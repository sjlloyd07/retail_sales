# Cleaning and Preparation

The data was copied to a new PostgreSQL database table for inspection, cleaning, and preparation for analysis.

The table was defined with column names and datatypes corresponding to the `.csv` header names.

### Table Sample
<details>
    <summary><strong>🔎 View Query</strong></summary><br>

```sql
SELECT *
FROM sales_raw
LIMIT 5;
```
</details>
	
| invoice_no | stock_code | description                         | quantity | invoice_date        | unit_price | customer_id | country        |
|------------|------------|-------------------------------------|----------|---------------------|------------|-------------|----------------|
| 536365     | 85123A     | WHITE HANGING HEART T-LIGHT HOLDER  | 6        | 2010-12-01 08:26:00 | 2.55       | 17850       | United Kingdom |
| 536365     | 71053      | WHITE METAL LANTERN                 | 6        | 2010-12-01 08:26:00 | 3.39       | 17850       | United Kingdom |
| 536365     | 84406B     | CREAM CUPID HEARTS COAT HANGER      | 8        | 2010-12-01 08:26:00 | 2.75       | 17850       | United Kingdom |
| 536365     | 84029G     | KNITTED UNION FLAG HOT WATER BOTTLE | 6        | 2010-12-01 08:26:00 | 3.39       | 17850       | United Kingdom |
| 536365     | 84029E     | RED WOOLLY HOTTIE WHITE HEART.      | 6        | 2010-12-01 08:26:00 | 3.39       | 17850       | United Kingdom |

<br>

### Column Information

<details>
    <summary><strong>🔎 View Query</strong></summary><br>

```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'sales_raw';
```
</details>

| column_name  | data_type                   |
|--------------|-----------------------------|
| unit_price   | numeric                     |
| quantity     | integer                     |
| invoice_date | timestamp without time zone |
| customer_id  | character varying           |
| invoice_no   | character varying           |
| country      | character varying           |
| stock_code   | character varying           |
| description  | character varying           |

<br>



----------------------------------------------------------------------------

# Cleaning and Preparation

### 🔷 Create `TEMP TABLE` to manipulate during cleaning and processing.

```sql
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

```

<br>

---

### 🔷 Check for missing values in the dataset (all columns).

<details>
    <summary><strong>🔎 View Query</strong></summary><br>

```sql
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

```
</details>

| invoice_no_null | stock_code_null | description_null | quantity_null | invoice_date_null | unit_price_null | customer_id_null | country_null |
|-----------------|-----------------|------------------|---------------|-------------------|-----------------|------------------|--------------|
| 0               | 0               | 1454             | 0             | 0                 | 0               | 135080           | 0            |

<br>

---

### 🔷 Check text columns for blank values.

<details>
    <summary><strong>🔎 View Query</strong></summary><br>

```sql
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

```
</details>

| invoice_no_blank | stock_code_blank | description_blank | customer_id_blank | country_blank |
|------------------|------------------|-------------------|-------------------|---------------|
| 0                | 0                | 0                 | 0                 | 0             |


<br>

---

### 🔷 Check numeric columns for values 0 or less.

<details>
    <summary><strong>🔎 View Query</strong></summary><br>

```sql
SELECT 
	SUM(CASE WHEN quantity <= 0
	   THEN 1 ELSE 0 END) AS qty_value_check,
	SUM(CASE WHEN unit_price <= 0
	   THEN 1 ELSE 0 END) AS price_value_check
FROM sales_temp;

```
</details>

| qty_value_check | price_value_check |
|-----------------|-------------------|
| 10624           | 2517              |


<br>

---

### 🔷 Check that date range in date column makes sense.

<details>
    <summary><strong>🔎 View Query</strong></summary><br>

```sql
SELECT 
	MIN(invoice_date) AS first_trans,
	MAX(invoice_date) AS last_trans
FROM sales_temp;

```
</details>

| first_trans | last_trans |
|-----------------|-------------------|
| 2010-12-01 08:26:00           | 2011-12-09 12:50:00              |


<br>
<br>

### ❗ Issue: 
* **There are quantitative columns with negative or 0 values.**
### 🛠️ Action: 
* **Investigate rows with negative or 0 values from the quantitative columns.**

**`quantity` values <= 0.**

