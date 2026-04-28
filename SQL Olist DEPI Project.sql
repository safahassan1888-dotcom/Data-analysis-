/* ============================
  1: Data Model & Cleaning
   ============================ */

-- Customers Table
DROP TABLE IF EXISTS olist_customers_dataset;
CREATE TABLE olist_customers_dataset (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

-- Geolocation Table
DROP TABLE IF EXISTS olist_geolocation_dataset;
CREATE TABLE olist_geolocation_dataset (
    geolocation_zip_code_prefix INT,
    geolocation_lat FLOAT,
    geolocation_lng FLOAT,
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(10)
);

-- Orders Table
DROP TABLE IF EXISTS olist_orders_dataset;
CREATE TABLE olist_orders_dataset (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    FOREIGN KEY (customer_id) REFERENCES olist_customers_dataset(customer_id)
);

-- Order Items Table
DROP TABLE IF EXISTS olist_order_items_dataset;
CREATE TABLE olist_order_items_dataset (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price FLOAT,
    freight_value FLOAT,
    PRIMARY KEY (order_id, order_item_id)
);

-- Payments Table
DROP TABLE IF EXISTS olist_order_payments_dataset;
CREATE TABLE olist_order_payments_dataset (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value FLOAT
);

-- Reviews Table
DROP TABLE IF EXISTS olist_order_reviews_dataset;
CREATE TABLE olist_order_reviews_dataset (
    review_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message VARCHAR(MAX),
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);

-- Products Table
DROP TABLE IF EXISTS olist_products_dataset;
CREATE TABLE olist_products_dataset (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g FLOAT,
    product_length_cm FLOAT,
    product_height_cm FLOAT,
    product_width_cm FLOAT
);

-- Sellers Table
DROP TABLE IF EXISTS olist_sellers_dataset;
CREATE TABLE olist_sellers_dataset (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);

-- Product Category Translation Table
DROP TABLE IF EXISTS product_category_name_translation;
CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);


/* ============================
   2: Analysis Questions:
   Sales & Payments
   ============================ */

-- Orders per Month
SELECT 
    YEAR(order_purchase_timestamp) AS Year,
    MONTH(order_purchase_timestamp) AS Month,
    COUNT(order_id) AS Total_Orders
FROM olist_orders_dataset
GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)
ORDER BY Year, Month;

-- Distribution of Order Status
SELECT 
    order_status,
    COUNT(order_id) AS Total_Orders
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY Total_Orders DESC;


-- Most Frequently Used Payment Type
SELECT 
    payment_type,
    COUNT(order_id) AS Total_Orders
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY Total_Orders DESC;


-- Typical Number of Installments
SELECT 
    payment_installments,
    COUNT(order_id) AS Total_Orders
FROM olist_order_payments_dataset
GROUP BY payment_installments
ORDER BY Total_Orders DESC;


-- Average Payment Value per Order
SELECT 
    AVG(payment_value) AS Avg_Payment_Value
FROM olist_order_payments_dataset;


-- Monthly Revenue Growth
SELECT 
    YEAR(o.order_purchase_timestamp) AS Year,
    MONTH(o.order_purchase_timestamp) AS Month,
    SUM(p.payment_value) AS Monthly_Revenue
FROM olist_orders_dataset o
JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
GROUP BY YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp)
ORDER BY Year, Month;


-- Delivered vs Canceled Orders
SELECT 
    order_status,
    COUNT(order_id) AS Total_Orders,
    CAST(COUNT(order_id) * 100.0 / (SELECT COUNT(order_id) FROM olist_orders_dataset) AS DECIMAL(5,2)) AS Percentage
FROM olist_orders_dataset
WHERE order_status IN ('delivered','canceled')
GROUP BY order_status;


-- Average Delivery Delay
SELECT 
    AVG(DATEDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date)) AS Avg_Delivery_Delay
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


  -- Top Cities and States by Orders
SELECT 
    c.customer_state,
    c.customer_city,
    COUNT(o.order_id) AS Total_Orders
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state, c.customer_city
ORDER BY Total_Orders DESC;


-- Late vs On-Time Orders
SELECT 
    CASE 
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On Time'
        ELSE 'Late'
    END AS Delivery_Status,
    COUNT(order_id) AS Total_Orders
