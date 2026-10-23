# Project Walkthrough: Brazilian E-Commerce Analysis in MySQL 8.0

## 1. Relational Schema & Table Ingestion Workflow
```text
Raw CSV Datasets (9 Files, ~1.5M rows)
  ├── product_category_name_translation.csv (71 rows + 2 pre-seeded = 73)
  ├── olist_customers_dataset.csv (99,441 rows)
  ├── olist_sellers_dataset.csv (3,095 rows)
  ├── olist_geolocation_dataset.csv (1,000,163 rows)
  ├── olist_products_dataset.csv (32,951 rows)
  ├── olist_orders_dataset.csv (99,441 rows)
  ├── olist_order_items_dataset.csv (112,650 rows)
  ├── olist_order_payments_dataset.csv (103,886 rows)
  └── olist_order_reviews_dataset.csv (99,224 rows)
        │
        ▼ [MySQL 8.0 DDL & Ingestion Engine]
  ┌────────────────────────────────────────────────────────┐
  │ 1. Schema Generation with Strict Foreign Keys          │
  │ 2. Pre-seeding Missing Category Translations           │
  │ 3. Multi-line Escaped CSV Ingestion (ESCAPED BY '')    │
  │ 4. Universal Windows/Unix Line Ending Trimming         │
  └────────────────────────────────────────────────────────┘
        │
        ▼ [Post-Import Verification]
  5-Phase Data Quality Suite (Row counts, PK uniqueness, 0 orphans, temporal consistency)
        │
        ▼ [Analytical Query Execution]
  15 Business Analytical Queries (CTEs, DENSE_RANK, LAG, Cumulative GMV)
```

---

## 2. Deep Dive: Overcoming Common SQL & Ingestion Pitfalls

### Pitfall 1: Join Fan-Out / Multiplication
- **Problem**: Joining `order_items` (112,650 rows) directly to `order_payments` (103,886 rows) on `order_id` causes orders with multiple items and multiple payment methods (e.g. 2 items, 2 vouchers) to create 4 rows instead of 2.
- **Solution**: Always pre-aggregate within CTEs at the granular primary key level (`order_id`) before joining:
  ```sql
  WITH items_per_order AS (
      SELECT order_id, SUM(price) AS total_item_price FROM order_items GROUP BY order_id
  ),
  payments_per_order AS (
      SELECT order_id, SUM(payment_value) AS total_payment FROM order_payments GROUP BY order_id
  )
  SELECT i.order_id, i.total_item_price, p.total_payment
  FROM items_per_order i
  JOIN payments_per_order p ON i.order_id = p.order_id;
  ```

### Pitfall 2: Foreign Key Constraint Failure on Product Categories (Error 1452)
- **Problem**: The raw Olist `olist_products_dataset.csv` contains 73 unique product categories, but the official `product_category_name_translation.csv` only contains 71 categories (missing `pc_gamer` and `portateis_cozinha_e_preparadores_de_alimentos`). If a strict foreign key `fk_products_category` is defined, loading products throws:
  `ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails`.
- **Solution**: The ingestion script explicitly pre-seeds the two missing categories into `product_category_name_translation` via `INSERT IGNORE` before loading products, preserving 100% referential integrity without dropping foreign keys.

### Pitfall 3: Corrupted Multi-Line Reviews & Backslash Escapes
- **Problem**: Portuguese customer feedback messages often end with emoticons like `:\`. Under default MySQL `LOAD DATA` settings (`ESCAPED BY '\\'`), a trailing backslash escapes the closing quotation mark (`\"`), causing MySQL to treat the subsequent CSV row as part of the review text. This leads to dropped records and parsing truncation warnings.
- **Solution**: Specify `FIELDS ESCAPED BY ''` in the `LOAD DATA` statement so backslashes are treated as literal characters and double quotes strictly delimit fields per RFC 4180.

### Pitfall 4: Windows Carriage Returns (`\r`) in String Comparisons
- **Problem**: When CSV files with CRLF line endings are loaded using `LINES TERMINATED BY '\n'`, the final column in each row retains an invisible `\r` (ASCII 13) character. Filtering by `WHERE state = 'SP'` fails because `'SP\r' != 'SP'`.
- **Solution**: Always map the final column to a session variable and apply `TRIM(TRAILING '\r' FROM @col)`.

### Pitfall 5: Reserved Keyword Collision (`YEAR_MONTH`)
- In MySQL, `YEAR_MONTH` is a reserved interval keyword (e.g., used in `DATE_ADD(col, INTERVAL 1 YEAR_MONTH)`). Using `year_month` as an unquoted column alias raises syntax error 1064. Always use aliases such as `sales_month`, `order_year_month`, or escape with backticks (`` `year_month` ``).

---

## 3. Hands-On Practice Exercises

- **Exercise 1: Seller Revenue Quartiles**: Write a query using `NTILE(4)` to segment sellers into 4 revenue quartiles based on their lifetime delivered revenue.
- **Exercise 2: Freight-to-Weight Elasticity**: Write a query that computes average freight value and average freight-to-price ratio bucketed into 500g product weight increments (`product_weight_g`).
- **Exercise 3: Delivery Delay Geography**: Identify the top 5 states where customers experience the longest delivery delays relative to the estimated delivery promise (`DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date)`).
- **Exercise 4: Spatial Distance (Geolocation Extension)**: Using the newly added `geolocation` table, calculate the average geographic centroid (`AVG(geolocation_lat)`, `AVG(geolocation_lng)`) for customer zip prefixes vs. seller zip prefixes, and apply the Haversine formula to compute average shipping distance in kilometers.
