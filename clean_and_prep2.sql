-- Create new database.
CREATE DATABASE retail_sales;

-- Create table with column names that match the .csv headers.
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


---- Copy .csv dataset to raw data table in psql editor.
\copy sales_raw FROM 'C:\Users\steve\github_portfolio_repos\portfolio_projects\retail_sales\retail_sales_data.csv' DELIMITER ',' CSV HEADER;


-- Inspect data.
----------------------------------------
-- Sample from dataset.
SELECT *
FROM sales_raw
LIMIT 5;

-- Number of records.
SELECT COUNT(*)
FROM sales_raw;
-- RESULT: 541909


-- Check/confirm column names and datatypes.
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'sales_raw';



-- Cleaning
----------------------------------------
-- Copy raw table data to temp table to further investigate and manipulate during cleaning.
-- Trim any extra blank characters from text columns.
DROP TABLE IF EXISTS sales_temp;
CREATE TEMP TABLE sales_temp AS
	SELECT 
		TRIM(invoice_no) AS invoice_no,
		TRIM(stock_code) AS stock_code,
		TRIM(description) AS description,
		quantity, 
		invoice_date,
		unit_price,
		TRIM(customer_id) AS customer_id,
		TRIM(country) AS country
	FROM sales_raw;


-- Check all columns for any NULL values.
SELECT 
	SUM(NUM_NULLS(invoice_no)) AS invoice_no_null,
	SUM(NUM_NULLS(stock_code)) AS stock_code_null,
	SUM(NUM_NULLS(description)) AS description_null,
	SUM(NUM_NULLS(quantity)) AS quantity_null,
	SUM(NUM_NULLS(invoice_date)) AS invoice_date_null,
	SUM(NUM_NULLS(unit_price)) AS unit_price_null,
	SUM(NUM_NULLS(customer_id)) AS customer_id_null,
	SUM(NUM_NULLS(country)) AS country_null
FROM sales_temp;
-- RESULT: description and customer_id have NULL values


-- Check text columns for blank values.
SELECT
	SUM(CASE WHEN invoice_no = '' 
		THEN 1 ELSE 0 END) AS invoice_no_blank,
	SUM(CASE WHEN stock_code = '' 
		THEN 1 ELSE 0 END) AS stock_code_blank,
	SUM(CASE WHEN description = '' 
		THEN 1 ELSE 0 END) AS description_blank,
	SUM(CASE WHEN customer_id = ''
		THEN 1 ELSE 0 END) AS customer_id_blank,
	SUM(CASE WHEN country = '' 
		THEN 1 ELSE 0 END) AS country_blank
FROM sales_temp;
-- RESULT: no blank values found


-- Check numeric columns for values 0 or less.
SELECT 
	SUM(CASE WHEN quantity <= 0
	   THEN 1 ELSE 0 END) AS qty_value_check,
	SUM(CASE WHEN unit_price <= 0
	   THEN 1 ELSE 0 END) AS price_value_check
FROM sales_temp;
-- RESULT: quantity and unit_price contain values 0 or less


-- Check that date range in date column makes sense.
SELECT 
	MIN(invoice_date) AS first_trans,
	MAX(invoice_date) AS last_trans
FROM sales_temp;
-- RESULT: date range 12/1/2010 to 12/9/2011


-- Investigate numerical column values.
-- Quantity values <= 0.
SELECT COUNT(*)
FROM sales_temp
WHERE quantity <= 0;
-- RESULT: 10624


-- quantity values <= 0 are assumed to be returns and are outside the scope of this analysis.
-- Remove records from dataset w/ quantity < 0.
DELETE FROM sales_temp
WHERE quantity <= 0;


-- unit_price values < 0.
SELECT COUNT(*)
FROM sales_temp
WHERE unit_price <= 0;
-- RESULT: 2517

-- unit_price values <= 0 are outside the scope of this analysis.
-- Remove records from dataset w/ unit_price <= 0.
DELETE FROM sales_temp
WHERE unit_price <= 0;


-- Investigate description and customer_id NULL values.
-- description
SELECT *
FROM sales_temp
WHERE description IS NULL;
-- No results.


-- customer_id
SELECT COUNT(*)
FROM sales_temp
WHERE customer_id IS NULL;
-- RESULT: 132220


