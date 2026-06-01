-- ============================================================
-- Olist E-Commerce Database Setup
-- Run this script once to create the database and load all 9 tables.
--
-- BEFORE RUNNING:
--   1. Update the file paths in each LOAD DATA statement below
--      to match where your CSVs are saved on your computer.
--   2. Make sure local_infile is enabled in MySQL:
--        SET GLOBAL local_infile = 1;
--      Or add this to your MySQL connection in VS Code:
--        allowLocalInfile=true
-- ============================================================

CREATE DATABASE IF NOT EXISTS olist;
USE olist;

-- ============================================================
-- TABLE DEFINITIONS
-- ============================================================

DROP TABLE IF EXISTS order_reviews;
DROP TABLE IF EXISTS order_payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS product_category_translation;
DROP TABLE IF EXISTS geolocation;

CREATE TABLE customers (
    customer_id             VARCHAR(50) PRIMARY KEY,
    customer_unique_id      VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city           VARCHAR(100),
    customer_state          CHAR(2)
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat             DECIMAL(18, 15),
    geolocation_lng             DECIMAL(18, 15),
    geolocation_city            VARCHAR(100),
    geolocation_state           CHAR(2)
);

CREATE TABLE sellers (
    seller_id               VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix  VARCHAR(10),
    seller_city             VARCHAR(100),
    seller_state            CHAR(2)
);

CREATE TABLE product_category_translation (
    product_category_name           VARCHAR(100) PRIMARY KEY,
    product_category_name_english   VARCHAR(100)
);

CREATE TABLE products (
    product_id                  VARCHAR(50) PRIMARY KEY,
    product_category_name       VARCHAR(100),
    product_name_lenght         INT,
    product_description_lenght  INT,
    product_photos_qty          INT,
    product_weight_g            INT,
    product_length_cm           INT,
    product_height_cm           INT,
    product_width_cm            INT
);

CREATE TABLE orders (
    order_id                        VARCHAR(50) PRIMARY KEY,
    customer_id                     VARCHAR(50),
    order_status                    VARCHAR(20),
    order_purchase_timestamp        DATETIME,
    order_approved_at               DATETIME,
    order_delivered_carrier_date    DATETIME,
    order_delivered_customer_date   DATETIME,
    order_estimated_delivery_date   DATETIME,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_id            VARCHAR(50),
    order_item_id       INT,
    product_id          VARCHAR(50),
    seller_id           VARCHAR(50),
    shipping_limit_date DATETIME,
    price               DECIMAL(10, 2),
    freight_value       DECIMAL(10, 2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);

CREATE TABLE order_payments (
    order_id                VARCHAR(50),
    payment_sequential      INT,
    payment_type            VARCHAR(20),
    payment_installments    INT,
    payment_value           DECIMAL(10, 2),
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE order_reviews (
    review_id               VARCHAR(50),
    order_id                VARCHAR(50),
    review_score            TINYINT,
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    DATETIME,
    review_answer_timestamp DATETIME,
    PRIMARY KEY (review_id, order_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- ============================================================
-- LOAD DATA
-- Update the file paths below to match your local CSV location.
-- Example path (Windows): 'C:/Users/austi/OneDrive/Documents/Cowork OS/Portfolio Projects/Project 1 - E-Commerce Analysis/data/olist_customers_dataset.csv'
-- Use forward slashes even on Windows.
-- ============================================================

LOAD DATA LOCAL INFILE 'YOUR_PATH/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state);

LOAD DATA LOCAL INFILE 'YOUR_PATH/olist_geolocation_dataset.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state);

LOAD DATA LOCAL INFILE 'YOUR_PATH/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(seller_id, seller_zip_code_prefix, seller_city, seller_state);

LOAD DATA LOCAL INFILE 'YOUR_PATH/product_category_name_translation.csv'
INTO TABLE product_category_translation
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_category_name, product_category_name_english);

LOAD DATA LOCAL INFILE 'YOUR_PATH/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_category_name, product_name_lenght, product_description_lenght,
 product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm);

LOAD DATA LOCAL INFILE 'YOUR_PATH/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at,
 order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date);

LOAD DATA LOCAL INFILE 'YOUR_PATH/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value);

LOAD DATA LOCAL INFILE 'YOUR_PATH/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, payment_sequential, payment_type, payment_installments, payment_value);

LOAD DATA LOCAL INFILE 'YOUR_PATH/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(review_id, order_id, review_score, review_comment_title, review_comment_message,
 review_creation_date, review_answer_timestamp);

-- ============================================================
-- VERIFY LOAD
-- Run these after loading to confirm row counts look right.
-- ============================================================

SELECT 'customers'                  AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'geolocation',     COUNT(*) FROM geolocation
UNION ALL SELECT 'sellers',         COUNT(*) FROM sellers
UNION ALL SELECT 'products',        COUNT(*) FROM products
UNION ALL SELECT 'orders',          COUNT(*) FROM orders
UNION ALL SELECT 'order_items',     COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments',  COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews',   COUNT(*) FROM order_reviews
UNION ALL SELECT 'product_category_translation', COUNT(*) FROM product_category_translation;