-	**`quantity`**

	<details>
		<summary><strong>🔎 View Query</strong></summary><br>
		
	```sql

	SELECT COUNT(*)
	FROM sales_temp
	WHERE quantity <= 0;

	```
	</details>

	| count |
	|--------|
	| 10624  |

	<br>

	`quantity` values < 0 are assumed to be returns and are outside the scope of this analysis.
	Remove records from dataset where `quantity` < 0.
	
	<details>
		<summary><strong>🔎 View Query</strong></summary><br>
		
	```sql

	DELETE FROM sales_temp
	WHERE quantity <= 0;

	```
	</details>

	<br>


**`unit_price` values <= 0.**

-	**`unit_price`**

	<details>
		<summary><strong>🔎 View Query</strong></summary><br>
		
	```sql

	SELECT COUNT(*)
	FROM sales_temp
	WHERE unit_price <= 0;

	```
	</details>

	| count |
	|-------|
	| 2517  |

	<br>

	`unit_price` values <= 0 are outside the scope of this analysis.
	Remove records from dataset where unit_price <= 0.

	<details>
		<summary><strong>🔎 View Query</strong></summary><br>
		
	```sql

	DELETE FROM sales_temp
	WHERE unit_price <= 0;

	```
	</details>

<br>
<br>

### ❗ Issue: 
* **The `description` and `customer_id` columns have missing data (NULL values).**
### 🛠️ Action: 
* **Investigate rows with NULL values in `description` and `customer_id` columns.**
  
-	**`description`**

	```sql

	SELECT *
	FROM sales_temp
	WHERE description IS NULL;

	```

	** NO RESULTS **

	<br>

-	**`customer_id`**

	<details>
		<summary><strong>🔎 View Query</strong></summary><br>
	
	```sql
	
	SELECT COUNT(*)
	FROM sales_temp
	WHERE customer_id IS NULL;
	
	```
	</details>
	
	**Results Summary:**
	
	| count  |
	|--------|
	| 132220 |

	<br>

	We'll assume the NULL `customer_id` values are customers that have not registered as members.
	Replace NULL `customer_id` values w/ GUEST.

	<details>
		<summary><strong>🔎 View Query</strong></summary><br>
	
	```sql
	
	UPDATE sales_temp
	SET customer_id = 'GUEST'
	WHERE customer_id IS NULL;
	
	```
	</details>

<br>

---

### 🔷 Number of records remaining after removing values that are outside the scope of the analysis.

<details>
    <summary><strong>🔎 View Query</strong></summary><br>
	
```sql

SELECT COUNT(*)
FROM sales_temp;

```
</details>

| count |
|-----------|
| 530104	|

<br>

---

### 🔷 Check that remaining `invoice_no` values are all the same length.

<details>
    <summary><strong>🔎 View Query</strong></summary><br>
	
```sql

SELECT 
	LENGTH(invoice_no)
	COUNT(*)
FROM sales_temp
GROUP BY LENGTH(invoice_no);

```
</details>

| length | count  |
|--------|--------|
| 6      | 530103 |
| 7      | 1      |


<br>

### ❗ Issue: 
* **There is one `invoice_no` value different from the rest.**
### 🛠️ Action: 
* **Investigate non-conforming value.**


<details>
    <summary><strong>🔎 View Query</strong></summary><br>
	
```sql

SELECT *
FROM sales_temp
WHERE LENGTH(invoice_no) = 7;

```
</details>

| invoice_no | stock_code | description     | quantity | invoice_date        | unit_price | customer_id | country        |
|------------|------------|-----------------|----------|---------------------|------------|-------------|----------------|
| A563185    | B          | Adjust bad debt | 1        | 2011-08-12 14:50:00 | 11062.06   |             | United Kingdom |

<br>

Single record is debt adjustment that can be removed from the dataset.

<details>
    <summary><strong>🔎 View Query</strong></summary><br>
	
```sql

DELETE FROM sales_temp
WHERE LENGTH(invoice_no) = 7;

```
</details>

<br>

---

### 🔷 Check that `stock_code` value character lengths are conforming.

<details>
    <summary><strong>🔎 View Query</strong></summary><br>
	
```sql

SELECT 
	LENGTH(stock_code),
	COUNT(stock_code)
FROM sales_temp
GROUP BY LENGTH(stock_code)
ORDER BY LENGTH(stock_code) DESC;

```
</details>

| length | count  |
|--------|--------|
| 12     | 43     |
| 9      | 15     |
| 8      | 20     |
| 7      | 383    |
| 6      | 50246  |
| 5      | 477096 |
| 4      | 1129   |
| 3      | 706    |
| 2      | 141    |
| 1      | 324    |

<br>

### ❗ Issue: 
* **`stock_code` lengths range from 1 to 12.**
### 🛠️ Action: 
* **Investigate different value lengths.**
  
