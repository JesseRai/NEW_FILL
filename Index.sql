-- 1. Speed up joins between payment, rental, and customer look‑ups by indexing customer_id and payment_date
CREATE INDEX idx_payment_customer_date
    ON payment (customer_id, payment_date);

-- 2. Boost performance of the join between rental and inventory by indexing inventory_id
CREATE INDEX idx_rental_inventory_id
    ON rental (inventory_id);

-- 3. Help the rental→inventory→film→category chain by indexing the film_id on inventory
CREATE INDEX idx_inventory_film_id
    ON inventory (film_id);

-- 4. Improve look‑ups from film to category via film_category
CREATE INDEX idx_film_category_film_id_category_id
    ON film_category (film_id, category_id);

-- 5. Optional: index the category name if you frequently filter or group by it
CREATE INDEX idx_category_name
    ON category (name);

-- 6. Optional: index the expression used to group payments by month; this helps if you do a lot of month‑level aggregations
CREATE INDEX idx_payment_month
    ON payment (DATE_TRUNC('month', payment_date));
