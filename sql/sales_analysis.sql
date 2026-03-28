CREATE DATABASE ecommerce_analysis;
USE ecommerce_analysis;
CREATE TABLE customers (
customer_id VARCHAR(50),
customer_unique_id VARCHAR(50),
customer_zip_code_prefix INT,
customer_city VARCHAR(50),
customer_state VARCHAR(5)
);
SELECT COUNT(*) FROM customers;
SELECT * FROM customers LIMIT 10;
CREATE TABLE customers_clean AS
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix AS zip_prefix,
    customer_city,
    customer_state
FROM customers;
SELECT customer_id, COUNT(*)
FROM customers_clean
GROUP BY customer_id
HAVING COUNT(*) > 1;

CREATE TABLE orders (
order_id TEXT,
customer_id TEXT,
order_status TEXT,
order_purchase_timestamp TEXT,
order_approved_at TEXT,
order_delivered_carrier_date TEXT,
order_delivered_customer_date TEXT,
order_estimated_delivery_date TEXT
);
SELECT COUNT(*) FROM orders;
SELECT * FROM orders LIMIT 10;
SELECT COUNT(*) FROM orders WHERE order_delivered_customer_date='';
SET SQL_SAFE_UPDATES = 0;
UPDATE orders SET order_delivered_customer_date = NULL WHERE order_delivered_customer_date='';
SELECT COUNT(*) FROM orders WHERE order_delivered_carrier_date = '';
UPDATE orders SET order_delivered_carrier_date = NULL WHERE order_delivered_carrier_date = '';
SELECT COUNT(*) FROM orders WHERE order_delivered_carrier_date IS NULL;
ALTER TABLE orders 
MODIFY order_purchase_timestamp DATETIME;
SELECT COUNT(*) FROM orders WHERE order_approved_at='';
UPDATE orders SET order_approved_at = NULL WHERE order_approved_at = '';
CREATE TABLE orders_clean AS
SELECT
    order_id,
    customer_id,
    order_status,
    STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s') AS purchase_time,
    STR_TO_DATE(order_approved_at, '%Y-%m-%d %H:%i:%s') AS approved_time,
    STR_TO_DATE(order_delivered_carrier_date, '%Y-%m-%d %H:%i:%s') AS carrier_time,
    STR_TO_DATE(order_delivered_customer_date, '%Y-%m-%d %H:%i:%s') AS delivered_time,
    STR_TO_DATE(order_estimated_delivery_date, '%Y-%m-%d %H:%i:%s') AS estimated_time
FROM orders;
SELECT * FROM orders_clean LIMIT 10;
SELECT order_id, COUNT(*)
FROM orders_clean
GROUP BY order_id
HAVING COUNT(*) > 1;
DESCRIBE orders_clean;


CREATE TABLE order_items (
order_id TEXT,
order_item_id INT,
product_id TEXT,
seller_id TEXT,
shipping_limit_date TEXT,
price NUMERIC,
freight_value NUMERIC
);
DESCRIBE order_items;
SELECT * FROM order_items LIMIT 10;
CREATE TABLE order_items_clean AS
SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    STR_TO_DATE(shipping_limit_date, '%Y-%m-%d %H:%i:%s') AS shipping_limit_time,
    price,
    freight_value
FROM order_items;
SELECT order_id, order_item_id, COUNT(*) AS duplicate_count
FROM order_items_clean
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

CREATE TABLE reviews (
review_id TEXT,
order_id TEXT,
review_score INT,
review_comment_title TEXT,
review_comment_message TEXT,
review_creation_date TIMESTAMP,
review_answer_timestamp TIMESTAMP
);
SELECT * FROM reviews LIMIT 10;
DESCRIBE reviews;
CREATE TABLE reviews_clean AS
SELECT
    review_id,
    order_id,
    CAST(NULLIF(review_score, '') AS UNSIGNED) AS review_score,
    NULLIF(TRIM(review_comment_title), '') AS review_title,
    NULLIF(TRIM(review_comment_message), '') AS review_message,
    STR_TO_DATE(NULLIF(TRIM(review_creation_date), ''), '%Y-%m-%d %H:%i:%s') 
        AS review_created_at,
    STR_TO_DATE(NULLIF(TRIM(review_answer_timestamp), ''), '%Y-%m-%d %H:%i:%s') 
        AS review_answered_at