-	**`stock_code` length >= 7**

	<details>
		<summary><strong>🔎 View Query</strong></summary><br>
		
	```sql

		SELECT 
			stock_code,
			description,
			LENGTH(stock_code),
			COUNT(stock_code)
		FROM sales_temp
		WHERE LENGTH(stock_code) >= 7
		GROUP BY stock_code, description
		ORDER BY LENGTH(stock_code) DESC;

	```
	</details>

	| stock_code   | description                        | length | count |
	|--------------|------------------------------------|--------|-------|
	| gift_0001_20 | Dotcomgiftshop Gift Voucher £20.00 | 12     | 9     |
	| gift_0001_30 | Dotcomgiftshop Gift Voucher £30.00 | 12     | 7     |
	| gift_0001_50 | Dotcomgiftshop Gift Voucher £50.00 | 12     | 4     |
	| gift_0001_40 | Dotcomgiftshop Gift Voucher £40.00 | 12     | 3     |
	| BANK CHARGES | Bank Charges                       | 12     | 12    |
	| gift_0001_10 | Dotcomgiftshop Gift Voucher £10.00 | 12     | 8     |
	| AMAZONFEE    | AMAZON FEE                         | 9      | 2     |
	| DCGSSGIRL    | GIRLS PARTY BAG                    | 9      | 13    |
	| DCGS0004     | HAYNES CAMPER SHOULDER BAG         | 8      | 1     |
	| DCGSSBOY     | BOYS PARTY BAG                     | 8      | 11    |
	| DCGS0076     | SUNJAR LED NIGHT NIGHT LIGHT       | 8      | 2     |
	| DCGS0070     | CAMOUFLAGE DOG COLLAR              | 8      | 1     |
	| DCGS0069     | OOH LA LA DOGS COLLAR              | 8      | 1     |
	| DCGS0003     | BOXED GLASS ASHTRAY                | 8      | 4     |
	| 15056bl      | EDWARDIAN PARASOL BLACK            | 7      | 62    |
	| 15056BL      | EDWARDIAN PARASOL BLACK            | 7      | 321   |

	<br>
	
	Records w/ stock_code lengths > 9 are not stock items.
	Remove records w/ AMAZONFEE and stock_codes w/ length > 9.

	```sql

	DELETE FROM sales_temp
	WHERE LENGTH(stock_code) > 9
	OR stock_code ILIKE 'AMAZONFEE';

	```

	<br>
	
-	**`stock_code` length < 5**

	<details>
		<summary><strong>🔎 View Query</strong></summary><br>
		
	```sql

	SELECT 
		stock_code,
		description,
		LENGTH(stock_code),
		COUNT(stock_code)
	FROM sales_temp
	WHERE LENGTH(stock_code) < 5
	GROUP BY stock_code, description
	ORDER BY LENGTH(stock_code) DESC;

	```
	</details>

	| stock_code | description                | length | count |
	|------------|----------------------------|--------|-------|
	| POST       | POSTAGE                    | 4      | 1126  |
	| PADS       | PADS TO MATCH ALL CUSHIONS | 4      | 3     |
	| DOT        | DOTCOM POSTAGE             | 3      | 706   |
	| C2         | CARRIAGE                   | 2      | 141   |
	| m          | Manual                     | 1      | 1     |
	| S          | SAMPLES                    | 1      | 2     |
	| M          | Manual                     | 1      | 321   |

	<br>
	
	Records w/ stock_code lengths < 5 are not stock items.
	Remove records w/ stock_codes lengths < 5.

	```sql

	DELETE FROM sales_temp
	WHERE LENGTH(stock_code) < 5;

	```

	<br>

-	**Check remaining `stock_code` lengths.**

	<details>
		<summary><strong>🔎 View Query</strong></summary><br>
		
	```sql

	SELECT 
		stock_code,
		LENGTH(stock_code)
	FROM sales_temp
	GROUP BY stock_code
	ORDER BY LENGTH(stock_code) DESC;

	```
	</details>

	| stock_code | length |
	|------------|--------|
	| DCGSSGIRL  | 9      |
	| DCGS0003   | 8      |
	| DCGSSBOY   | 8      |
	| DCGS0004   | 8      |
	| DCGS0076   | 8      |
	...
	
	<br>
	
	Remaining `stock_code` values all appear to be stock items.

	<br>
	
---

### 🔷 Check for any remaining missing values.

<details>
    <summary><strong>🔎 View Query</strong></summary><br>
	
