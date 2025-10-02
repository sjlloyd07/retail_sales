# Cleaning and Preparation

The data was imported to a new table created in a PostgreSQL databse for inspection, cleaning, and preparation for analysis.

The table was defined with column names and datatypes corresponding to the `.csv` header names.

### Table Summary
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

# EDA, Cleaning, Processing

### 🔷 Create `TEMP TABLE` to manipulate during cleaning and processing.

```sql
CREATE TEMP TABLE sales_temp AS
	SELECT *
	FROM sales_raw;

```

<br>

---

### 🔷 Check for missing values in dataset (all columns).

<details>
    <summary><strong>🔎 View Query</strong></summary><br>

```sql
SELECT COUNT(*) AS null_values
FROM sales_temp
WHERE invoice_no ISNULL OR stock_code ISNULL OR description ISNULL
	OR quantity ISNULL OR invoice_date ISNULL OR unit_price ISNULL
	OR customer_id ISNULL OR country ISNULL OR quantity <= 0 OR
	unit_price <= 0;

```
</details>

| null_values |
|-------------|
| 144025	  |


<br>

---

### 🔷 Dive deeper into missing values - column by column.

- All columns were checked individually for `NULL` values using `COUNT(*)` and `WHERE` 
*`column_name`* `ISNULL`.  
- `quantity` and `unit_price` were checked for negative or 0 values.

<br>

**Two columns contained `NULL` values: `description` and `customer_id`.**

-	**`description`**

	<details>
		<summary><strong>🔎 View Query</strong></summary><br>
		
	```sql

	SELECT COUNT(*) AS null_values
	FROM sales_temp
	WHERE description ISNULL;

	```
	</details>

	| null_values |
	|-------------|
	| 1454		  |

	<br>

-	**`customer_id`**

	<details>
		<summary><strong>🔎 View Query</strong></summary><br>
		
	```sql

	SELECT COUNT(*) AS null_values
	FROM sales_temp
	WHERE customer_id ISNULL;

	```
	</details>

	| null_values |
	|-------------|
	| 135080	  |

	<br>

**`quantity` and `unit_price` both contained negative or 0 values.**

-	**`quantity`**

	<details>
		<summary><strong>🔎 View Query</strong></summary><br>
		
	```sql

	SELECT COUNT(*) AS less_0
	FROM sales_temp
	WHERE quantity <= 0

	```
	</details>

	| less_0 |
	|--------|
	| 10624  |

	<br>

-	**`unit_price`**

	<details>
		<summary><strong>🔎 View Query</strong></summary><br>
		
	```sql

	SELECT COUNT(unit_price)
	FROM sales_raw
	WHERE unit_price <= 0;

	```
	</details>

	| less_0 |
	|--------|
	| 2517  |


<br>
<br>

---

### ❗ Issue: 
* **There are columns with missing data: NULL and 0 values.**
### 🛠️ Action: 
* **Remove rows with NULL or 0 values from the dataset.**
  
*A real world dataset would require further investigation, but we will proceed w/ removing the rows w/ missing data for the purpose of this analysis.*

```sql

DELETE FROM sales_temp2 
	WHERE quantity <= 0 
		OR	description ISNULL 
		OR	unit_price <= 0 
		OR customer_id ISNULL;

```
<br>

- **Confirm successful update.**

	<details>
		<summary><strong>🔎 View Query</strong></summary><br>
	
	```sql
	
	SELECT COUNT(*) AS missing
	FROM sales_temp
		WHERE quantity <= 0 
			OR	description ISNULL 
			OR	unit_price <= 0 
			OR customer_id ISNULL
	
	```
	</details>
	
	**Results Summary:**
	
	| missing |
	|---------|
	| 0       |


<br>

---

### 🔷 Number of Records

<details>
    <summary><strong>🔎 View Query</strong></summary><br>
	
```sql

SELECT COUNT(*)
FROM sales_temp;

```
</details>

| count |
|-----------|
| 397884	|

<br>

---

### 🔷 Unique Invoices

<details>
    <summary><strong>🔎 View Query</strong></summary><br>
	
```sql

SELECT COUNT(DISTINCT invoice_no)
FROM sales_temp;

```
</details>

| count |
|-------------|
| 18532	|

<br>

---

### 🔷 Does every stock_code match a description?

<details>
    <summary><strong>🔎 View Query</strong></summary><br>
	
