-- =================================================================
-- Step 1: Create Staging Tables for Raw Data
-- =================================================================

-- These tables are temporary holding areas for the initial CSV data.

CREATE OR REPLACE TABLE raw_products (
    product_id NUMBER,
    product_name VARCHAR,
    category VARCHAR,
    brand VARCHAR
);

CREATE OR REPLACE TABLE raw_sales (
    sale_id NUMBER,
    product_id NUMBER,
    store_id NUMBER,
    customer_id NUMBER,
    date DATE,
    units_sold NUMBER,
    unit_price NUMBER(10, 2)
);

-- NOTE: At this point, the user should manually load the CSV data
-- into the above tables using the Snowflake UI.

-- =================================================================
-- Step 2: Build the Star Schema (Dimension and Fact Tables)
-- =================================================================

--
-- DIMENSION TABLES
--

USE DATABASE MY_DB;
USE SCHEMA PUBLIC;

-- Create and populate the Product Dimension
CREATE OR REPLACE TABLE dim_product (
    product_key NUMBER PRIMARY KEY,
    product_id NUMBER,
    product_name VARCHAR,
    category VARCHAR,
    brand VARCHAR
);

INSERT INTO dim_product (product_key, product_id, product_name, category, brand)
SELECT product_id, product_id, product_name, category, brand FROM raw_products;


-- Create and populate the Store Dimension
CREATE OR REPLACE TABLE dim_store (
    store_key NUMBER PRIMARY KEY,
    store_id NUMBER
);

INSERT INTO dim_store (store_key, store_id)
SELECT DISTINCT store_id, store_id FROM raw_sales;


-- Create and populate the Date Dimension
CREATE OR REPLACE TABLE dim_date (
    date_key DATE PRIMARY KEY,
    full_date DATE,
    day_of_week VARCHAR(9),
    month_name VARCHAR(3),
    month_number NUMBER,
    quarter NUMBER,
    year NUMBER
);

INSERT INTO dim_date (date_key, full_date, day_of_week, month_name, month_number, quarter, year)
SELECT DISTINCT
    date AS date_key,
    date AS full_date,
    DAYNAME(date) AS day_of_week,
    MONTHNAME(date) AS month_name,
    MONTH(date) AS month_number,
    QUARTER(date) AS quarter,
    YEAR(date) AS year
FROM raw_sales
ORDER BY date_key;


--
-- FACT TABLE
--

CREATE OR REPLACE TABLE fact_sales (
    sale_id NUMBER PRIMARY KEY,
    date_key DATE,
    product_key NUMBER,
    store_key NUMBER,
    customer_id NUMBER,
    units_sold NUMBER,
    unit_price NUMBER(10, 2),
    total_revenue NUMBER(12, 2),
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    FOREIGN KEY (store_key) REFERENCES dim_store(store_key)
);

INSERT INTO fact_sales (sale_id, date_key, product_key, store_key, customer_id, units_sold, unit_price, total_revenue)
SELECT
    s.sale_id,
    s.date,
    s.product_id,
    s.store_id,
    s.customer_id,
    s.units_sold,
    s.unit_price,
    s.units_sold * s.unit_price AS total_revenue
FROM raw_sales s;