```sql

SELECT COUNT(*) AS missing
FROM sales_temp
WHERE quantity <= 0 
	OR	description ISNULL 
	OR	unit_price <= 0 
	OR customer_id ISNULL;

```
</details>

| missing |
|---------|
| 0       |


<br>

---

### 🔷 Check number of distinct stock_codes and descriptions (should match).

<details>
    <summary><strong>🔎 View Query</strong></summary><br>
	
```sql

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

```
</details>

| stock_count | desc_count |
|-------------|------------|
| 3907        | 4001       |

<br>

### ❗ Issue: 
* **Each `stock_code` should be paired to exactly one `description`.**
### 🛠️ Action: 
* **Investigate why `stock_code` count and `description` count do not match.**
  
-	**`stock_code`**

	<details>
		<summary><strong>🔎 View Query</strong></summary><br>
		
	```sql

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

	```
	</details>

	| stock_code | description                         | rn |
	|------------|-------------------------------------|----|
	| 16156L     | WRAP CAROUSEL                       | 1  |
	| 16156L     | WRAP, CAROUSEL                      | 2  |
	| 17107D     | FLOWER FAIRY 5 DRAWER LINERS        | 1  |
	| 17107D     | FLOWER FAIRY 5 SUMMER DRAW LINERS   | 2  |
	| 17107D     | FLOWER FAIRY,5 SUMMER B'DRAW LINERS | 3  |
	...

	<br>

-	**Update unique stock_code/description pairs using value from first description in ordered results (rn = 1).**

	<details>
		<summary><strong>🔎 View CREATE TEMP TABLE Statement</strong></summary><br>
		
	```sql

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

	```
	</details>

	<br>

-	**Replace all non-conforming descriptions with corrected versions.**

	<details>
		<summary><strong>🔎 View UPDATE Statement </strong></summary><br>
		
	```sql

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

	```
	</details>

	<br>

-	**Check updated number of distinct `stock_code` and `description` values (should match if one description to one stock_code).**

	<details>
		<summary><strong>🔎 View Query </strong></summary><br>
		
	```sql

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

	```
	</details>

	| stock_count | desc_count |
	|-------------|------------|
	| 3907        | 3775       |

	<br>

-	**Investigate why there are more unique stock codes than descriptions.**

	<details>
		<summary><strong>🔎 View Query </strong></summary><br>
		
	```sql

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

	```
	</details>

	| description                       | stock_code | rn |
	|-----------------------------------|------------|----|
	| 3 GARDENIA MORRIS BOXED CANDLES   | 85034a     | 1  |
	| 3 GARDENIA MORRIS BOXED CANDLES   | 85034A     | 2  |
	| 3 WHITE CHOC MORRIS BOXED CANDLES | 85034b     | 1  |
	| 3 WHITE CHOC MORRIS BOXED CANDLES | 85034B     | 2  |
	| 3D DOG PICTURE PLAYING CARDS      | 84558a     | 1  |
	...


	The resulting list of description/stock_code pairs reveals 2 issues:
    - Some repeating descriptions have stock_codes that match but have different character capitalization.
	- Some repeating descriptions have stock_codes that are in series: serialized odd digits.

	<br>

-	**Repeat query and check for any other similiarities/differences in the non-conforming subset.**

	<details>
		<summary><strong>🔎 View Query </strong></summary><br>
		
	```sql
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

	```
	</details>

	| description                       | stock_code | code_len | rn |
	|-----------------------------------|------------|----------|----|
	| 3 GARDENIA MORRIS BOXED CANDLES   | 85034a     | 6        | 1  |
	| 3 GARDENIA MORRIS BOXED CANDLES   | 85034A     | 6        | 2  |
	| 3 WHITE CHOC MORRIS BOXED CANDLES | 85034b     | 6        | 1  |
	| 3 WHITE CHOC MORRIS BOXED CANDLES | 85034B     | 6        | 2  |
	| 3D DOG PICTURE PLAYING CARDS      | 84558a     | 6        | 1  |
	...

	<br>

-	❗ **Issue:**
    - **All 6 and 7 character length stock_codes end in letters. Some of these stock_codes match except for the capitalization of the letter suffix.**
-	🛠️ **Action:**
    - **Standardize the capitalization of the letters used in stock_codes.**

	<details>
		<summary><strong>🔎 View UPDATE Statement </strong></summary><br>
		
	```sql
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

	```
	</details>

	<br>

-	❗ **Issue:**
    - **Descriptions have stock_codes that are proximal (w/in a few digits), share a code w/ a letter suffix added, or both. These distinctions are presumed to be updated versions of the products and the descriptions need to be changed to reflect this.**
