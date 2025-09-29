-- Project: ornate-fragment-473519-c2
-- Dataset: dvd_rental

WITH CTE_BASE AS (
  SELECT
    p.customer_id,
    p.amount,
    TIMESTAMP(p.payment_date) AS paid_ts,
    DATE_TRUNC(DATE(p.payment_date), MONTH) AS paid_month,
    c.name AS category
  FROM `ornate-fragment-473519-c2.dvd_rental.payment`        p
  JOIN `ornate-fragment-473519-c2.dvd_rental.rental`         r  ON r.rental_id    = p.rental_id
  JOIN `ornate-fragment-473519-c2.dvd_rental.inventory`      i  ON i.inventory_id = r.inventory_id
  JOIN `ornate-fragment-473519-c2.dvd_rental.film_category`  fc ON fc.film_id     = i.film_id
  JOIN `ornate-fragment-473519-c2.dvd_rental.category`       c  ON c.category_id  = fc.category_id
),
CTE_MONTH_CAT AS (
  SELECT paid_month, category, SUM(amount) AS rev
  FROM CTE_BASE
  GROUP BY paid_month, category
),
CTE_MONTH_TOTAL AS (
  SELECT paid_month, SUM(rev) AS rev_total
  FROM CTE_MONTH_CAT
  GROUP BY paid_month
),
CTE_MONTH_CAT_SHARE AS (
  SELECT
    mc.paid_month,
    mc.category,
    mc.rev,
    SAFE_DIVIDE(mc.rev, mt.rev_total) AS rev_share
  FROM CTE_MONTH_CAT mc
  JOIN CTE_MONTH_TOTAL mt USING (paid_month)
),
CTE_CUSTOMER_REV AS (
  SELECT paid_month, category, customer_id, SUM(amount) AS cust_rev
  FROM CTE_BASE
  GROUP BY paid_month, category, customer_id
),
-- do the ranking AND filter here with QUALIFY
CTE_TOP3 AS (
  SELECT
    paid_month,
    category,
    customer_id,
    cust_rev,
    RANK() OVER (PARTITION BY paid_month, category ORDER BY cust_rev DESC) AS rnk
  FROM CTE_CUSTOMER_REV
  QUALIFY rnk <= 3
),
CTE_PREV90 AS (
  SELECT
    b.customer_id,
    b.category,
    b.paid_month,
    SUM(b2.amount) AS spend_prev_90d
  FROM CTE_BASE b
  JOIN CTE_BASE b2
    ON b2.customer_id = b.customer_id
   AND b2.category    = b.category
   AND b2.paid_ts <= TIMESTAMP(DATE_ADD(b.paid_month, INTERVAL 1 MONTH))
   AND b2.paid_ts >  TIMESTAMP(DATE_ADD(b.paid_month, INTERVAL -2 MONTH))
  GROUP BY 1,2,3
)
SELECT
  t.paid_month,
  t.category,
  t.customer_id,
  t.cust_rev,
  p90.spend_prev_90d,
  m.rev,
  m.rev_share,
  t.rnk
FROM CTE_TOP3 t
JOIN CTE_MONTH_CAT_SHARE m USING (paid_month, category)
LEFT JOIN CTE_PREV90 p90
  ON p90.customer_id = t.customer_id
 AND p90.category    = t.category
 AND p90.paid_month  = t.paid_month
ORDER BY paid_month, category, rnk;
