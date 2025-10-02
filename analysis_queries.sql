-- SELECT *
-- FROM sales_clean;

SELECT *
FROM information_schema.columns
WHERE table_name = 'sales_clean2';


-- Create sales data date table from invoice_date range.
CREATE TABLE sales_dates AS (
	WITH dates_cte AS (
		SELECT
			GENERATE_SERIES(
				DATE_TRUNC('day', MIN(invoice_date)), 
				DATE_TRUNC('day', MAX(invoice_date)), 
				'1 day') AS sales_date
		FROM sales_clean2
		)
	SELECT
		sales_date,
		DATE_PART('year', sales_date) AS year,
		DATE_PART('month', sales_date) AS month,
		DATE_PART('day', sales_date) AS day
	FROM dates_cte
	GROUP BY 1, 2, 3, 4
	ORDER BY sales_date);



-- TOP 10 SOLD PRODUCTS EACH MONTH
SELECT
	stock_code,
	description,
-- 	SUM(quantity) AS qty_sold,
-- 	SUM(quantity * unit_price) AS total_sales,
	date_trunc('month', invoice_date) AS sales_month
FROM sales_clean2
-- GROUP BY 1,2,5
-- ORDER BY sales_month, total_sales DESC;

-- with sales_rank AS (
	SELECT
		sd.year,
		sd.month,
		stock_code,
		description,
		SUM(quantity) AS qty_sold,
		SUM(quantity * unit_price) AS total_sales,
		DENSE_RANK() OVER(PARTITION BY sd.month ORDER BY SUM(quantity * unit_price) DESC) AS rank
	FROM sales_clean2 sc
	LEFT JOIN sales_dates sd
	ON date_part('month', sc.invoice_date) = sd.month
	GROUP BY 1, 2, 3, 4

-- 	)
-- SELECT *
-- FROM sales_rank
-- WHERE rank <= 10
-- ORDER BY DATE_PART('month', sales_date), rank

;




-- MONTHLY SALES W/ PCT CHANGE BY MONTH
WITH monthly_sales AS (
	SELECT
		date_trunc('month', invoice_date) AS sales_month,
		SUM(quantity * unit_price) AS total_sales
	FROM sales_clean2
	GROUP BY 1
	)
SELECT
	sales_month,
	total_sales,
	ROUND((total_sales - LAG(total_sales) OVER(ORDER BY sales_month))
		/LAG(total_sales) OVER(ORDER BY sales_month) * 100,1) AS pct_change
FROM monthly_sales


-- MEDIAN INVOICE SALE AMOUNT
-- WITH inv_cte AS (
-- 	SELECT
-- 		invoice_no,
-- 		SUM(quantity * unit_price) AS total
-- 	FROM sales_clean
-- 	GROUP BY invoice_no
-- 	)
-- SELECT 
-- 	PERCENTILE_CONT(.5) WITHIN GROUP (ORDER BY total)
-- FROM inv_cte



---- ITEMS IN INVOICE, NUMBER OF INVOICES, BUCKET CATEGORY
-- CREATE VIEW item_buckets AS 
-- (
-- WITH items_per_inv AS (
-- 	SELECT 
-- 		invoice_no,
-- 		COUNT(stock_code) AS items_in_order
-- 	FROM sales_clean
-- 	GROUP BY invoice_no
-- 	ORDER BY invoice_no
-- 	), 
-- 	item_inv_count AS (
-- 	SELECT
-- 		items_in_order,
-- 		COUNT(*) AS num_invoices
-- 	FROM items_per_inv
-- 	GROUP BY items_in_order
-- 	ORDER BY items_in_order
-- 	)
-- SELECT
-- 	*,
-- 	(CASE
-- 		WHEN items_in_order <= 5 THEN 'Small: 5 or Fewer'
-- 		WHEN items_in_order BETWEEN 5 AND 20 THEN 'Medium: Between 6 and 20'
-- 		WHEN items_in_order BETWEEN 20 AND 50 THEN 'Large: Between 21 and 50'
-- 		WHEN items_in_order > 50 THEN 'Bulk: More than 50'
-- 	END) as item_count_bucket
-- FROM item_inv_count
-- )
	
	
	
---- NUMBER OF INVOICES IN EACH BUCKET	
-- SELECT
-- 	item_count_bucket AS order_size,
-- 	SUM(num_invoices) AS number_of_orders
-- FROM item_buckets
-- GROUP BY item_count_bucket



--- TOTAL ONE TIME CUSTOMERS / REPEAT CUSTOMERS
-- WITH invoice_counts AS (
-- 	SELECT
-- 		customer_id,
-- 		invoice_no,
-- 		COUNT(invoice_no)
-- 	FROM sales_clean
-- 	GROUP BY customer_id, invoice_no
-- 	ORDER BY customer_id
-- 	),
-- 	inv_per_cust AS (
-- 	SELECT 
-- 		customer_id,
-- 		COUNT(invoice_no) AS invoices
-- 	FROM invoice_counts
-- 	GROUP BY customer_id
-- 	)
	
-- SELECT
-- 	SUM(CASE WHEN invoices = 1 THEN 1 END) AS one_time_customers,
-- 	SUM(CASE WHEN invoices > 1 THEN 1 END) AS repeat_customers
-- FROM inv_per_cust



---- CONDENSED LIST OF CUSTOMER ID, INVOICE NO, DATE, ITEMS PER INVOICE
-- CREATE VIEW invoices_condensed AS (
-- 	SELECT
-- 		customer_id,
-- 		invoice_no,
-- 		DATE_TRUNC('day', invoice_date) as date,
-- 		COUNT(invoice_no) AS items_per_inv
-- 	FROM sales_clean
-- 	GROUP BY 
-- 		customer_id, 
-- 		invoice_no,
-- 		date
-- 	ORDER BY customer_id
-- 	)



---- REPEAT CUSTOMERS/INVOICES/DATES OF INVOICES/ROLLING DIFFERENCE (TIME SINCE PREV ORDER)
-- list of customer ids w/ more than one invoice
WITH repeat_customers AS (
	SELECT customer_id
	FROM invoices_condensed
	GROUP BY customer_id
	HAVING COUNT(invoice_no) > 1
	)
-- calculate rolling difference from previous order for each customer
	, time_between AS (
	SELECT
		ic.customer_id,
		ic.invoice_no,
		ic.date,
		date - LAG(date) OVER(PARTITION BY ic.customer_id ORDER BY date) AS time_since_prev_order
	FROM invoices_condensed ic
	JOIN repeat_customers rc
		ON ic.customer_id = rc.customer_id
	)

-- CUSTOMER ID, MEDIAN RETURN TIME
SELECT
	customer_id,	
	DATE_TRUNC('day', PERCENTILE_CONT(.5) WITHIN GROUP(ORDER BY time_since_prev_order)) AS med_return_time
FROM time_between
GROUP BY customer_id




