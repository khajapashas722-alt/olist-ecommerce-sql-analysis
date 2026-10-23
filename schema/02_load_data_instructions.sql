-- =============================================================================
-- Brazilian E-Commerce Database (Olist) - Data Ingestion Script (MySQL 8.0)
-- Description: High-performance LOAD DATA LOCAL INFILE script for all 9 Olist CSVs.
-- Handled Quirks:
--   - Foreign key dependency order (Translations -> Customers/Sellers/Geo -> Products -> Orders -> Items/Payments/Reviews)
--   - Seeding of 2 missing category translations ('pc_gamer' & 'portateis_cozinha_e_preparadores_de_alimentos')
--   - Multi-line review messages & trailing backslashes (FIELDS ESCAPED BY '')
--   - Windows CRLF vs Unix LF carriage return stripping (TRIM(TRAILING '\r' FROM ...))
--   - Empty strings to NULL conversions (NULLIF(@col, ''))
-- =============================================================================

/*
--------------------------------------------------------------------------------
PREREQUISITES & CLIENT CONFIGURATION (CRUCIAL):
--------------------------------------------------------------------------------

1. MYSQL SERVER:
   Local infile must be enabled on the server:
   SET GLOBAL local_infile = 1;

2. MYSQL CLIENT (Command Line):
   Connect using the --local-infile=1 flag:
   mysql --local-infile=1 -u root -p olist_ecommerce

3. MYSQL WORKBENCH:
   By default, MySQL Workbench disables OPT_LOCAL_INFILE on connections.
   To enable:
     a. On the Workbench home screen, right-click your connection -> 'Edit Connection...'
     b. Click the 'Advanced' tab.
     c. In the 'Others:' box at the bottom, paste:
        OPT_LOCAL_INFILE=1
     d. Click 'Test Connection', then 'Close'. Reconnect to your database.
   If safe update errors occur (Error 1175), run:
     SET SQL_SAFE_UPDATES = 0;

4. PATH CONFIGURATION:
   The statements below use the default local path:
     'C:/Users/shakj/Downloads/archive (3)/'
   NOTE: In MySQL file paths, always use FORWARD SLASHES (/) even on Windows.
   If your CSV files reside in another folder, find and replace this base path.

5. IDEMPOTENT & SAFE RE-EXECUTION:
   - To perform a fresh reload without duplicate key errors, TRUNCATE tables first
     in reverse foreign-key order (see the TRUNCATE section below).
   - Alternatively, 'IGNORE INTO TABLE' skips records with duplicate primary keys.
--------------------------------------------------------------------------------
*/

USE olist_ecommerce;
SET GLOBAL local_infile = 1;

-- OPTIONAL: Clean reload (uncomment if re-running on an existing populated database)
/*
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE order_reviews;
TRUNCATE TABLE order_payments;
TRUNCATE TABLE order_items;
TRUNCATE TABLE orders;
TRUNCATE TABLE products;
TRUNCATE TABLE geolocation;
TRUNCATE TABLE sellers;
TRUNCATE TABLE customers;
TRUNCATE TABLE product_category_name_translation;
SET FOREIGN_KEY_CHECKS = 1;
*/

-- =============================================================================
-- STEP 1: Ingest Category Translations (Reference Lookup)
-- Expected Count: 71 rows in CSV + 2 pre-seeded = 73 total rows
-- =============================================================================
LOAD DATA LOCAL INFILE 'C:/Users/shakj/Downloads/archive (3)/product_category_name_translation.csv'
IGNORE INTO TABLE product_category_name_translation
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_category_name, @english)
SET product_category_name_english = TRIM(TRAILING '\r' FROM @english);

-- Pre-seed the 2 product categories present in products dataset but missing from official translation CSV
-- to maintain 100% referential integrity with fk_products_category
INSERT IGNORE INTO product_category_name_translation (product_category_name, product_category_name_english)
VALUES 
    ('portateis_cozinha_e_preparadores_de_alimentos', 'small_appliances_kitchen_and_food_preparers'),
    ('pc_gamer', 'pc_gamer');


-- =============================================================================
-- STEP 2: Ingest Customers
-- Expected Count: ~99,441 rows
-- =============================================================================
LOAD DATA LOCAL INFILE 'C:/Users/shakj/Downloads/archive (3)/olist_customers_dataset.csv'
IGNORE INTO TABLE customers
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, @state)
SET customer_state = TRIM(TRAILING '\r' FROM @state);


