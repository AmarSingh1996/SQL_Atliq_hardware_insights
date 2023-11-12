#-----------------------Provide Insights to Management in Consumer Goods Domain----------------------------#

select * from dim_customer;

-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
select market from dim_customer
where customer = "Atliq Exclusive" and region = "APAC";

-----------------------------------------------------------------------------------------------------

-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg
select * from dim_product;
select * from fact_gross_price;

SELECT 
  COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN dp.product_code END) AS unique_products_2020,
  COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN dp.product_code END) AS unique_products_2021,
  100 * (COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN dp.product_code END) - COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN dp.product_code END)) / COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN dp.product_code END) AS percentage_chg
FROM 
  dim_product dp
  JOIN fact_gross_price fgp ON dp.product_code = fgp.product_code
WHERE
  fiscal_year IN (2020, 2021)
  
-- ---------------------------------------------------------------------------------------------------

-- 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields, segment product_count

SELECT segment, COUNT(DISTINCT product) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- ---------------------------------------------------------------------------------------------------
-- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, segment product_count_2020 product_co

SELECT dp.segment, 
  COUNT(DISTINCT CASE WHEN fgp.fiscal_year = 2020 THEN dp.product_code END) AS product_count_2020,
  COUNT(DISTINCT CASE WHEN fgp.fiscal_year = 2021 THEN dp.product_code END) AS product_count_2021,
  COUNT(DISTINCT CASE WHEN fgp.fiscal_year = 2021 THEN dp.product_code END) - COUNT(DISTINCT CASE WHEN fgp.fiscal_year = 2020 THEN dp.product_code END) AS difference
FROM dim_product dp
JOIN fact_gross_price fgp ON dp.product_code = fgp.product_code
GROUP BY dp.segment
ORDER BY difference DESC;

-- ---------------------------------------------------------------------------------------------------
-- 5. Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code product manufacturing_cost

select dp.product_code, dp.product, fmc.manufacturing_cost
from dim_product dp
join fact_manufacturing_cost fmc on dp.product_code = fmc.product_code
WHERE 
  fmc.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost) 
  OR fmc.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost);
  
  
  -- ---------------------------------------------------------------------------------------------------

-- 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these fields, customer_code customer average_discount_percentage
-- select * from dim_customer where market = 'india';

select dc.customer_code, dc.customer, avg(fpid.pre_invoice_discount_pct) as average_discount_percentage
from dim_customer dc
join fact_pre_invoice_deductions fpid on dc.customer_code = fpid.customer_code
where dc.market = 'India' and fpid.fiscal_year = 2021
group by dc.customer_code, dc.customer
order by average_discount_percentage desc
limit 5;

-- ---------------------------------------------------------------------------------------------------
-- 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . This analysis helps to get an idea of low and high-performing months and take strategic decisions. The final report contains these columns: Month Year Gross sales Amount
-- gross_sales_amt = gross_price * sold_quantity

SELECT MONTH(fs.date) AS Month, YEAR(fs.date) AS Year, Round(SUM(fs.sold_quantity * fg.gross_price),3) AS Gross_Sales_Amount
FROM dim_customer dc
  JOIN fact_sales_monthly fs ON dc.customer_code = fs.customer_code
  JOIN fact_gross_price fg ON fs.product_code = fg.product_code AND fs.fiscal_year = fg.fiscal_year
WHERE dc.customer = 'Atliq Exclusive' 
GROUP BY YEAR(fs.date), MONTH(fs.date)
ORDER BY YEAR(fs.date) ASC, MONTH(fs.date) ASC;


-- ---------------------------------------------------------------------------------------------------
-- 8. In which quarter of 2020, got the maximum total_sold_quantzity? The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity
-- SELECT CONCAT(YEAR(date), '-Q', QUARTER(date)) AS quarter from fact_sales_monthly

SELECT CONCAT(YEAR(date), '-Q', QUARTER(date)) AS quarter, SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE YEAR(date) = 2020
GROUP BY quarter
ORDER BY total_sold_quantity DESC
LIMIT 1;

-- ---------------------------------------------------------------------------------------------------
-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields, channel gross_sales_mln percentage
-- select channel from dim_customer;

select dc.channel, 
	round(sum(fg.gross_price * fs.sold_quantity),3) as gross_sales_mln,
	round(sum((fg.gross_price * fs.sold_quantity) / (SELECT SUM(gross_price) 
    FROM fact_gross_price WHERE fiscal_year = 2021) * 100),3) AS percentage
from fact_gross_price fg
join fact_sales_monthly fs on fg.product_code = fs.product_code and fg.fiscal_year = fs.fiscal_year
join dim_customer dc on fs.customer_code = dc.customer_code
WHERE fg.fiscal_year = 2021
GROUP BY dc.channel
ORDER BY gross_sales_mln DESC
LIMIT 1;

-- ---------------------------------------------------------------------------------------------------
-- 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields, division product_code product total_sold_quantity rank_order

WITH cte AS (
    SELECT dp.division, dp.product_code, dp.product,
        SUM(fs.sold_quantity) AS total_sold_quantity,
        RANK() OVER (PARTITION BY dp.division ORDER BY SUM(fs.sold_quantity) DESC) AS rank_order
    FROM dim_product dp
	INNER JOIN fact_sales_monthly fs ON dp.product_code = fs.product_code
    WHERE fs.fiscal_year = 2021
    GROUP BY dp.division, dp.product_code, dp.product
)
SELECT division, product_code, product, total_sold_quantity, rank_order
FROM cte
WHERE rank_order <= 3
ORDER BY division, rank_order

-- --------------------------------------------------------------------------------------------------


