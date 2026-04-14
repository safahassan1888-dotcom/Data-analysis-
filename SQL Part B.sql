SH.(Logistics & Delivery)
 CREATE TABLE olist_customers_dataset (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);
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
SELECT 
    o.order_id,
    c.customer_state,
    o.order_purchase_timestamp,
    DATEDIFF(day, o.order_estimated_delivery_date, o.order_delivered_customer_date) AS delivery_accuracy_days,
    DATEDIFF(day, o.order_delivered_carrier_date, o.order_delivered_customer_date) AS shipping_time_days,

    CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'On Time or Early'
        ELSE 'Late'
    END AS delivery_status
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL;
  SELECT 
    c.customer_state,
    AVG(DATEDIFF(day, o.order_estimated_delivery_date, o.order_delivered_customer_date)) AS avg_delay_days,
    COUNT(o.order_id) AS total_orders
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_delay_days DESC; 

-- ============================================
-- Data Cleaning & Preprocessing – (Logistics & Delivery)
-- ============================================

-- Step 1: Convert date columns to DATETIME
ALTER TABLE olist_orders_dataset ALTER COLUMN order_purchase_timestamp DATETIME;
ALTER TABLE olist_orders_dataset ALTER COLUMN order_approved_at DATETIME;
ALTER TABLE olist_orders_dataset ALTER COLUMN order_delivered_carrier_date DATETIME;
ALTER TABLE olist_orders_dataset ALTER COLUMN order_delivered_customer_date DATETIME;
ALTER TABLE olist_orders_dataset ALTER COLUMN order_estimated_delivery_date DATETIME;

-- Step 2: Identify missing values in delivery date
SELECT order_id, order_status
FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NULL;

-- Step 2 (continued): Use conditions instead of UPDATE
SELECT AVG(DATEDIFF(day, order_estimated_delivery_date, order_delivered_customer_date)) AS avg_delay
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;

-- Step 3: Standardize state names to uppercase
UPDATE olist_customers_dataset
SET customer_state = UPPER(customer_state);

-- Step 4 (continued): Verify states after update
SELECT DISTINCT customer_state
FROM olist_customers_dataset
ORDER BY customer_state;


 --Notebook Outline :

 1: Average Delivery Delay
SELECT 
    AVG(DATEDIFF(day, order_estimated_delivery_date, order_delivered_customer_date)) AS avg_delivery_delay
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;
 
  2: Top States/Cities by Orders

 SELECT 
    c.customer_state,
    c.customer_city,
    COUNT(o.order_id) AS total_orders
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state, c.customer_city
ORDER BY total_orders DESC;

3: Late vs On-Time Orders
SELECT 
    CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(o.order_id) AS total_orders
FROM olist_orders_dataset o
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY 
    CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'On Time'
        ELSE 'Late'
        END;
       
  4: Shipping Lead Time

    SELECT 
    AVG(DATEDIFF(day, order_approved_at, order_delivered_carrier_date)) AS avg_shipping_lead_time
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_carrier_date IS NOT NULL
  AND order_approved_at IS NOT NULL;
