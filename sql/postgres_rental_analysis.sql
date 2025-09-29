-- Analysis query for DVDRental dataset
WITH CTE_BASE AS (
    SELECT 
        p.customer_id,
        p.rental_id,
        p.amount AS paid_amount,
        p.payment_date::DATE,
        DATE_TRUNC('month', p.payment_date)::DATE AS paid_month,
        r.rental_date::DATE AS rental_date,
        i.film_id,
        c.category_id,
        c.name AS category_name
    FROM payment p 
    JOIN rental r ON p.rental_id = r.rental_id
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film_category fc ON i.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
),

CTE_MONTH_CAT AS (
    SELECT    
        paid_month,
        category_name,
        SUM(paid_amount) AS category_month_revenue
    FROM CTE_BASE
    GROUP BY 1, 2
),

CTE_MONTH_TOTAL AS (
    SELECT 
        paid_month,
        SUM(category_month_revenue) AS month_total_revenue
    FROM CTE_MONTH_CAT
    GROUP BY 1
),

CTE_MONTH_CAT_SHARE AS (
    SELECT
        mc.paid_month,
        mc.category_name,
        mc.category_month_revenue,
        (mc.category_month_revenue::NUMERIC / NULLIF(mt.month_total_revenue,0))::NUMERIC(12,4) AS 
            category_share_of_month
    FROM CTE_MONTH_CAT mc
    JOIN CTE_MONTH_TOTAL mt USING(paid_month)
),

CTE_MOM AS (
    SELECT 
        paid_month,
        category_name,
        category_month_revenue,
        category_share_of_month,
        CASE
            WHEN LAG(category_month_revenue)
                 OVER (PARTITION BY category_name ORDER BY paid_month) IS NULL THEN NULL
            ELSE (category_month_revenue - LAG(category_month_revenue) 
                 OVER (PARTITION BY category_name ORDER BY paid_month))
                 / NULLIF(LAG(category_month_revenue) OVER (PARTITION BY category_name ORDER BY paid_month), 0.0)
        END::NUMERIC(12,4) as mom_growth_pct
    FROM cte_month_cat_share
),

CTE_CUSTOMER_REV AS (
    SELECT
        paid_month,
        category_name,
        customer_id,
        SUM(paid_amount) AS customer_month_revenue
    FROM CTE_BASE
    GROUP BY 1,2,3
),

CTE_CUSTOMER_RANK AS (
    SELECT 
        cr.*, 
        RANK() OVER (PARTITION BY paid_month, category_name ORDER BY customer_month_revenue DESC, customer_id) AS 
            customer_rank_in_category_month
    FROM cte_customer_rev cr
),

CTE_PREV90 AS (
  SELECT d.paid_month, d.customer_id,
         COALESCE((
           SELECT SUM(p2.amount)
           FROM payment p2
           WHERE p2.customer_id = d.customer_id
             AND p2.payment_date >= d.paid_month - INTERVAL '90 days'
             AND p2.payment_date <  d.paid_month
         ),0) AS prev90_spend
  FROM (SELECT DISTINCT paid_month, customer_id FROM CTE_CUSTOMER_REV) d
),

CTE_TOP3 AS (
    SELECT
        m.paid_month,
        m.category_name,
        m.category_month_revenue,
        m.category_share_of_month,
        m.mom_growth_pct,
        r.customer_id,
        r.customer_month_revenue,
        r.customer_rank_in_category_month
    FROM CTE_MOM m
    JOIN CTE_CUSTOMER_RANK r
      ON r.paid_month = m.paid_month
     AND r.category_name = m.category_name
    WHERE r.customer_rank_in_category_month <= 3
),

CTE_TOP3_WITH_SHARE AS (
    SELECT
        t.*,
        (t.customer_month_revenue::numeric / NULLIF(t.category_month_revenue,0))::numeric(12,4)
            AS customer_share_of_category_month
    FROM CTE_TOP3 t
)

SELECT
    t.paid_month,
    t.category_name,
    t.category_month_revenue,
    t.category_share_of_month,
    t.mom_growth_pct,
    t.customer_id,
    t.customer_month_revenue,
    t.customer_rank_in_category_month,
    t.customer_share_of_category_month,
    pv.prev90_spend
FROM cte_top3_with_share t
LEFT JOIN CTE_PREV90 pv ON pv.paid_month = t.paid_month AND pv.customer_id = t.customer_id
ORDER BY t.paid_month, t.category_name, t.customer_rank_in_category_month;