FROM reviews;
SELECT order_id, COUNT(*) AS duplicate_count
FROM reviews_clean
GROUP BY order_id
HAVING COUNT(*) > 1;

CREATE TABLE products (
product_id TEXT,
product_category_name TEXT,
product_name_lenght TEXT,
product_description_lenght TEXT,
product_photos_qty TEXT,
product_weight_g TEXT,
product_length_cm TEXT,
product_height_cm TEXT,
product_width_cm TEXT
);
CREATE TABLE products_clean AS
SELECT
    product_id,
    NULLIF(product_category_name, '') AS category_name,
    CAST(NULLIF(product_name_lenght, '') AS UNSIGNED) AS name_length,
    CAST(NULLIF(product_description_lenght, '') AS UNSIGNED) AS description_length,
    CAST(NULLIF(product_photos_qty, '') AS UNSIGNED) AS photo_count,
    CAST(NULLIF(product_weight_g, '') AS DECIMAL(10,2)) AS weight_grams,
    CAST(NULLIF(product_length_cm, '') AS DECIMAL(10,2)) AS length_cm,
    CAST(NULLIF(product_height_cm, '') AS DECIMAL(10,2)) AS height_cm,
    CAST(NULLIF(product_width_cm, '') AS DECIMAL(10,2)) AS width_cm
FROM products;
SELECT product_id, COUNT(*) AS duplicate_count
FROM products_clean
GROUP BY product_id
HAVING COUNT(*) > 1;

CREATE TABLE payments (
order_id TEXT,
payment_sequential INT,
payment_type TEXT,
payment_installments INT,
payment_value NUMERIC
);
CREATE TABLE payments_clean AS
SELECT
    order_id,
    payment_sequential AS payment_seq,
    payment_type,
    payment_installments AS installments,
    payment_value AS payment_amount
FROM payments;
SELECT order_id, COUNT(*) AS payment_rows
FROM payments_clean
GROUP BY order_id
HAVING COUNT(*) > 1;

DROP TABLE IF EXISTS payments_agg;
CREATE TABLE payments_agg AS
SELECT
    order_id,
    ROUND(SUM(CAST(payment_amount AS DECIMAL(12,2))),2) AS total_payment,
    ROUND(AVG(CAST(installments AS DECIMAL(10,2))),2) AS avg_installments
FROM payments_clean
WHERE payment_amount IS NOT NULL
GROUP BY order_id;

DROP TABLE IF EXISTS master_orders;

CREATE TABLE master_orders AS
SELECT
    c.customer_unique_id,
    c.customer_id,
    c.customer_city,
    c.customer_state,
    o.order_id,
    o.order_status,
    o.purchase_time,
    o.delivered_time,
    o.estimated_time,
    CASE
        WHEN o.delivered_time IS NOT NULL
        AND o.estimated_time IS NOT NULL
        THEN DATEDIFF(o.delivered_time, o.estimated_time)
        ELSE NULL
    END AS delivery_delay,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value,
    p.category_name,
    p.weight_grams,
    pay.total_payment AS payment_amount,
    pay.avg_installments AS installments,
    r.review_score
FROM customers_clean c
JOIN orders_clean o 
    ON c.customer_id = o.customer_id
JOIN order_items_clean oi 
    ON o.order_id = oi.order_id
LEFT JOIN products_clean p 
    ON oi.product_id = p.product_id
LEFT JOIN payments_agg pay 
    ON o.order_id = pay.order_id
LEFT JOIN reviews_clean r 
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered';

DESCRIBE master_orders;
ALTER TABLE master_orders
MODIFY seller_id VARCHAR(50),
MODIFY order_id VARCHAR(50);
SELECT DISTINCT order_status FROM master_orders;
CREATE INDEX idx_customer ON master_orders(customer_unique_id);
CREATE INDEX idx_seller ON master_orders(seller_id);
CREATE INDEX idx_order ON master_orders(order_id);
SELECT *
FROM master_orders
WHERE price > 5000
ORDER BY price DESC;

