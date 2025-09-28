# Rental Revenue Analysis (DVDRental)

This project analyzes rental revenue from the DVD Rental dataset using PostgreSQL. The goal is to demonstrate the use of common table expressions (CTEs), window functions, multi-table joins, and to evaluate whether further optimization (such as adding indexes) is necessary.

## Dataset
The analysis uses the following tables from the DVD Rental database: `payment`, `rental`, `inventory`, `film_category`, and `category`. Each payment is linked to a rental, which in turn is linked to an inventory item (a specific DVD copy). That copy belongs to a film and, through a join on `film_category`, is associated with a single category.

## Analysis Query
The SQL query (see `SQL_CODE.sql`) performs several steps:

1. **CTE_BASE** joins the payment, rental, and category tables and derives additional fields such as `paid_month`.
2. **CTE_MONTH_CAT** aggregates revenue by month and category.
3. **CTE_MONTH_TOTAL** computes total monthly revenue across all categories.
4. **CTE_MONTH_CAT_SHARE** calculates each category’s share of total monthly revenue.
5. **CTE_MOM** computes month-over-month (MoM) growth for each category.
6. **CTE_CUSTOMER_REV** aggregates revenue per customer for each month and category.
7. **CTE_CUSTOMER_RANK** ranks customers by their spending within each month and category using a window function.
8. **CTE_PREV90** computes the total amount that a customer spent in the 90 days prior to the current month.
9. **CTE_TOP3** filters to the top three customers (per month & category), and **CTE_TOP3_WITH_SHARE** derives each top customer’s share of that category’s revenue.

The final select lists each month–category combination with its top customers, their revenue, rank, and 90‑day spend.

## Results
The analysis showed that the query runs in under a second on the provided dataset (see the `analysis` tab of the query plan). Because the dataset is relatively small, PostgreSQL’s default execution plan already performs well, and adding indexes yields negligible improvement. The attached execution plan screenshots (`explain_analysis_part1.png` to `explain_analysis_part4.png`) show that sequential scans and hash joins are sufficient for the workload.

A summary of the revenue by month and category is provided in `statistics_table.png` (first 15 rows shown). These results confirm that the query computes revenue and customer rankings correctly.

## Index Consideration
During development, various indexing strategies were evaluated. For example, an index on `(customer_id, payment_date)` in the `payment` table could accelerate rolling window calculations if the dataset grows significantly. However, given the current data volume and query complexity, additional indexes would add maintenance overhead without noticeable performance gains. Therefore, no new indexes were applied.

## Usage
To reproduce the analysis:

1. Ensure you have a PostgreSQL database with the DVD Rental dataset loaded.
2. Run the contents of `analysis.sql` in a SQL client (e.g. pgAdmin or psql).
3. Review the output and query plan to see the same results and performance.

The images in this repository (`statistics_table.png` and the `explain_analysis_part*.png` files) provide visual evidence of the query’s runtime characteristics.

---

For any future scaling or additional filters (e.g., frequent queries by customer or specific date ranges), consider adding targeted indexes and re‑examining the execution plan.