-- We'll assume the NULL customer_id values are customers that have not registered as members.
-- Replace NULL customer_id values w/ GUEST.
UPDATE sales_temp
SET customer_id = 'GUEST'
WHERE customer_id IS NULL;


-- Record count after filtering out unneccessary values.
SELECT COUNT(*)
FROM sales_temp;
-- RESULT: 530104


-- Check that remaining invoice_no values are all the same length.
SELECT LENGTH(invoice_no), COUNT(*)
FROM sales_temp
GROUP BY LENGTH(invoice_no);
-- RESULT: value character lengths 6 and 7 found


-- Investigate different invoice_no character lengths.
SELECT *
FROM sales_temp
WHERE LENGTH(invoice_no) = 7;
-- RESULT: single record returned is bookkeeping adjustment


-- Remove record from data.
DELETE FROM sales_temp
WHERE LENGTH(invoice_no) = 7;


-- Check length of stock_code values.
SELECT 
	LENGTH(stock_code),
	COUNT(stock_code)
FROM sales_temp
GROUP BY LENGTH(stock_code)
ORDER BY LENGTH(stock_code) DESC;
-- RESULT: majority of values are length 5 & 6


-- Investigate different stock code lengths.
-- stock_code length >= 7
SELECT 
	stock_code,
	description,
	LENGTH(stock_code),
	COUNT(stock_code)
FROM sales_temp
WHERE LENGTH(stock_code) >= 7
GROUP BY stock_code, description
ORDER BY LENGTH(stock_code) DESC;
-- RESULT: records w/ stock_code lengths > 9 are not stock items


-- Remove records w/ AMAZONFEE and stock_codes w/ length > 9.
DELETE FROM sales_temp
WHERE LENGTH(stock_code) > 9
OR stock_code ILIKE 'AMAZONFEE';


-- stock_code length < 5
SELECT 
	stock_code,
	description,
	LENGTH(stock_code),
	COUNT(stock_code)
FROM sales_temp
WHERE LENGTH(stock_code) < 5
GROUP BY stock_code, description
ORDER BY LENGTH(stock_code) DESC;
-- RESULT: records w/ stock_code lengths < 5 are not stock items


-- Remove records w/ stock_code lengths < 5.
DELETE FROM sales_temp
WHERE LENGTH(stock_code) < 5;


-- Check remaining stock_code lengths. 
SELECT 
	stock_code,
	LENGTH(stock_code)
FROM sales_temp
GROUP BY stock_code
ORDER BY LENGTH(stock_code) DESC;


--- Check for any remaining missing values.
SELECT COUNT(*) AS missing
FROM sales_temp
WHERE quantity <= 0 
	OR	description ISNULL 
	OR	unit_price <= 0 
	OR customer_id ISNULL;
-- RESULT: 0


-- Total records remaining should all be transaction records of stock items.
SELECT COUNT(*)
FROM sales_temp;
-- RESULT: 527758


-- Check number of distinct stock_codes and descriptions (should match).
WITH s_cte AS (
	SELECT stock_code
	FROM sales_temp
	GROUP BY stock_code),
	d_cte AS (
	SELECT description
	FROM sales_temp
	GROUP BY description)

SELECT 
	(SELECT COUNT(stock_code) AS stock_count FROM s_cte),
	(SELECT COUNT(description) AS desc_count FROM d_cte);
-- RESULT: 3907, 4001 (do not match)



-- Investigate why stock_code count and description count do not match.
WITH stock_rn AS (
	-- Return distinct stock_code/description pairs partitioned by distinct stock_codes; assign row numbers.
	SELECT
		stock_code,
		description,
		ROW_NUMBER() OVER(PARTITION BY stock_code ORDER BY description) AS rn
	FROM sales_temp
	GROUP BY stock_code, description
	ORDER BY stock_code, rn
	)
-- List of all stock codes paired to more than one description.
SELECT stock_code, description, rn
FROM stock_rn
WHERE stock_code IN (
	SELECT stock_code
	FROM stock_rn
	WHERE rn > 1)
ORDER BY stock_code;
-- RESULT: Some description values in the data have typos or different format for the same stock_code.
	