SELECT
    review_score,
    AVG(delivery_delay) AS avg_delay_days,
    COUNT(DISTINCT order_id) AS total_orders
FROM master_orders
WHERE review_score IS NOT NULL
GROUP BY review_score
ORDER BY review_score;

SELECT
    CASE
        WHEN price < 50 THEN 'Low'
        WHEN price BETWEEN 50 AND 200 THEN 'Medium'
        ELSE 'High'
    END AS price_segment,
    AVG(review_score) AS avg_review,
    COUNT(DISTINCT order_id) AS total_orders
FROM master_orders
WHERE review_score IS NOT NULL
GROUP BY price_segment;

SELECT
    seller_id,
    AVG(delivery_delay) AS avg_delay_days,
    COUNT(DISTINCT order_id) AS total_orders
FROM master_orders
GROUP BY seller_id
ORDER BY avg_delay_days DESC
LIMIT 10;

SELECT
    customer_unique_id,
    COUNT(DISTINCT order_id) AS total_orders,
    AVG(review_score) AS avg_review
FROM master_orders
GROUP BY customer_unique_id;

SELECT
    CASE
        WHEN total_orders = 1 THEN 'Single'
        ELSE 'Repeat'
    END AS customer_type,
    AVG(avg_review) AS avg_rating
FROM (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS total_orders,
        AVG(review_score) AS avg_review
    FROM master_orders
    GROUP BY customer_unique_id
) t
GROUP BY customer_type;

SELECT
    customer_unique_id,
    COUNT(DISTINCT order_id) AS total_orders,
    AVG(delivery_delay) AS avg_delay
FROM master_orders
GROUP BY customer_unique_id;

SELECT
    seller_id,
    SUM(price) AS total_revenue,
    AVG(delivery_delay) AS avg_delay,
    AVG(review_score) AS avg_rating,
    (
        (AVG(delivery_delay) * 0.4) +
        ((5 - AVG(review_score)) * 0.6)
    ) AS risk_score
FROM master_orders
WHERE review_score IS NOT NULL
GROUP BY seller_id
ORDER BY risk_score DESC
LIMIT 15;

SELECT
    CASE
        WHEN freight_value < 10 THEN 'Low Freight'
        WHEN freight_value BETWEEN 10 AND 30 THEN 'Medium Freight'
        ELSE 'High Freight'
    END AS freight_segment,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(price) AS total_revenue,
    AVG(review_score) AS avg_review
FROM master_orders
GROUP BY freight_segment;

SELECT
    delivery_delay,
    freight_value,
    price,
    installments,
    review_score
FROM master_orders
WHERE review_score IS NOT NULL;

DROP TABLE IF EXISTS customer_model_data;

CREATE TABLE customer_model_data (
    customer_unique_id VARCHAR(50),
    total_orders INT,
    total_revenue DECIMAL(12,2),
    avg_review DECIMAL(4,2),
    avg_delay DECIMAL(6,2),
    avg_installments DECIMAL(6,2)
);
INSERT INTO customer_model_data
SELECT
    customer_unique_id,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(price),2) AS total_revenue,
    ROUND(AVG(review_score),2) AS avg_review,
    ROUND(AVG(delivery_delay),2) AS avg_delay,
    ROUND(AVG(installments),2) AS avg_installments
FROM master_orders
GROUP BY customer_unique_id;
SELECT *
FROM city_analysis
ORDER BY total_revenue DESC
LIMIT 20;
SELECT *
FROM (
    SELECT *
    FROM city_analysis
    ORDER BY total_revenue DESC
    LIMIT 20
) t
ORDER BY avg_rating ASC;

SELECT
    SUM(total_revenue) AS revenue_from_churned
FROM customer_model_data
WHERE total_orders = 1;
SELECT SUM(total_revenue) FROM customer_model_data;
SELECT * FROM master_orders;
SELECT * FROM customer_model_data;
