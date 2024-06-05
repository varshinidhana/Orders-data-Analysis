CREATE TABLE df_orders (
  order_id INT PRIMARY KEY,
  order_date VARCHAR(20),
  ship_mode VARCHAR(20),
  segment VARCHAR(20),
  country VARCHAR(20),
  city VARCHAR(20),
  state VARCHAR(20),
  postal_code VARCHAR(20),
  region VARCHAR(20),
  category VARCHAR(20),
  sub_category VARCHAR(20),
  product_id VARCHAR(20),
  quantity INT,
  discount DECIMAL(7, 2),
  sale_price DECIMAL(7, 2),
  profit DECIMAL(7, 2)
);

select* from df_orders;
--1.find top 10 highest reveue generating products 

SELECT product_id, SUM(sale_price) AS sales
FROM df_orders
GROUP BY product_id
ORDER BY sales DESC
LIMIT 10;    

-- 2.Find top 5 highest selling products in each region
WITH cte AS (
    SELECT 
        region,
        product_id,
        SUM(sale_price) AS sales
    FROM df_orders
    GROUP BY region, product_id
)
--3.find top 5 highest selling products in each region

WITH cte AS (
    SELECT 
        region,
        product_id,
        SUM(sale_price) AS sales
    FROM df_orders
    GROUP BY region, product_id
)
SELECT * FROM (
    SELECT 
        region,
        product_id,
        sales,
        ROW_NUMBER() OVER(PARTITION BY region ORDER BY sales DESC) AS rn
    FROM cte
) AS A
WHERE rn <= 5;

-- 4. Find month-over-month growth comparison for 2022 and 2023 sales
WITH cte AS (
    SELECT 
        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,
        SUM(sale_price) AS sales
    FROM df_orders
    GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT 
    order_month,
    SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS sales_2022,
    SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS sales_2023,
    (SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) - SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END)) / NULLIF(SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END), 0) * 100 AS growth_percentage
FROM 
    cte
GROUP BY 
    order_month
ORDER BY 
    order_month;


-- 5. For each category, find the month with the highest sales
WITH cte AS (
    SELECT 
        category,
        FORMAT(order_date, 'yyyyMM') AS order_year_month,
        SUM(sale_price) AS sales 
    FROM df_orders
    GROUP BY category, FORMAT(order_date, 'yyyyMM')
)
SELECT 
    *
FROM (
    SELECT 
        *,
        ROW_NUMBER() OVER(PARTITION BY category ORDER BY sales DESC) AS rn
    FROM cte
) a
WHERE rn = 1;

-- 6. Find the sub-category with the highest growth in profit from 2022 to 2023
WITH cte AS (
    SELECT 
        sub_category,
        YEAR(order_date) AS order_year,
        SUM(sale_price) AS sales
    FROM df_orders
    GROUP BY sub_category, YEAR(order_date)
),
cte2 AS (
    SELECT 
        sub_category,
        SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS sales_2022,
        SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS sales_2023
    FROM cte 
    GROUP BY sub_category
)
SELECT *
 ,(sales_2023 - sales_2022) AS growth_in_profit
FROM cte2
ORDER BY (sales_2023 - sales_2022) DESC
LIMIT 10;
