# Brazilian E-Commerce Sales & Logistics Analysis (MySQL 8.0)

A relational database analytics project investigating marketplace commerce, customer ordering patterns, seller fulfillment logistics, payment installment mechanisms, and customer satisfaction using MySQL 8.0.

---

## 1. Project Overview & Business Problem
E-commerce marketplaces depend on coordinated logistics between independent third-party sellers, delivery carriers, and consumers. In vast geographic markets such as Brazil, shipping distances and fulfillment bottlenecks significantly influence operational overhead, freight pricing, and customer churn.

This project designs and deploys a relational schema in **MySQL 8.0** modeling the public Olist Brazilian E-Commerce ecosystem comprising:
- **99,441 orders**
- **112,650 line items**
- **103,886 payment records**
- **99,224 customer reviews**
- **32,951 products**
- **3,095 marketplace sellers**
- **1,000,163 geographic coordinate observations**

Through 15 business queries leveraging joins, common table expressions (CTEs), and window functions, we diagnose revenue growth, logistics bottlenecks, payment tender distributions, and repeat purchasing behaviors.

---

## 2. Business Questions Addressed
1. **Financial Reconciliation**: What is the relationship between gross product item revenue, freight charges, and customer payment value?
2. **Sales Trajectory**: How has monthly marketplace revenue grown, and what was the impact of peak events such as Black Friday?
3. **Category Profitability**: Which product categories lead gross marketplace volume when translated to English?
4. **Logistics & Delivery Promises**: What percentage of orders are delivered late, and what is the difference in lead times between on-time and delayed shipments?
5. **Customer Satisfaction Degradation**: How severely do delivery delays degrade average review scores and increase 1-star ratings?
6. **Payment Structure**: How dominant are installment payments on credit cards in Brazil, and what is the average installment term?
7. **Customer Retention**: What proportion of unique customers return to make a second or third purchase?
8. **Seller Operations**: How do merchants rank within their respective states using window rankings?

---

## 3. Technology Stack & Database Architecture
- **RDBMS**: MySQL Server 8.0
- **Database Client**: MySQL Command Line / MySQL Workbench 8.0
- **SQL Techniques**: Primary & Foreign Key Constraints, B-Tree Indexes, Subqueries, CTEs, Window Functions (`ROW_NUMBER`, `DENSE_RANK`, `SUM() OVER`, `LAG()`), DateTime arithmetic (`DATEDIFF`, `TIMESTAMPDIFF`, `DATE_FORMAT`), Multi-line text parsing, Safe Idempotent Ingestion.

---

## 4. Repository & Folder Structure
```text
olist-ecommerce-sql-analysis/
├── schema/
│   ├── 01_create_schema.sql           # Complete DDL script with constraints and indexes (9 tables)
│   ├── 02_load_data_instructions.sql  # High-performance CSV ingestion & Workbench guide
│   └── ER_DIAGRAM.md                  # Comprehensive Mermaid Entity-Relationship diagram
├── queries/
│   ├── 01_data_quality_checks.sql     # Referential integrity, orphan, and boundary checks
│   └── 02_business_analytical_queries.sql # 15 business queries with CTEs and window functions
├── PROJECT_WALKTHROUGH.md             # Query breakdown, join pitfalls, and exercises
└── README.md                          # Complete documentation and interview guide
```

---

## 5. Dataset Attribution & Entity Model