```sql

SELECT 
	COUNT(DISTINCT stock_code) AS stock_codes, 
	COUNT(DISTINCT description) AS descriptions
FROM sales_temp;

```
</details>

| stock_codes | descriptions |
|---------------|--------------|
| 3665          | 3877         |

<br>

---

### ❗ Issue: 
* **There are fewer stock_code values than description values in the dataset.**

### 🛠️ Action: 
* **Investigate why there are more descriptions than stock codes.**

	- Create `TEMP TABLE` with all stock codes and descriptions.
	- Partition by stock codes to assign row numbers to every `stock_code`-`description` pair.
	- Query this table to return results of only stock codes that have more than one description.
	
		<details>
			<summary><strong>🔎 View Query</strong></summary><br>
			
		```sql
	
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
	
		```
		</details>
			 
		**Results Summary:**
	
		| stock_code | description                         |
		|------------|-------------------------------------|
		| 16156L     | WRAP CAROUSEL                       |
		| 16156L     | WRAP, CAROUSEL                      |
		| 17107D     | FLOWER FAIRY 5 DRAWER LINERS        |
		| 17107D     | FLOWER FAIRY 5 SUMMER DRAW LINERS   |
		| 17107D     | FLOWER FAIRY,5 SUMMER B'DRAW LINERS |

<br> 

---

### ❗ Issue: 
* **Some stock codes were input with multiple descriptions.**

### 🛠️ Action: 
* **Find and eliminate redundant descriptions for stock codes.**
	
	- Create `TEMP TABLE` that only contains stock codes with first returned description. Use this in an `UPDATE` statement to replace redundant descriptions.
	
		<details>
			<summary><strong>🔎 View Query</strong></summary><br>
	
		```sql
	
		DROP TABLE IF EXISTS unique_stock_desc; 
		CREATE TEMP TABLE unique_stock_desc AS 
			SELECT stock_code, description
			FROM stock_rows
			WHERE rn = 1 
			ORDER BY stock_code
	
		UPDATE sales_temp 
		SET description	= (
			SELECT usd.description
			FROM unique_stock_desc usd
			WHERE usd.stock_code = sales_temp.stock_code)
	
		```
		</details>
	
		Check stock codes and descriptions after update.
		
		<details>
			<summary><strong>🔎 View Query</strong></summary><br>
	
		```sql
	
		SELECT 
			COUNT(DISTINCT stock_code) AS stock_count, 
			COUNT(DISTINCT description) AS desc_count
		FROM sales_temp
	
		```
		</details>
	
		| stock_count | desc_count |
		|-------------|------------|
		| 3665        | 3647       |

<br>

---

### ❗ Issue: 
* **After description update, there are more unique stock codes than descriptions.**

### 🛠️ Action: 
* **Investigate why some descriptions would have multiple stock codes.**
	
	- Return stock codes that have multiple descriptions.
	
		<details>
			<summary><strong>🔎 View Query</strong></summary><br>
	
		```sql
	
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
			WHERE rn > 1)
		;
	
		```
		</details>
		
		**Results Summary:**
		
		| description                  | stock_code | rn |
		|------------------------------|------------|----|
		| COLOURING PENCILS BROWN TUBE | 10133      | 1  |
		| COLOURING PENCILS BROWN TUBE | 10135      | 2  |
		| COLUMBIAN CANDLE RECTANGLE   | 72131      | 1  |
		| COLUMBIAN CANDLE RECTANGLE   | 72133      | 2  |
		| COLUMBIAN CANDLE ROUND       | 72128      | 1  |

<br>

---

### ❗ Issue: 
* **Some stock codes refer to multiple identical descriptions due to possible update errors.**
* **Assume newer product version stock codes were updated in series, but descriptions were not.**

