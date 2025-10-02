-- create new database
CREATE DATABASE retail_sales;

-- create raw dataset table
DROP TABLE IF EXISTS sales_raw;
CREATE TABLE sales_raw (
	invoice_no varchar,
	stock_code varchar,
	description varchar,
	quantity int,
	invoice_date timestamp,
	unit_price decimal,
	customer_id varchar,
	country varchar
	);


---- copy csv dataset to raw data table
\copy sales_raw FROM 'C:\Users\steve\github_portfolio_repos\portfolio_projects\retail_sales\retail_sales_data.csv' DELIMITER ',' CSV HEADER;

-- inspect data: return summary of dataset
SELECT *
FROM sales_raw
LIMIT 5;

-- return column name and datatype
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'sales_raw';

--------------------------------------
-- # EDA, Cleaning, Processing

--  Create `TEMP TABLE sales_temp` from `sales` table to manipulate during cleaning and processing.

CREATE TEMP TABLE sales_temp AS
	SELECT *
	FROM sales_raw;

-- check for NULL values in ANY column
SELECT COUNT(*) AS null_values
FROM sales_temp
WHERE invoice_no ISNULL OR stock_code ISNULL OR description ISNULL
	OR quantity ISNULL OR invoice_date ISNULL OR unit_price ISNULL
	OR customer_id ISNULL OR country ISNULL OR quantity <= 0 OR
	unit_price <= 0;


-- check columns for NULL values and negative/0
-- customer_id NULL
SELECT COUNT(*) AS null_values
FROM sales_temp
WHERE customer_id ISNULL;

-- description NULL 
SELECT DISTINCT *
FROM sales_temp
WHERE description ISNULL;

-- quantity <= 0 
SELECT COUNT(*) AS less_0
FROM sales_temp
WHERE quantity <= 0;

-- unit_price <= 0 
SELECT COUNT(unit_price)
FROM sales_temp
WHERE unit_price <= 0;


-- delete NULL and 0 values from temp table
DELETE FROM sales_temp 
	WHERE quantity <= 0 
		OR	description ISNULL 
		OR	unit_price <= 0 
		OR customer_id ISNULL;


--- check successful update
SELECT COUNT(*) AS missing
FROM sales_temp
	WHERE quantity <= 0 
		OR	description ISNULL 
		OR	unit_price <= 0 
		OR customer_id ISNULL



-- total records
SELECT COUNT(*)
FROM sales_temp;

-- unique invoices
SELECT COUNT(DISTINCT invoice_no)
FROM sales_temp;

-- check unique stock codes and matching descriptions
SELECT COUNT(DISTINCT stock_code) AS stock_codes, 
		COUNT(DISTINCT description) AS descriptions
FROM sales_temp;


-- investigate stock_codes and descriptions
---- create TEMP TABLE with stock_code, descriptions, and row number partitioned by stock_code,
---- use this to return list of all stock codes with more than one description
DROP TABLE IF EXISTS stock_rows; 
CREATE TEMP TABLE stock_rows AS (
	WITH sc_list AS (
		SELECT DISTINCT stock_code
		FROM sales_temp
		ORDER BY stock_code
		)

	SELECT
		s.stock_code,
		s.description,
		ROW_NUMBER() OVER(PARTITION BY s.stock_code ORDER BY s.description) AS rn
	FROM sales_temp s
	LEFT JOIN sc_list sc
		ON s.stock_code = sc.stock_code
	GROUP BY s.stock_code, s.description
	ORDER BY stock_code
	);

SELECT stock_code, description
FROM stock_rows
WHERE stock_code IN (
	SELECT stock_code
	FROM stock_rows
	WHERE rn > 1)
ORDER BY stock_code;

----
-- UPDATE unique stock code-description pairs using first returned description
DROP TABLE IF EXISTS unique_stock_desc; 
CREATE TEMP TABLE unique_stock_desc AS 
	SELECT stock_code, description
	FROM stock_rows
	WHERE rn = 1 
	ORDER BY stock_code;

UPDATE sales_temp 
SET description	= (
	SELECT usd.description
	FROM unique_stock_desc usd
	WHERE usd.stock_code = sales_temp.stock_code)


-- check updated stock code and description counts
SELECT 
	COUNT(DISTINCT stock_code) AS stock_count, 
	COUNT(DISTINCT description) AS desc_count
FROM sales_temp



--------------------
-- investigate why there are more unique stock codes than descriptions
---- create TEMP TABLE with stock_code, descriptions, and row number partitioned by description,
---- use this to return list of all description with more than one stock code
DROP TABLE IF EXISTS desc_rows; 
CREATE TEMP TABLE desc_rows AS 
WITH sc_list AS ( -- return stock code list
	SELECT DISTINCT stock_code
	FROM sales_temp
	ORDER BY stock_code
	),
	desc_rows AS ( -- return descriptions/stock codes partitioned by description
	SELECT 
		s.description, 
		s.stock_code,
		ROW_NUMBER() OVER(PARTITION BY s.description ORDER BY s.stock_code) AS rn
	FROM sales_temp s
	LEFT JOIN sc_list sc
		ON s.stock_code = sc.stock_code
	GROUP BY s.stock_code, s.description
	ORDER BY description
	)

	SELECT description, stock_code, rn --return only results w/ duplicate descriptions
	FROM desc_rows
	WHERE description IN 
		(SELECT description
		FROM desc_rows
		WHERE rn > 1);

-- update duplicated descriptions w/ version numbers
UPDATE desc_rows
SET description = CONCAT(description, ' v', rn);

SELECT *
FROM desc_rows
LIMIT 5;


-- update unique stock code description table w/ updated descriptions
WITH desc_update AS (
	SELECT
		usd.stock_code,
		(CASE
			WHEN usd.stock_code IN 
				(SELECT dr.stock_code
				 FROM desc_rows)
			 THEN dr.description
			ELSE usd.description
		END) AS new_desc
	FROM unique_stock_desc usd
	LEFT JOIN desc_rows dr
		ON usd.stock_code = dr.stock_code
	)

UPDATE unique_stock_desc
SET description =
	(SELECT new_desc
	FROM desc_update du
	WHERE unique_stock_desc.stock_code = du.stock_code);


-- check that update was successful
SELECT *
FROM unique_stock_desc
LIMIT 5;


-- update sales_temp with new descriptions
UPDATE sales_temp
SET description = 
	(SELECT usd.description
	 FROM unique_stock_desc usd
	 WHERE sales_temp.stock_code = usd.stock_code);


-- check updated stock code and description counts
SELECT 
	COUNT(DISTINCT stock_code) AS stock_count, 
	COUNT(DISTINCT description) AS desc_count
FROM sales_temp;



-- remove unneccessary non-stock items
DELETE FROM sales_temp
WHERE stock_code IN ('M', 'POST', 'DOT', 'C2', 'PADS', 'BANK CHARGES');

SELECT COUNT(DISTINCT stock_code)
FROM sales_temp





-- final summary
SELECT 
	COUNT(*) AS records,
	COUNT(DISTINCT invoice_no) AS invoices,
	COUNT(DISTINCT stock_code) AS unique_stock_items,
	SUM(quantity) AS total_items_sold,
	ROUND(SUM(unit_price),2) AS total_sales,
	COUNT(DISTINCT customer_id) AS customers,
	COUNT(DISTINCT country) AS countries
FROM sales_temp




select * from sales_temp




