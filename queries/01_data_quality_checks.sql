-- =============================================================================
-- Brazilian E-Commerce: Data Quality & Referential Integrity Validation
-- Environment: MySQL 8.0
-- =============================================================================

USE olist_ecommerce;

-- -----------------------------------------------------------------------------
-- CHECK 1: Primary Key Uniqueness & Row Counts
-- -----------------------------------------------------------------------------
SELECT 'customers' AS table_name, COUNT(*) AS total_rows, COUNT(DISTINCT customer_id) AS unique_pks FROM customers
UNION ALL
SELECT 'orders', COUNT(*), COUNT(DISTINCT order_id) FROM orders
UNION ALL
SELECT 'products', COUNT(*), COUNT(DISTINCT product_id) FROM products
UNION ALL
SELECT 'sellers', COUNT(*), COUNT(DISTINCT seller_id) FROM sellers;

-- -----------------------------------------------------------------------------
-- CHECK 2: Referential Integrity & Orphan Records Check
-- Ensure all foreign keys point to valid parent entities.
-- -----------------------------------------------------------------------------
-- Orphan Orders (Orders missing a Customer)
SELECT COUNT(*) AS orphan_orders
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Orphan Order Items (Items missing an Order)
SELECT COUNT(*) AS orphan_order_items
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Orphan Products in Order Items
SELECT COUNT(*) AS orphan_product_items
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- -----------------------------------------------------------------------------
-- CHECK 3: Numerical Bounds & Logical Consistency Checks
-- -----------------------------------------------------------------------------
-- Non-positive item prices or freight values
SELECT COUNT(*) AS invalid_price_count
FROM order_items
WHERE price <= 0 OR freight_value < 0;

-- Review scores out of bounds [1, 5]
SELECT COUNT(*) AS invalid_review_scores
FROM order_reviews
WHERE review_score < 1 OR review_score > 5;

-- Delivery dates preceding purchase timestamp (Logical impossibility)
SELECT COUNT(*) AS illogical_delivery_dates
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;
