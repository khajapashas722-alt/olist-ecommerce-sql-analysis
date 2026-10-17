-- =============================================================================
-- MySQL 8.0 Data Ingestion Guide & Infile Script
-- Dataset: Olist Brazilian E-Commerce
-- =============================================================================

/*
HOW TO IMPORT CSV DATA INTO MYSQL 8.0:

METHOD 1: Using MySQL Workbench Table Data Import Wizard (Recommended for Beginners)
1. Open MySQL Workbench and connect to your local MySQL 8.0 instance.
2. In the Schemas tab on the left, right-click on table (e.g., 'customers') -> 'Table Data Import Wizard'.
3. Browse and select the corresponding CSV file.
4. Verify column mappings and click 'Next' to execute.

METHOD 2: High-Performance Ingestion using LOAD DATA LOCAL INFILE
Prerequisites in MySQL 8:
- Enable local infile on server: SET GLOBAL local_infile = 1;
- Connect client with flag: mysql --local-infile=1 -u root -p
*/

SET GLOBAL local_infile = 1;
USE olist_ecommerce;

-- 1. Ingest Translations
LOAD DATA LOCAL INFILE 'product_category_name_translation.csv'
INTO TABLE product_category_name_translation
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_category_name, product_category_name_english);

-- 2. Ingest Customers
LOAD DATA LOCAL INFILE 'olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state);

-- 3. Ingest Sellers
LOAD DATA LOCAL INFILE 'olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(seller_id, seller_zip_code_prefix, seller_city, seller_state);

-- 4. Ingest Products
LOAD DATA LOCAL INFILE 'olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
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
    product_width_cm = NULLIF(@width, '');

-- 5. Ingest Orders
LOAD DATA LOCAL INFILE 'olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status, order_purchase_timestamp, @approved, @carrier, @delivered, order_estimated_delivery_date)
SET
    order_approved_at = NULLIF(@approved, ''),
    order_delivered_carrier_date = NULLIF(@carrier, ''),
    order_delivered_customer_date = NULLIF(@delivered, '');

-- 6. Ingest Order Items
LOAD DATA LOCAL INFILE 'olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value);

-- 7. Ingest Order Payments
LOAD DATA LOCAL INFILE 'olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, payment_sequential, payment_type, payment_installments, payment_value);

-- 8. Ingest Order Reviews
LOAD DATA LOCAL INFILE 'olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(review_id, order_id, review_score, @title, @message, review_creation_date, review_answer_timestamp)
SET
    review_comment_title = NULLIF(@title, ''),
    review_comment_message = NULLIF(@message, '');
