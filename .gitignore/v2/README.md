# Retail Store Sales Analysis

### Overview

The stakeholders of a retail store request the following information about their store's sales data.  
The raw sales data consists of timestamped invoices that contain customer and product details.

### Deliverables
* Total sales.
* Sales distribution over the year.
* Sales distribution by country.
* Top selling items.
* Top performing customer.
* Number of customers and orders.
* Average sales total per order.


<br>

### Tools
- PostgreSQL (PgAdmin4)
- Tableau

<br>

---

## Table of Contents
* ### [Data](https://github.com/sjlloyd07/portfolio_projects/tree/main/retail_sales#Data)
* ### [Cleaning and Prep](https://github.com/sjlloyd07/portfolio_projects/tree/main/retail_sales#Cleaning--Prep)
* ### [Dashboard](https://github.com/sjlloyd07/portfolio_projects/tree/main/retail_sales#Dashboard)


----

<br>

# Data
The dataset consists of mock retail sales data sourced from this kaggle [online retail dataset](https://www.kaggle.com/datasets/siddharththakkar26/online-retail-dataset).  
It was downloaded to local storage in `.xlsx` format, inspected and exported into `.csv` format, and uploaded to a PostgreSQL database for cleaning and preparation.

<br>

----

# [Cleaning / Prep](/retail_sales/cleaning-prep.md)
The PostgreSQL GUI PgAdmin4 was utilized to perform data inspection and cleaning tasks to prepare the data for analysis and visualization in Tableau.

**Summary of the prepared dataset:**

| records | invoices | unique_stock_items | total_items_sold | total_sales | customers | countries |
|---------|----------|--------------------|------------------|-------------|-----------|-----------|
| 353039  | 16232    | 3581               | 4559048          | 6369539.52  | 4168      | 36        |

<br>

----

# Dashboard

<div class='tableauPlaceholder' id='viz1702568107933' style='position: relative'>
  <noscript>
    <a href='https://public.tableau.com/views/retail_sales_report_17022538787610/Dashboard?:language=en-US&:display_count=n&:origin=viz_share_link'>
      <img alt='Dashboard (2) ' src='https:&#47;&#47;public.tableau.com&#47;static&#47;images&#47;re&#47;retail_sales_report_17022538787610&#47;Dashboard2&#47;1_rss.png' style='border: none' />
    </a>

<br>