FROM olist_orders_dataset
WHERE order_status = 'delivered'
GROUP BY CASE 
            WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On Time'
            ELSE 'Late'
         END;


         -- Average Shipping Lead Time
SELECT 
    AVG(DATEDIFF(DAY, order_approved_at, order_delivered_carrier_date)) AS Avg_Shipping_Lead_Time
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_carrier_date IS NOT NULL
  AND order_approved_at IS NOT NULL;


  -- Regional Bottlenecks
SELECT 
    c.customer_state,
    AVG(DATEDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date)) AS Avg_Delay
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY Avg_Delay DESC;


/* ============================
    3: Forecasting:
    Products & Inventory
   ============================ */

-- Highest Revenue by Category
SELECT 
    p.product_category_name,
    SUM(oi.price) AS Total_Revenue
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY Total_Revenue DESC;


-- Best-Selling Products by Volume
SELECT 
    product_id,
    COUNT(order_id) AS Total_Sold
FROM olist_order_items_dataset
GROUP BY product_id
ORDER BY Total_Sold DESC;


-- Average Product Weight per Category
SELECT 
    p.product_category_name,
    AVG(p.product_weight_g) AS Avg_Weight
FROM olist_products_dataset p
GROUP BY p.product_category_name
ORDER BY Avg_Weight DESC;


-- Relationship Between Weight and Freight Value
SELECT 
    p.product_weight_g,
    oi.freight_value
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
WHERE p.product_weight_g IS NOT NULL AND oi.freight_value IS NOT NULL;


-- Frequently Bundled Products
SELECT 
    order_id,
    STRING_AGG(product_id, ', ') AS Bundled_Products
FROM olist_order_items_dataset
GROUP BY order_id
HAVING COUNT(DISTINCT product_id) > 1;


-- Product Dimensions Impact on Freight Cost
SELECT 
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    oi.freight_value
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
WHERE oi.freight_value IS NOT NULL;



/* ============================
  4:Dashboard & KPIs:
   Customers, Sellers & Reviews
   ============================ */
-- New vs Repeat Customers
SELECT 
    customer_unique_id,
    COUNT(order_id) AS Orders_Count,
    CASE 
        WHEN COUNT(order_id) = 1 THEN 'New'
        ELSE 'Repeat'
    END AS Customer_Type
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
GROUP BY customer_unique_id;


-- Average Review Score
SELECT 
    AVG(review_score) AS Avg_Review_Score
FROM olist_order_reviews_dataset;


-- Top Sellers by Revenue
SELECT 
    seller_id,
    SUM(price) AS Total_Revenue
FROM olist_order_items_dataset
GROUP BY seller_id
ORDER BY Total_Revenue DESC;


-- Revenue Concentration Among Sellers
SELECT 
    seller_id,
    SUM(price) AS Total_Revenue
FROM olist_order_items_dataset
GROUP BY seller_id
ORDER BY Total_Revenue DESC;


-- Review Score Trends Over Time
SELECT 
    YEAR(review_creation_date) AS Year,
    MONTH(review_creation_date) AS Month,
    AVG(review_score) AS Avg_Score
FROM olist_order_reviews_dataset
GROUP BY YEAR(review_creation_date), MONTH(review_creation_date)
ORDER BY Year, Month;


-- States Contribution to Sales Volume
SELECT 
    c.customer_state,
    s.seller_state,
    COUNT(o.order_id) AS Total_Orders
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
JOIN olist_sellers_dataset s ON oi.seller_id = s.seller_id
GROUP BY c.customer_state, s.seller_state
ORDER BY Total_Orders DESC;


EXEC sp_rename 'OLIST_CUSTOMERS_DATASET.customer_id', 'CUSTOMER_ID', 'COLUMN';
EXEC sp_rename 'OLIST_CUSTOMERS_DATASET.customer_unique_id', 'CUSTOMER_UNIQUE_ID', 'COLUMN';
EXEC sp_rename 'OLIST_CUSTOMERS_DATASET.customer_zip_code_prefix', 'CUSTOMER_ZIP_CODE_PREFIX', 'COLUMN';
EXEC sp_rename 'OLIST_CUSTOMERS_DATASET.customer_city', 'CUSTOMER_CITY', 'COLUMN';
EXEC sp_rename 'OLIST_CUSTOMERS_DATASET.customer_state', 'CUSTOMER_STATE', 'COLUMN';