-	🛠️ **Action:**
    - **Create temp table to reference for description update.**

	<details>
		<summary><strong>🔎 View UPDATE Statement </strong></summary><br>
		
	```sql
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

	```
	</details>

	<br>
	
    - **Update sales_temp w/ values from fixed_desc temp table.**

	<details>
		<summary><strong>🔎 View UPDATE Statement </strong></summary><br>
		
	```sql
	BEGIN;
	UPDATE sales_temp
	SET description = 
		new_desc 
		FROM fixed_desc 
		WHERE fixed_desc.stock_code = sales_temp.stock_code;

	-- ROLLBACK;
	COMMIT;

	```
	</details>

	<br>
	
-	**Check updated number of distinct stock_codes and descriptions (should match if one description to one stock_code).**

	<details>
		<summary><strong>🔎 View UPDATE Statement </strong></summary><br>
		
	```sql
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

	```
	</details>

	| stock_count | desc_count |
	|-------------|------------|
	| 3798        | 3800       |

	<br>
	
-	**Investigate why there are fewer stock_codes than descriptions.**
-	**Create temp table to use in update.**

	<details>
		<summary><strong>🔎 View UPDATE Statement </strong></summary><br>
		
	```sql
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

	```
	</details>

	<br>
	
-	**Update sales_temp w/ values from sub_temp temp table.**

	<details>
		<summary><strong>🔎 View UPDATE Statement </strong></summary><br>
		
	```sql
	BEGIN;
	UPDATE sales_temp
	SET description =
		sub_temp.description
		FROM sub_temp
		WHERE sub_temp.stock_code = sales_temp.stock_code;
	-- ROLLBACK;
	COMMIT;
	```
	</details>


-	**Check updated number of distinct stock_codes and descriptions (should match if one description to one stock_code).**

	<details>
		<summary><strong>🔎 View UPDATE Statement </strong></summary><br>
		
	```sql
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
	```
	</details>

	<br>

---

### 🔷 Copy temp table data to clean data table.

<details>
	<summary><strong>🔎 View CREATE TABLE Statement </strong></summary><br>
	
```sql
CREATE TABLE sales_clean2 AS (
	SELECT *
	FROM sales_temp);
```
</details>

<br>
	
---

### 🔷 Final table summary.

<details>
	<summary><strong>🔎 View Query </strong></summary><br>
	
```sql
SELECT 
	COUNT(*) AS num_records,
	COUNT(DISTINCT invoice_no) AS num_invoices,
	COUNT(DISTINCT stock_code) AS unique_stock_codes,
	SUM(quantity) AS total_items_sold,
	ROUND(SUM(unit_price * quantity),2) AS total_sales,
	COUNT(DISTINCT customer_id) AS num_customers,
	COUNT(DISTINCT country) AS num_countries
FROM sales_clean2;
```
</details>

| num_records | num_invoices | unique_stock_codes | total_items_sold | total_sales | num_customers | num_countries |
|-------------|--------------|--------------------|------------------|-------------|---------------|---------------|
| 527758      | 19773        | 3798               | 5577100          | 10271433.06 | 4335          | 38            |

<br>

---

### 🔷 Final table sample.

<details>
	<summary><strong>🔎 View Query </strong></summary><br>
	
```sql
SELECT *
FROM sales_clean2
LIMIT 5;
```
</details>

| invoice_no | stock_code | description                        | quantity | invoice_date        | unit_price | customer_id | country        |
|------------|------------|------------------------------------|----------|---------------------|------------|-------------|----------------|
| 536365     | 85123A     | CREAM HANGING HEART T-LIGHT HOLDER | 6        | 2010-12-01 08:26:00 | 2.55       | 17850       | United Kingdom |
| 536381     | 21523      | DOORMAT FANCY FONT HOME SWEET HOME | 10       | 2010-12-01 09:41:00 | 6.75       | 15311       | United Kingdom |
| 536382     | 10002      | INFLATABLE POLITICAL GLOBE         | 12       | 2010-12-01 09:45:00 | 0.85       | 16098       | United Kingdom |
| 536390     | 22941      | CHRISTMAS LIGHTS 10 REINDEER       | 2        | 2010-12-01 10:19:00 | 8.5        | 17511       | United Kingdom |
| 536390     | 22960      | JAM MAKING SET WITH JARS           | 12       | 2010-12-01 10:19:00 | 3.75       | 17511       | United Kingdom |










