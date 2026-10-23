-- =============================================================================
-- Brazilian E-Commerce: Comprehensive Data Quality & Integrity Suite
-- Environment: MySQL 8.0
-- Description: Rigorous post-import verification covering row counts, primary key
--              uniqueness, composite keys, mandatory nulls, referential integrity
--              (orphan records), numerical bounds, and temporal consistency.
-- =============================================================================

USE olist_ecommerce;

-- -----------------------------------------------------------------------------
-- CHECK 1: Table Row Counts & Cardinality Reference Comparison
-- Validates that every imported table has loaded data within expected ranges.
-- -----------------------------------------------------------------------------
SELECT 
    'customers' AS table_name,
    COUNT(*) AS actual_row_count,
    99441 AS expected_reference_count,
    CASE WHEN COUNT(*) = 99441 THEN 'MATCH' ELSE 'REVIEW' END AS count_status
FROM customers
UNION ALL
SELECT 'sellers', COUNT(*), 3095, CASE WHEN COUNT(*) = 3095 THEN 'MATCH' ELSE 'REVIEW' END FROM sellers
UNION ALL
SELECT 'geolocation', COUNT(*), 1000163, CASE WHEN COUNT(*) = 1000163 THEN 'MATCH' ELSE 'REVIEW' END FROM geolocation
UNION ALL
SELECT 'products', COUNT(*), 32951, CASE WHEN COUNT(*) = 32951 THEN 'MATCH' ELSE 'REVIEW' END FROM products
UNION ALL
SELECT 'product_category_name_translation', COUNT(*), 73, CASE WHEN COUNT(*) >= 71 THEN 'MATCH' ELSE 'REVIEW' END FROM product_category_name_translation
UNION ALL
SELECT 'orders', COUNT(*), 99441, CASE WHEN COUNT(*) = 99441 THEN 'MATCH' ELSE 'REVIEW' END FROM orders
UNION ALL
SELECT 'order_items', COUNT(*), 112650, CASE WHEN COUNT(*) = 112650 THEN 'MATCH' ELSE 'REVIEW' END FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*), 103886, CASE WHEN COUNT(*) = 103886 THEN 'MATCH' ELSE 'REVIEW' END FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*), 99224, CASE WHEN COUNT(*) = 99224 THEN 'MATCH' ELSE 'REVIEW' END FROM order_reviews;


-- -----------------------------------------------------------------------------
-- CHECK 2: Primary Key Integrity & Duplicate PK Verification
-- Audits both single-column and composite primary keys across all tables.
-- Expected duplicates across all tables: exactly 0.
-- -----------------------------------------------------------------------------
SELECT 
    'customers' AS table_name,
    'customer_id' AS pk_definition,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_keys,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_pks
FROM customers
UNION ALL
SELECT 'sellers', 'seller_id', COUNT(*), COUNT(DISTINCT seller_id), COUNT(*) - COUNT(DISTINCT seller_id) FROM sellers
UNION ALL
SELECT 'product_category_name_translation', 'product_category_name', COUNT(*), COUNT(DISTINCT product_category_name), COUNT(*) - COUNT(DISTINCT product_category_name) FROM product_category_name_translation
UNION ALL
SELECT 'products', 'product_id', COUNT(*), COUNT(DISTINCT product_id), COUNT(*) - COUNT(DISTINCT product_id) FROM products
UNION ALL
SELECT 'orders', 'order_id', COUNT(*), COUNT(DISTINCT order_id), COUNT(*) - COUNT(DISTINCT order_id) FROM orders
UNION ALL
SELECT 
    'order_items', 
    '(order_id, order_item_id)', 
    COUNT(*), 
    COUNT(DISTINCT CONCAT(order_id, '-', order_item_id)), 
    COUNT(*) - COUNT(DISTINCT CONCAT(order_id, '-', order_item_id)) 
FROM order_items
UNION ALL
SELECT 
    'order_payments', 
    '(order_id, payment_sequential)', 
    COUNT(*), 
    COUNT(DISTINCT CONCAT(order_id, '-', payment_sequential)), 
    COUNT(*) - COUNT(DISTINCT CONCAT(order_id, '-', payment_sequential)) 
FROM order_payments
UNION ALL
SELECT 
    'order_reviews', 
    '(review_id, order_id)', 
    COUNT(*), 
    COUNT(DISTINCT CONCAT(review_id, '-', order_id)), 
    COUNT(*) - COUNT(DISTINCT CONCAT(review_id, '-', order_id)) 
FROM order_reviews;


