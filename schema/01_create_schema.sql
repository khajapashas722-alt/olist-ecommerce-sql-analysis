-- =============================================================================
-- Brazilian E-Commerce Database Schema (MySQL 8.0)
-- Dataset: Olist Public E-Commerce Dataset
-- Description: DDL script creating all core relational tables, primary keys,
--              foreign keys, and indexes for analytical workload optimization.
-- =============================================================================

CREATE DATABASE IF NOT EXISTS olist_ecommerce
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE olist_ecommerce;

-- -----------------------------------------------------------------------------
-- Table 1: customers
-- Description: Stores customer accounts and geographic locations.
-- Note: customer_id is order-specific; customer_unique_id identifies individuals.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS order_reviews;
DROP TABLE IF EXISTS order_payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS product_category_name_translation;
DROP TABLE IF EXISTS sellers;

CREATE TABLE customers (
    customer_id VARCHAR(32) NOT NULL,
    customer_unique_id VARCHAR(32) NOT NULL,
    customer_zip_code_prefix VARCHAR(10) NOT NULL,
    customer_city VARCHAR(100) NOT NULL,
    customer_state CHAR(2) NOT NULL,
    PRIMARY KEY (customer_id),
    INDEX idx_customer_unique (customer_unique_id),
    INDEX idx_customer_state (customer_state)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table 2: sellers
-- Description: Independent merchants fulfilling marketplace orders.
-- -----------------------------------------------------------------------------
CREATE TABLE sellers (
    seller_id VARCHAR(32) NOT NULL,
    seller_zip_code_prefix VARCHAR(10) NOT NULL,
    seller_city VARCHAR(100) NOT NULL,
    seller_state CHAR(2) NOT NULL,
    PRIMARY KEY (seller_id),
    INDEX idx_seller_state (seller_state)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table 3: product_category_name_translation
-- Description: Portuguese to English translation map for product categories.
-- -----------------------------------------------------------------------------
CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(100) NOT NULL,
    product_category_name_english VARCHAR(100) NOT NULL,
    PRIMARY KEY (product_category_name)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table 4: products
-- Description: Product catalog attributes, physical dimensions, and category.
-- -----------------------------------------------------------------------------
CREATE TABLE products (
    product_id VARCHAR(32) NOT NULL,
    product_category_name VARCHAR(100) NULL,
    product_name_length INT NULL,
    product_description_length INT NULL,
    product_photos_qty INT NULL,
    product_weight_g INT NULL,
    product_length_cm INT NULL,
    product_height_cm INT NULL,
    product_width_cm INT NULL,
    PRIMARY KEY (product_id),
    INDEX idx_product_category (product_category_name),
    CONSTRAINT fk_products_category
        FOREIGN KEY (product_category_name) 
        REFERENCES product_category_name_translation (product_category_name)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table 5: orders
-- Description: Master order table recording purchase and delivery lifecycle timestamps.
-- -----------------------------------------------------------------------------
CREATE TABLE orders (
    order_id VARCHAR(32) NOT NULL,
    customer_id VARCHAR(32) NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    order_purchase_timestamp DATETIME NOT NULL,
    order_approved_at DATETIME NULL,
    order_delivered_carrier_date DATETIME NULL,
    order_delivered_customer_date DATETIME NULL,
    order_estimated_delivery_date DATETIME NOT NULL,
    PRIMARY KEY (order_id),
    INDEX idx_orders_customer (customer_id),
    INDEX idx_order_purchase (order_purchase_timestamp),
    INDEX idx_order_status (order_status),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) 
        REFERENCES customers (customer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table 6: order_items
-- Description: Line-item level details linking orders, products, and sellers.
-- -----------------------------------------------------------------------------
CREATE TABLE order_items (
    order_id VARCHAR(32) NOT NULL,
    order_item_id INT NOT NULL,
    product_id VARCHAR(32) NOT NULL,
    seller_id VARCHAR(32) NOT NULL,
    shipping_limit_date DATETIME NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    freight_value DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id),
    INDEX idx_items_product (product_id),
    INDEX idx_items_seller (seller_id),
    CONSTRAINT fk_items_order
        FOREIGN KEY (order_id) 
        REFERENCES orders (order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_items_product
        FOREIGN KEY (product_id) 
        REFERENCES products (product_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_items_seller
        FOREIGN KEY (seller_id) 
        REFERENCES sellers (seller_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table 7: order_payments
-- Description: Financial settlement records per order (installments, tenders).
-- -----------------------------------------------------------------------------
CREATE TABLE order_payments (
    order_id VARCHAR(32) NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type VARCHAR(20) NOT NULL,
    payment_installments INT NOT NULL,
    payment_value DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential),
    INDEX idx_payments_type (payment_type),
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id) 
        REFERENCES orders (order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table 8: order_reviews
-- Description: Customer satisfaction scores (1-5) and survey feedback comments.
-- -----------------------------------------------------------------------------
CREATE TABLE order_reviews (
    review_id VARCHAR(32) NOT NULL,
    order_id VARCHAR(32) NOT NULL,
    review_score INT NOT NULL,
    review_comment_title TEXT NULL,
    review_comment_message TEXT NULL,
    review_creation_date DATETIME NOT NULL,
    review_answer_timestamp DATETIME NOT NULL,
    PRIMARY KEY (review_id, order_id),
    INDEX idx_reviews_score (review_score),
    CONSTRAINT fk_reviews_order
        FOREIGN KEY (order_id) 
        REFERENCES orders (order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;
