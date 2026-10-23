-- =============================================================================
-- Brazilian E-Commerce Database (Olist) - Surgical Database Repair Script
-- Description: Safely repairs a database where geolocation was duplicated to 2,000,326
--              rows by repeated execution, WITHOUT touching or reimporting the
--              other 8 already-verified tables.
-- =============================================================================

USE olist_ecommerce;

-- -----------------------------------------------------------------------------
-- STEP 1: Pre-Repair Dependency & Impact Check
-- Verifies that NO foreign keys in the entire schema reference 'geolocation'.
-- Result should be EMPTY (0 rows), confirming zero risk to other tables.
-- -----------------------------------------------------------------------------
SELECT 
    TABLE_NAME AS referencing_table,
    COLUMN_NAME AS referencing_column,
    CONSTRAINT_NAME AS foreign_key_name,
    REFERENCED_TABLE_NAME AS parent_table
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
WHERE REFERENCED_TABLE_SCHEMA = 'olist_ecommerce' 
  AND REFERENCED_TABLE_NAME = 'geolocation';

-- -----------------------------------------------------------------------------
-- STEP 2: Inspect Current Duplication State
-- If geolocation was run twice, row count is 2,000,326.
-- Expected benchmark count is 1,000,163.
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS current_geolocation_rows,
    1000163 AS expected_benchmark_rows,
    COUNT(*) - 1000163 AS excess_duplicated_rows
FROM geolocation;

-- -----------------------------------------------------------------------------
-- STEP 3: Safe Removal of Duplicated Geolocation Records
-- Because geolocation uses an AUTO_INCREMENT primary key (geolocation_id):
--   - Batch 1 (original CSV import) occupies IDs 1 through 1,000,163.
--   - Batch 2 (accidental re-import) occupies IDs 1,000,164 through 2,000,326.
-- Deleting IDs > 1,000,163 cleanly removes only the duplicate second batch
-- while preserving all 1,000,163 original records (including valid duplicate pings).
--
-- NOTE: If Safe Update mode is enabled in MySQL Workbench, temporarily disable it:
-- -----------------------------------------------------------------------------
SET SQL_SAFE_UPDATES = 0;

DELETE FROM geolocation 
WHERE geolocation_id > 1000163;

SET SQL_SAFE_UPDATES = 1;

-- -----------------------------------------------------------------------------
-- STEP 4: Post-Repair Verification
-- Verifies that geolocation now has exactly 1,000,163 rows and all 8 other tables
-- remain completely intact and untouched.
-- -----------------------------------------------------------------------------
SELECT 'customers' AS table_name, COUNT(*) AS row_count, 99441 AS expected FROM customers
UNION ALL SELECT 'sellers', COUNT(*), 3095 FROM sellers
UNION ALL SELECT 'geolocation', COUNT(*), 1000163 FROM geolocation
UNION ALL SELECT 'products', COUNT(*), 32951 FROM products
UNION ALL SELECT 'product_category_name_translation', COUNT(*), 73 FROM product_category_name_translation
UNION ALL SELECT 'orders', COUNT(*), 99441 FROM orders
UNION ALL SELECT 'order_items', COUNT(*), 112650 FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*), 103886 FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*), 99224 FROM order_reviews;