-- Update unique stock_code/description pairs using description from first description in ordered results (rn = 1).
-- Create temp table w/ distinct stock_code/description pairs w/ assigned row numbers.
DROP TABLE IF EXISTS stock_rn; 
CREATE TEMP TABLE stock_rn AS (
	SELECT
		stock_code,
		description,
		ROW_NUMBER() OVER(PARTITION BY stock_code ORDER BY description) AS rn
	FROM sales_temp
	GROUP BY stock_code, description
	ORDER BY stock_code, rn
);


-- Replace all non-conforming descriptions with corrected versions.
UPDATE sales_temp 
SET description	= (
	SELECT stock_desc.description
	FROM (
		-- Subquery table w/ distinct stock_code/descriptions
		SELECT stock_code, description
		FROM stock_rn
		WHERE rn = 1 
		ORDER BY stock_code) stock_desc 
	WHERE stock_desc.stock_code = sales_temp.stock_code
);
	

-- Check updated number of distinct stock_codes and descriptions (should match if one description to one stock_code).
WITH s_cte AS (
	SELECT stock_code
	FROM sales_temp
	GROUP BY stock_code),
	d_cte AS (
	SELECT description
	FROM sales_temp
	GROUP BY description)

SELECT 
	(SELECT COUNT(stock_code) AS stock_count FROM s_cte),
	(SELECT COUNT(description) AS desc_count FROM d_cte);
-- RESULT: 3907, 3775 (not a match)


-- Investigate why there are more unique stock codes than descriptions.
WITH desc_rn AS (
	-- Return each distinct description/stock_code pair partitioned by distinct descriptions and row numbers assigned.
	SELECT 
		description, 
		stock_code,
		ROW_NUMBER() OVER(PARTITION BY description ORDER BY stock_code) AS rn
	FROM sales_temp 
	GROUP BY stock_code, description
	ORDER BY description
	)
-- List of all descriptions paired to more than one stock_code.
SELECT description, stock_code, rn
FROM desc_rn
WHERE description IN (
	SELECT description
	FROM desc_rn
	WHERE rn > 1)
ORDER BY description;
-- RESULT: 
-- The resulting list of description/stock_code pairs reveals 2 issues:
---- 1. Some repeating descriptions have stock_codes that match but have different character capitalization.
---- 2. Some repeating descriptions have stock_codes that are in series: serialized odd digits.


-- Repeat query and check for any other similiarities/differences in the non-conforming subset.
WITH desc_rn AS (
	-- Return each distinct description/stock_code pair partitioned by distinct descriptions and row numbers assigned.
	SELECT 
		description, 
		stock_code,
		ROW_NUMBER() OVER(PARTITION BY description ORDER BY stock_code) AS rn
	FROM sales_temp 
	GROUP BY stock_code, description
	ORDER BY description
	)
-- List of all descriptions paired to more than one stock_code and character length of stock_code.
SELECT 
	description, 
	stock_code, 
	LENGTH(stock_code) AS code_len,
	rn
FROM desc_rn
WHERE description IN (
	SELECT description
	FROM desc_rn
	WHERE rn > 1)
ORDER BY description;
-- RESULTS: Stock_code character lengths are 5, 6, 7. Character lengths > 5 have letter suffixes.



-- Issue 1.
-- All 6 and 7 character length stock_codes end in letters. Some of these stock_codes match except for the capitalization of the letter suffix.
-- Standardize the capitalization of the letters used in stock_codes.
UPDATE sales_temp
SET stock_code = 		
	-- Replace letter code suffixes w/ uppercase; 5 character codes are unchanged.
	(CASE
		WHEN LENGTH(stock_code) > 6
		THEN LEFT(stock_code, 5) || UPPER(RIGHT(stock_code, 2))	
		WHEN LENGTH(stock_code) > 5
		THEN LEFT(stock_code, 5) || UPPER(RIGHT(stock_code, 1))
		ELSE stock_code
	 END);
	