- **Dataset Source**: [Kaggle Olist Brazilian E-Commerce Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- **Timeframe**: October 2016 to October 2018
- **Primary Currency**: Brazilian Real (BRL / R$)

### Relational Schema Summary
| Table Name | Primary Key | Total Records | Foreign Keys / Relationships |
| :--- | :--- | :--- | :--- |
| `customers` | `customer_id` | 99,441 | Referenced by `orders.customer_id` |
| `orders` | `order_id` | 99,441 | References `customers.customer_id` |
| `order_items` | `(order_id, order_item_id)` | 112,650 | References `orders.order_id`, `products.product_id`, `sellers.seller_id` |
| `order_payments`| `(order_id, payment_sequential)` | 103,886 | References `orders.order_id` |
| `order_reviews` | `(review_id, order_id)` | 99,224 | References `orders.order_id` |
| `products` | `product_id` | 32,951 | References `product_category_name_translation.product_category_name` |
| `sellers` | `seller_id` | 3,095 | Referenced by `order_items.seller_id` |
| `geolocation` | `geolocation_id` (Auto-Inc) | 1,000,163 | Linked to `customers` & `sellers` via `zip_code_prefix` |
| `product_category_name_translation` | `product_category_name` | 73 | Referenced by `products.product_category_name` (71 CSV + 2 pre-seeded) |

*(Refer to [schema/ER_DIAGRAM.md](schema/ER_DIAGRAM.md) for the visual Mermaid diagram).*

---

## 6. Installation & Execution Guide

### Prerequisites
1. **MySQL Server 8.0** installed and running locally.
2. The 9 raw Olist CSV files downloaded from Kaggle into a local folder:
   - `product_category_name_translation.csv`
   - `olist_customers_dataset.csv`
   - `olist_sellers_dataset.csv`
   - `olist_geolocation_dataset.csv`
   - `olist_products_dataset.csv`
   - `olist_orders_dataset.csv`
   - `olist_order_items_dataset.csv`
   - `olist_order_payments_dataset.csv`
   - `olist_order_reviews_dataset.csv`

### Setting Your Local CSV Directory
In `schema/02_load_data_instructions.sql`, update the base directory path in the `LOAD DATA LOCAL INFILE` statements to match your local setup:
```sql
-- Example for Windows:
LOAD DATA LOCAL INFILE 'C:/Users/YourUsername/Downloads/archive (3)/olist_customers_dataset.csv'
-- Example for Linux/macOS:
LOAD DATA LOCAL INFILE '/home/username/data/olist_customers_dataset.csv'
```
> [!IMPORTANT]
> Always use **forward slashes (`/`)** in MySQL file paths on Windows. Backslashes (`\`) are treated as escape characters.

---

### Method A: Execution via MySQL Workbench 8.0 (Recommended GUI)

1. **Enable Local Infile on Connection**:
   - On the MySQL Workbench home screen, right-click your connection $\rightarrow$ **Edit Connection...**
   - Select the **Advanced** tab.
   - In the **Others:** text box at the bottom, enter:
     ```text
     OPT_LOCAL_INFILE=1
     ```
   - Click **Test Connection**, then click **Close** and open the connection.
2. **Execute Schema Creation**:
   - In Workbench, open [`schema/01_create_schema.sql`](schema/01_create_schema.sql) and click the **Execute (Lightning Bolt)** icon.
3. **Execute Data Ingestion**:
   - Open [`schema/02_load_data_instructions.sql`](schema/02_load_data_instructions.sql).
   - Ensure the file path matches your CSV directory.
   - Execute the entire script. All 9 tables will populate.
4. **Execute Post-Import Validation**:
   - Open [`queries/01_data_quality_checks.sql`](queries/01_data_quality_checks.sql) and execute. Verify that all row counts report `MATCH` and duplicate PKs report `0`.
5. **Execute Business Analytics**:
   - Open [`queries/02_business_analytical_queries.sql`](queries/02_business_analytical_queries.sql) and run any or all of the 15 queries.

---

### Method B: Execution via Command Line (PowerShell / Bash)

```bash
# Step 1: Create Database & Relational Schema
mysql -u root -p < schema/01_create_schema.sql

# Step 2: Ingest Raw CSV Datasets with Local Infile Enabled
mysql --local-infile=1 -u root -p olist_ecommerce < schema/02_load_data_instructions.sql

# Step 3: Run Comprehensive Data Quality Checks
mysql -u root -p olist_ecommerce < queries/01_data_quality_checks.sql

# Step 4: Execute Analytical Business Queries
mysql -u root -p olist_ecommerce < queries/02_business_analytical_queries.sql
```

---

## 7. Troubleshooting Common MySQL Ingestion & Workbench Errors

| Error Code / Symptom | Root Cause | Exact Solution |
| :--- | :--- | :--- |
| **Error Code: 3948**<br>`Loading local data is disabled - this must be enabled on both the client and server sides` | Server or client connection has `local_infile` disabled. | 1. Run `SET GLOBAL local_infile = 1;` in MySQL.<br>2. In Workbench, add `OPT_LOCAL_INFILE=1` to Connection $\rightarrow$ Advanced $\rightarrow$ Others.<br>3. In CLI, pass `--local-infile=1`. |
| **Error Code: 2068**<br>`LOAD DATA LOCAL INFILE file request was rejected due to restrictions on client side` | MySQL 8 client library blocks local infile by default. | Connect with `mysql --local-infile=1` or configure Workbench connection as described above. |
| **Error Code: 1175**<br>`You are using safe update mode...` | Workbench prevents `UPDATE` or `DELETE` without a WHERE key clause. | Execute `SET SQL_SAFE_UPDATES = 0;` before running update scripts. |
| **Error Code: 1452**<br>`Cannot add or update a child row: a foreign key constraint fails` | Upstream Olist product dataset has 2 categories (`pc_gamer` and `portateis_cozinha_e_preparadores_de_alimentos`) missing from the official translation CSV. | The load script pre-seeds these two categories into `product_category_name_translation` via `INSERT IGNORE` before loading products, eliminating this error completely. |
| **Malformed Review Comments**<br>`Warning 1262 / Lost rows in reviews` | Portuguese review comments often end with emoticons like `:\`, which escapes the closing quote if default backslash escaping is enabled. | Use `FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY ''` in the load statement. |
| **Trailing `\r` on Windows**<br>`Invalid strings or comparison failures on last column` | Windows line endings (`\r\n`) leave a carriage return on the final column when parsed with `LINES TERMINATED BY '\n'`. | The load script automatically maps the last column to a user variable and applies `TRIM(TRAILING '\r' FROM @var)`. |

---

## 8. Key Findings & Empirical Results

All queries were executed against live MySQL 8.0 with real data:

### 1. Financial Reconciliation & Avoiding Join Multiplications
- **Total Item Revenue**: R$ 13,591,643.70
- **Total Freight Collected**: R$ 2,251,909.54
- **Total Charged on Line Items**: R$ 15,843,553.24
- **Total Payments Recorded**: R$ 16,008,872.12
- *Technical Note*: Directly joining `order_items` with `order_payments` without pre-aggregation produces Cartesian fan-out, inflating apparent revenue to over R$ 65M. Pre-aggregating at the order level resolves this.

### 2. Category Performance
The top 5 grossing merchandise categories:
1. **Health & Beauty**: R$ 1,258,681.34 (9,670 units sold, avg item price R$ 130.16)
2. **Watches & Gifts**: R$ 1,205,005.68 (5,991 units sold, avg item price R$ 201.14)
3. **Bed, Bath & Table**: R$ 1,036,988.68 (11,115 units sold, avg item price R$ 93.30)
4. **Sports & Leisure**: R$ 988,048.97 (8,641 units sold, avg item price R$ 114.34)
5. **Computers & Accessories**: R$ 911,954.32 (7,827 units sold, avg item price R$ 116.51)

### 3. Delivery Performance & Satisfaction Collapse
- **On-Time Fulfillment Rate**: 91.88% (88,644 orders), with an average delivery lead time of **10.8 days**.
- **Late Deliveries**: 8.11% (7,826 orders), taking an average of **31.5 days** to reach the consumer.
- **Review Score Impact**:
  - On-time orders average **4.29 / 5.0** stars (62.4% 5-star, only 6.6% 1-star).
  - Late orders collapse to an average of **2.57 / 5.0** stars (**46.2% 1-star ratings**). Delayed delivery is the single strongest predictor of customer dissatisfaction.

### 4. Geographic Disparity & Freight Burden
- **São Paulo (SP)** generates **R$ 5.07M (37.3% of total revenue)** with a freight-to-price ratio of **13.85%**.
- Remote states (e.g., Roraima [RR], Maranhão [MA]) face freight burdens exceeding **26% to 28%** of item value, depressing conversion rates.

### 5. Payment Methods & Credit Dependence
- **Credit Card**: Accounts for **78.34%** of payments (R$ 12.54M), averaging **3.5 installments** with terms up to 24 months.
- **Boleto Bancário**: Accounts for **17.92%** (R$ 2.87M), serving unbanked or cash-preference consumers.

### 6. Retention & Churn Reality
- **97.00%** of unique customers (90,557 individuals) placed only a single order during the entire 2-year window.
- Only **2.76%** placed a second order, and **0.24%** placed 3 or more orders, highlighting an urgent need for customer lifecycle marketing.

---

## 9. Interview Preparation: 10 Core SQL Questions & Answers

### Q1: What is the difference between `customer_id` and `customer_unique_id` in this dataset?
**Answer**: In the Olist architecture, a new `customer_id` is created for every purchase transaction (acting as a transaction-specific customer token). `customer_unique_id` identifies the actual natural individual. To compute repeat customer rates or lifetime value, queries must group by `customer_unique_id`.

### Q2: What causes join fan-out multiplication, and how did you prevent it in Query 1?
**Answer**: When an order has multiple items ($M$) and multiple payments ($N$), joining `order_items` directly to `order_payments` produces $M \times N$ rows. If an order has 3 items and 2 payments, 6 rows are generated, duplicating price and payment sums. We resolved this by computing item totals and payment totals in separate Common Table Expressions (CTEs) before combining them.

### Q3: When should you use `DENSE_RANK()` versus `RANK()` versus `ROW_NUMBER()`?
**Answer**:
- `ROW_NUMBER()` assigns sequential integers (1, 2, 3...) regardless of ties.
- `RANK()` assigns identical ranks to ties but skips subsequent numbers (e.g., 1, 2, 2, 4).
- `DENSE_RANK()` assigns identical ranks to ties without skipping numbers (e.g., 1, 2, 2, 3). For leaderboard rankings (like top 3 sellers per state), `DENSE_RANK()` ensures no ranks are skipped.

### Q4: How does the window function `LAG()` operate in Month-over-Month (MoM) calculations?
**Answer**: `LAG(column, offset)` accesses the value of `column` from the row preceding the current row within the defined `OVER (ORDER BY ...)` partition. In our MoM query, `LAG(monthly_revenue, 1)` fetched the previous month's revenue to compute percentage delta.

### Q5: Why is `COALESCE()` used when joining product translations?
**Answer**: Some products may have null or missing translations in the lookup table. `COALESCE(t.product_category_name_english, p.product_category_name, 'Uncategorized')` falls back gracefully to the original Portuguese category name, or to 'Uncategorized', preventing null values in reporting.

### Q6: What is the performance impact of indexing `order_purchase_timestamp`?
**Answer**: Date-range filtering and `DATE_FORMAT` aggregations frequently sort or filter by order timestamp. Adding a B-Tree index on `order_purchase_timestamp` allows MySQL to satisfy range queries without performing full table scans over 99k rows.

### Q7: Why did you use `DATEDIFF()` instead of `TIMESTAMPDIFF()` in delivery lead time queries?
**Answer**: `DATEDIFF(date1, date2)` computes the integer count of calendar days between two dates, which aligns with standard consumer delivery expectations. When hourly or minute-level precision is required (such as order approval time), `TIMESTAMPDIFF(MINUTE, ...)` is preferred.

### Q8: What does `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` specify in window functions?
**Answer**: It defines the window frame for aggregation. For cumulative running sums (`SUM() OVER ()`), it specifies that the sum includes all rows from the start of the partition up to and including the current row.

### Q9: What is the difference between `WHERE` and `HAVING` in analytical queries?
**Answer**: `WHERE` filters individual rows before grouping and aggregation occur. `HAVING` filters aggregated group records after `GROUP BY` has evaluated aggregate functions like `COUNT()`, `SUM()`, or `AVG()`.

### Q10: What operational strategy would you recommend based on your query results?
**Answer**: Late deliveries drop 5-star ratings from 62.4% down to 22.2% while doubling 1-star complaints. The marketplace should establish strict fulfillment Service Level Agreements (SLAs) for sellers in SP and RJ shipping to distant states (like BA and PE), or incentivize localized regional fulfillment hubs in the northeast.
