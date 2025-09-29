-- Sample indexes for optimizing queries against the DVDRental dataset.
--
-- On the sample database used in this repository the tables are small
-- enough that sequential scans perform well and additional indexes are
-- unnecessary.  If you work with a larger dataset or experience
-- performance issues, you can apply these definitions to help the
-- database planner locate rows more efficiently.

-- Accelerate rolling 90‑90-day spend calculations by indexing customer and payment_date
CREATE INDEX CONCURRENTLY IF NOT EXISTS payment_customer_date_idx
    ON payment (customer_id, payment_date);

-- Speed up joins between film_category and category/inventory by indexing film_id and category_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS film_category_film_idx
    ON film_category (film_id, category_id);