-- Issue 2.
-- Descriptions have stock_codes that are proximal (w/in a few digits), share a code w/ a letter suffix added, or both.
-- These distinctions are presumed to be updated versions of the products and the descriptions need to be changed to reflect this.
-- Create temp table to reference for description update.
DROP TABLE IF EXISTS fixed_desc; 
CREATE TEMP TABLE fixed_desc AS (
	WITH desc_rn AS (
		-- Return each distinct description/stock_code pair partitioned by distinct descriptions and row numbers assigned.
		SELECT 
			description, 
			stock_code,
			ROW_NUMBER() OVER(PARTITION BY description ORDER BY stock_code) AS rn
		FROM sales_temp 
		GROUP BY stock_code, description
		ORDER BY description
		)
	-- List of all description/stock_code pairs that repeat descriptions.
	-- Alter descriptions based on assigned rn to reflect version number in description.
	SELECT 
		description || ' v' || rn AS new_desc,
		stock_code
	FROM desc_rn
	WHERE description IN (
		SELECT description
		FROM desc_rn
		WHERE rn > 1)
	ORDER BY description);



-- Update sales_temp w/ values from fixed_desc temp table.
BEGIN;
UPDATE sales_temp
SET description = 
	new_desc 
	FROM fixed_desc 
	WHERE fixed_desc.stock_code = sales_temp.stock_code;

-- ROLLBACK;
COMMIT;


-- Check updated number of distinct stock_codes and descriptions (should match if one description to one stock_code).
WITH s_cte AS (
	SELECT stock_code
	FROM sales_temp
	GROUP BY stock_code),
	d_cte AS (
	SELECT description
	FROM sales_temp
	GROUP BY description)

SELECT 
	(SELECT COUNT(stock_code) AS stock_count FROM s_cte),
	(SELECT COUNT(description) AS desc_count FROM d_cte);
-- RESULT: 3798, 3800; do not match


-- Investigate why there are fewer stock_codes than descriptions.
-- Create temp table to use in update.
DROP TABLE IF EXISTS sub_temp;
CREATE TEMP TABLE sub_temp AS (
	WITH desc_rn AS (
		-- Return each distinct description/stock_code pair partitioned by distinct stock_codes and row numbers assigned.
		SELECT 
			description, 
			stock_code,
			ROW_NUMBER() OVER(PARTITION BY stock_code ORDER BY description) AS rn
		FROM sales_temp 
		GROUP BY stock_code, description
		ORDER BY stock_code, rn
		),
		-- Return all rows w/ duplicate stock_codes.
		repeated_cte AS (
		SELECT * 
		FROM desc_rn
		WHERE stock_code IN (
			SELECT stock_code
			FROM desc_rn
			WHERE rn > 1)
		ORDER BY stock_code, rn
		)
	-- Return table w/ stock codes and description w/ rn=1 for substitution.
	SELECT stock_code, description
	FROM repeated_cte
	WHERE rn = 1
);

-- Update sales_temp w/ values from sub_temp temp table.
BEGIN;
UPDATE sales_temp
SET description =
	sub_temp.description
	FROM sub_temp
	WHERE sub_temp.stock_code = sales_temp.stock_code;
-- ROLLBACK;
COMMIT;


-- Check updated number of distinct stock_codes and descriptions (should match if one description to one stock_code).
WITH s_cte AS (
	SELECT stock_code
	FROM sales_temp
	GROUP BY stock_code),
	d_cte AS (
	SELECT description
	FROM sales_temp
	GROUP BY description)
SELECT 
	(SELECT COUNT(stock_code) AS stock_count FROM s_cte),
	(SELECT COUNT(description) AS desc_count FROM d_cte);
-- RESULTS: match


-- Copy temp table data to clean data table.
CREATE TABLE sales_clean2 AS (
	SELECT *
	FROM sales_temp);


-- Table summary.
SELECT 
	COUNT(*) AS num_records,
	COUNT(DISTINCT invoice_no) AS num_invoices,
	COUNT(DISTINCT stock_code) AS unique_stock_codes,
	SUM(quantity) AS total_items_sold,
	ROUND(SUM(unit_price * quantity),2) AS total_sales,
	COUNT(DISTINCT customer_id) AS num_customers,
	COUNT(DISTINCT country) AS num_countries
FROM sales_clean2;


-- Table sample.
SELECT *
FROM sales_clean2
LIMIT 5;



-- Copy final clean table to csv file.
\copy sales_clean2 TO 'C:\Users\steve\tech_portfolio\portfolio_projects\retail_sales\retail_sales_data_clean2.csv' DELIMITER ',' CSV HEADER;