### 🛠️ Action: 
* **Update descriptions to match stock codes by adding version numbers to duplicates.**

	- Update duplicate descriptions w/ appropriate version numbers.
	 
		 <details>
			<summary><strong>🔎 View Query</strong></summary><br>
	
		```sql
	
		UPDATE desc_rows
		SET description = CONCAT(description, ' v', rn);
	
		```
		</details>
		
		 <details>
			<summary><strong>🔎 View Results Summary</strong></summary><br>
	
		```sql
	
		SELECT *
		FROM desc_rows
		LIMIT 5;
	
		```
		
		| description                     | stock_code | rn |
		|---------------------------------|------------|----|
		| COLOURING PENCILS BROWN TUBE v1 | 10133      | 1  |
		| COLOURING PENCILS BROWN TUBE v2 | 10135      | 2  |
		| COLUMBIAN CANDLE RECTANGLE v1   | 72131      | 1  |
		| COLUMBIAN CANDLE RECTANGLE v2   | 72133      | 2  |
		| COLUMBIAN CANDLE ROUND v1       | 72128      | 1  |
		
		</details>		
	
	<br>
	  
	- Update unique stock code description table w/ updated descriptions.
	
		<details>
			<summary><strong>🔎 View Query</strong></summary><br>
	
		```sql
	
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
	
		```
		</details>
	
	<br>
		
	- Update `sales_temp` table w/ new descriptions.
		
		```sql
				
		UPDATE sales_temp
		SET description = 
			(SELECT usd.description
			 FROM unique_stock_desc usd
			 WHERE sales_temp.stock_code = usd.stock_code);
	
		```
	
	 <br>
		
	- Check that update was successful.
	
		<details>
			<summary><strong>🔎 View Query</strong></summary><br>
	
		```sql
	
		SELECT 
			COUNT(DISTINCT stock_code) AS stock_count, 
			COUNT(DISTINCT description) AS desc_count
		FROM sales_temp
	
		```
		</details>
	
		| stock_count | desc_count |
		|-------------|------------|
		| 3665        | 3665       |
		
<br>

---

### ❗ Issue: 
* **Unneccessary non-product stock items are in the dataset and should be removed for this analysis.**

### 🛠️ Action: 
* **Update dataset to remove non-product stock items.**

	<details>
		<summary><strong>🔎 View Query</strong></summary><br>
	
	```sql
	
	DELETE FROM sales_temp
	WHERE stock_code IN ('M', 'C2', 'POST', 'DOT', 'PADS', 'BANK CHARGES');
	
	```
	</details>

- Check that update was successful.

	<details>
		<summary><strong>🔎 View Query</strong></summary><br>

	```sql

	SELECT COUNT(DISTINCT stock_code)
	FROM sales_temp;

	```
	</details>

	| count  | 
	|--------|
	| 3659   |
	
	
<br>
<br>

---

## 🔷 Cleaned Column Summaries

<details>
	<summary><strong>🔎 View Query</strong></summary><br>

```sql

SELECT 
	COUNT(*) AS records,
	COUNT(DISTINCT invoice_no) AS invoices,
	COUNT(DISTINCT stock_code) AS unique_stock_items,
	SUM(quantity) AS total_items_sold,
	ROUND(SUM(unit_price * quantity),2) AS total_sales,
	COUNT(DISTINCT customer_id) AS customers,
	COUNT(DISTINCT country) AS countries
FROM sales_temp

```
</details>

**Results:**

| records | invoices | unique_stock_items | total_items_sold | total_sales | customers | countries |
|---------|----------|--------------------|------------------|-------------|-----------|-----------|
| 396337  | 18402    | 3659               | 5157354          | 7301987.41   | 4334      | 37        |

<br>

For better comparison and understanding of the monthly sales data, analysis will proceed only on the monthly records that are complete in this dataset.  

The following will be filtered out of the final data before proceeding with analysis and visualization:
* incomplete December 2010 records
* incomplete December 2011 records

<br>

**Final Cleaned Column Summaries**

<details>
	<summary><strong>🔎 View Query</strong></summary><br>

```sql

SELECT 
	COUNT(*) AS records,
	COUNT(DISTINCT invoice_no) AS invoices,
	COUNT(DISTINCT stock_code) AS unique_stock_items,
	SUM(quantity) AS total_items_sold,
	ROUND(SUM(unit_price * quantity),2) AS total_sales,
	COUNT(DISTINCT customer_id) AS customers,
	COUNT(DISTINCT country) AS countries
FROM sales_clean
WHERE date_part('month', invoice_date) != 12
	AND date_part('year', invoice_date) != 2010

```
</details>

**Results:**

| records | invoices | unique_stock_items | total_items_sold | total_sales | customers | countries |
|---------|----------|--------------------|------------------|-------------|-----------|-----------|
| 353039  | 16232    | 3581               | 4559048          | 6369539.52  | 4168      | 36        |


<br>



---
<br>


