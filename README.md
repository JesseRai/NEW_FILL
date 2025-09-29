# Rental Revenue Analysis (DVDRental)

This repository contains a set of SQL queries, scripts, and supporting assets to analyse revenue in the classic [DVD Rental](https://www.postgresqltutorial.com/postgresql-sample-database/) database.  The project demonstrates how to build a layered SQL query using common table expressions (CTEs), window functions and multi‑table joins to answer business questions such as:

* How much revenue does each film category generate each month?
* What share of total monthly revenue does each category represent?
* How does category revenue change month over month (MoM)?
* Who are the top‑spending customers in each category and month?
* How much did those customers spend in the 90 days prior to the reporting month?

Although the analysis is built against PostgreSQL, an equivalent version of the query is provided for BigQuery.  A small Python script is also included for exporting database tables to CSV if you need to inspect the underlying data.

## Repository structure

```
.
├── README.md                       – project overview and usage instructions
├── sql
│   ├── postgres_rental_analysis.sql – main analysis query for PostgreSQL
│   ├── bigquery_rental_analysis.sql – equivalent analysis query for BigQuery
│   └— indexes.sql                 – optional sample index definitions for scaling
├── scripts
│   └— export_tables_to_csv.py     – helper script to export tables to CSV
├── images/                         – execution plan screenshots (explain_analysis_part*.png)
└— (old files moved into the above directories)
```

## Dataset

The analysis uses the following tables from the DVD Rental database:

* `payment` – records of customer payments
* `rental` – details of each rental transaction
* `inventory` – catalogue of DVD copies
* `film_category` – mapping between films and their categories
* `category` – list of film categories

Each payment is linked to a rental, which in turn links to a specific DVD copy (`inventory`).  That copy belongs to a film and, through `film_category`, is associated with a single `category`.

## Analysis query

The primary analysis query is implemented in [`sql/postgres_rental_analysis.sql`](sql/postgres_rental_analysis.sql).  It builds a series of CTEs to break the problem into manageable steps:

1. **`cte_base`** – joins the payment, rental and category tables and derives useful fields such as `paid_month`.
2. **`cte_month_cat`** – aggregates revenue by month and category.
3. **`cte_month_total`** – aggregates total revenue across all categories per month.
4. **`cte_month_cat_share`** – computes each category’s share of the month’s total.
5. **`cte_mom`** – calculates month‑over‑month growth for each category.
6. **`cte_customer_rev`** – aggregates revenue per customer for each month and category.
7. **`cte_customer_rank`** – ranks customers within each month–category combination.
8. **`cte_prev90`** – calculates each customer’s spend in the 90 days prior to the current month.
9. **`cte_top3_with_share`** – selects the top 3 customers per month & category and derives each top customer’s share of category revenue.

The final `SELECT` lists each month–category combination with its top customers, their revenue, rank, share of category revenue and 90‑day prior spend.

The equivalent BigQuery version is available in [`sql/bigquery_rental_analysis.sql`](sql/bigquery_rental_analysis.sql).

## Results and performance

On the sample dataset, the query completes in under a second.  PostgreSQL’s default execution plan (primarily sequential scans and hash joins) is sufficient for this workload.  Additional indexes were evaluated but did not provide significant benefit at this scale, so none were added by default.  Should the dataset grow or performance become an issue, you can apply the sample index definitions in [`sql/indexes.sql`](sql/indexes.sql).  Execution plan screenshots (`images/explain_analysis_part*.png`) are included for reference.

## Usage

1. Load the DVD Rental database into PostgreSQL (see the [PostgreSQL tutorial](https://www.postgresqltutorial.com/postgresql-sample-database/) for instructions).
2. Run the query in [`sql/postgres_rental_analysis.sql`](sql/postgres_rental_analysis.sql) using `psql`, pgAdmin or your preferred SQL client.
3. Review the output and execution plan to interpret the results.
4. If you are working with BigQuery instead of PostgreSQL, use [`sql/bigquery_rental_analysis.sql`](sql/bigquery_rental_analysis.sql).

To export tables to CSV for additional analysis, run the helper script:

```bash
python scripts/export_tables_to_csv.py
```

Make sure to adjust the `conn_params` dictionary and `output_dir` path inside the script to match your environment.

---

Feel free to open issues or submit pull requests if you have suggestions for improving the analysis or the repository structure.