-- -----------------------------------------------------------------------------
-- CHECK 3: Unexpected NULL Values on Mandatory Business Fields
-- Verifies that critical transactional and dimensional attributes are populated.
-- Expected invalid rows: exactly 0.
-- -----------------------------------------------------------------------------
SELECT 
    SUM(CASE WHEN customer_id IS NULL OR customer_id = '' THEN 1 ELSE 0 END) AS null_customer_pks,
    SUM(CASE WHEN customer_unique_id IS NULL OR customer_unique_id = '' THEN 1 ELSE 0 END) AS null_customer_uniques,
    SUM(CASE WHEN customer_state IS NULL OR LENGTH(customer_state) != 2 THEN 1 ELSE 0 END) AS invalid_customer_states
FROM customers;

SELECT 
    SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END) AS null_order_pks,
    SUM(CASE WHEN customer_id IS NULL OR customer_id = '' THEN 1 ELSE 0 END) AS null_order_customers,
    SUM(CASE WHEN order_status IS NULL OR order_status = '' THEN 1 ELSE 0 END) AS null_order_statuses,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS null_order_purchases
FROM orders;

SELECT 
    SUM(CASE WHEN price IS NULL OR price <= 0 THEN 1 ELSE 0 END) AS invalid_item_prices,
    SUM(CASE WHEN freight_value IS NULL OR freight_value < 0 THEN 1 ELSE 0 END) AS invalid_item_freights,
    SUM(CASE WHEN shipping_limit_date IS NULL THEN 1 ELSE 0 END) AS null_item_shipping_dates
FROM order_items;

SELECT 
    SUM(CASE WHEN payment_type IS NULL OR payment_type = '' THEN 1 ELSE 0 END) AS null_payment_types,
    SUM(CASE WHEN payment_installments IS NULL OR payment_installments < 1 THEN 1 ELSE 0 END) AS invalid_installments,
    SUM(CASE WHEN payment_value IS NULL OR payment_value < 0 THEN 1 ELSE 0 END) AS invalid_payment_values
FROM order_payments;

SELECT 
    SUM(CASE WHEN review_score NOT BETWEEN 1 AND 5 THEN 1 ELSE 0 END) AS out_of_bound_review_scores,
    SUM(CASE WHEN review_creation_date IS NULL THEN 1 ELSE 0 END) AS null_review_creation_dates,
    SUM(CASE WHEN review_answer_timestamp IS NULL THEN 1 ELSE 0 END) AS null_review_answer_dates
FROM order_reviews;


-- -----------------------------------------------------------------------------
-- CHECK 4: Referential Integrity & Orphan Records Across All Relationships
-- Validates foreign-key alignment between child tables and parent dimensions.
-- Expected orphan records: exactly 0.
-- -----------------------------------------------------------------------------
SELECT 
    'orders -> customers' AS relationship,
    COUNT(*) AS orphan_count
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'order_items -> orders', COUNT(*)
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'order_items -> products', COUNT(*)
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL
UNION ALL
SELECT 'order_items -> sellers', COUNT(*)
FROM order_items oi
LEFT JOIN sellers s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL
UNION ALL
SELECT 'order_payments -> orders', COUNT(*)
FROM order_payments op
LEFT JOIN orders o ON op.order_id = o.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'order_reviews -> orders', COUNT(*)
FROM order_reviews r
LEFT JOIN orders o ON r.order_id = o.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'products -> translation (missing translations)', COUNT(*)
FROM products p
LEFT JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL AND t.product_category_name IS NULL;


-- -----------------------------------------------------------------------------
-- CHECK 5: Temporal Consistency & Logical Date Chronology
-- Flags records where timestamps follow an impossible temporal sequence.
-- -----------------------------------------------------------------------------
SELECT 
    -- Delivery to customer before order was ever placed
    SUM(CASE WHEN order_delivered_customer_date < order_purchase_timestamp THEN 1 ELSE 0 END) AS delivered_before_purchase,
    -- Carrier dispatch before order was ever placed
    SUM(CASE WHEN order_delivered_carrier_date < order_purchase_timestamp THEN 1 ELSE 0 END) AS carrier_before_purchase,
    -- Customer delivery before carrier received the package
    SUM(CASE WHEN order_delivered_customer_date < order_delivered_carrier_date THEN 1 ELSE 0 END) AS delivered_before_carrier,
    -- Order approved before order placed (accounting for potential clock skew)
    SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, order_purchase_timestamp, order_approved_at) < -5 THEN 1 ELSE 0 END) AS approved_substantially_before_purchase
FROM orders;
