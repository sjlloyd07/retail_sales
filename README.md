# SuperDeluxe Supplies Retail Store 
## Sales Report

### Scenario

SuperDeluxe Supplies is an online retail store based in the UK. Management at SuperDeluxe require a basic report displaying an overview of sales starting at the beginning of the year. We are given the raw sales data (a .csv file containing timestamped transactions recorded over several months) on which to perform the analysis in order to present the findings.

After interviewing the stakeholders, it was decided that the sales report should contain the deliverables below and allow the user to filter results by country and customer membership status (member or guest).

* Total YTD revenue.
* Number of invoices and average invoice total.
* Monthly sales revenue.
* Top selling products.
* Sales by country.


<br>

### Tools
- PostgreSQL (PgAdmin4)
- Tableau

<br>

---

## Table of Contents
* ### [Data](https://github.com/sjlloyd07/portfolio_projects/tree/main/retail_sales#Data)
* ### [Cleaning and Prep](https://github.com/sjlloyd07/portfolio_projects/tree/main/retail_sales#Cleaning--Prep)
* ### [Sales Dashboard](https://github.com/sjlloyd07/portfolio_projects/tree/main/retail_sales#Sales-Dashboard)


----

<br>

# Data
The dataset consists of mock retail sales data sourced from this [kaggle dataset](https://www.kaggle.com/datasets/siddharththakkar26/online-retail-dataset). It was downloaded to local storage in `.xlsx` format before being inspected and saved as a `.csv` file. The `.csv` file was then imported to a PostgreSQL database for exploration, cleaning, and preparation.

The dataset contains 8 columns:

| invoice_no | stock_code | description | quantity | invoice_date        | unit_price | customer_id | country        |
|------------|------------|-------------|----------|---------------------|------------|-------------|----------------|

<br>

----

# Cleaning / Prep
The PostgreSQL GUI PgAdmin4 was utilized to perform data inspection and cleaning tasks detailed [here](./cleaning-prep2.md) to prepare the data for analysis and visualization in Tableau.

**Summary of the prepared dataset:**

| num_records | num_invoices | unique_stock_codes | total_items_sold | total_sales | num_customers | num_countries |
|-------------|--------------|--------------------|------------------|-------------|---------------|---------------|
| 527758      | 19773        | 3798               | 5577100          | 10271433.06 | 4335          | 38            |


<br>

----

# Sales Dashboard

<div class='tableauPlaceholder' id='viz1713212791963' style='position: relative'>
  <noscript>
    <a href='https://public.tableau.com/views/retail_sales_v2/SalesDashboard?:language=en-US&:sid=&:display_count=n&:origin=viz_share_link'>
      <img alt='Sales Dashboard ' src='https://public.tableau.com/static/images/re/retail_sales_v2/SalesDashboard/1_rss.png' style='border: none' />
    </a>

<br>