-- =============================================================================
-- STEP 3: Ingest Sellers
-- Expected Count: ~3,095 rows
-- =============================================================================
LOAD DATA LOCAL INFILE 'C:/Users/shakj/Downloads/archive (3)/olist_sellers_dataset.csv'
IGNORE INTO TABLE sellers
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(seller_id, seller_zip_code_prefix, seller_city, @state)
SET seller_state = TRIM(TRAILING '\r' FROM @state);


-- =============================================================================
-- STEP 4: Ingest Geolocation Coordinates
-- Expected Count: ~1,000,163 rows
-- Note: Contains multiple coordinate observations per zip prefix.
-- =============================================================================
LOAD DATA LOCAL INFILE 'C:/Users/shakj/Downloads/archive (3)/olist_geolocation_dataset.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, @state)
SET geolocation_state = TRIM(TRAILING '\r' FROM @state);


-- =============================================================================
-- STEP 5: Ingest Products Catalog
-- Expected Count: ~32,951 rows
-- =============================================================================
LOAD DATA LOCAL INFILE 'C:/Users/shakj/Downloads/archive (3)/olist_products_dataset.csv'
IGNORE INTO TABLE products
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, @category, @name_len, @desc_len, @photos, @weight, @len, @height, @width)
SET 
    product_category_name = NULLIF(@category, ''),
    product_name_length = NULLIF(@name_len, ''),
    product_description_length = NULLIF(@desc_len, ''),
    product_photos_qty = NULLIF(@photos, ''),
    product_weight_g = NULLIF(@weight, ''),
    product_length_cm = NULLIF(@len, ''),
    product_height_cm = NULLIF(@height, ''),
    product_width_cm = NULLIF(TRIM(TRAILING '\r' FROM @width), '');


-- =============================================================================
-- STEP 6: Ingest Orders Master Table
-- Expected Count: ~99,441 rows
-- =============================================================================
LOAD DATA LOCAL INFILE 'C:/Users/shakj/Downloads/archive (3)/olist_orders_dataset.csv'
IGNORE INTO TABLE orders
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status, order_purchase_timestamp, @approved, @carrier, @delivered, @est_delivery)
SET
    order_approved_at = NULLIF(@approved, ''),
    order_delivered_carrier_date = NULLIF(@carrier, ''),
    order_delivered_customer_date = NULLIF(@delivered, ''),
    order_estimated_delivery_date = TRIM(TRAILING '\r' FROM @est_delivery);


-- =============================================================================
-- STEP 7: Ingest Order Items (Line Items)
-- Expected Count: ~112,650 rows
-- =============================================================================
LOAD DATA LOCAL INFILE 'C:/Users/shakj/Downloads/archive (3)/olist_order_items_dataset.csv'
IGNORE INTO TABLE order_items
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, @freight)
SET freight_value = TRIM(TRAILING '\r' FROM @freight);


-- =============================================================================
-- STEP 8: Ingest Order Payments
-- Expected Count: ~103,886 rows
-- =============================================================================
LOAD DATA LOCAL INFILE 'C:/Users/shakj/Downloads/archive (3)/olist_order_payments_dataset.csv'
IGNORE INTO TABLE order_payments
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, payment_sequential, payment_type, payment_installments, @val)
SET payment_value = TRIM(TRAILING '\r' FROM @val);


-- =============================================================================
-- STEP 9: Ingest Order Customer Reviews
-- Expected Count: ~99,224 rows
-- Note: ESCAPED BY '' is essential because Portuguese review texts often end with
--       emoticons like ':\', where a trailing backslash would otherwise escape
--       the closing quotation mark and corrupt row parsing.
-- =============================================================================
LOAD DATA LOCAL INFILE 'C:/Users/shakj/Downloads/archive (3)/olist_order_reviews_dataset.csv'
IGNORE INTO TABLE order_reviews
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(review_id, order_id, review_score, @title, @message, review_creation_date, @answer)
SET
    review_comment_title = NULLIF(@title, ''),
    review_comment_message = NULLIF(@message, ''),
    review_answer_timestamp = TRIM(TRAILING '\r' FROM @answer);
