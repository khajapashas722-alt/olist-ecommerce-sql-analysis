# Brazilian E-Commerce Sales & Logistics Analysis (MySQL 8.0)

A relational database analytics project investigating marketplace commerce, customer ordering patterns, seller fulfillment logistics, payment installment mechanisms, and customer satisfaction using MySQL 8.0.

---

## 1. Project Overview & Business Problem
E-commerce marketplaces depend on coordinated logistics between independent third-party sellers, delivery carriers, and consumers. In vast geographic markets such as Brazil, shipping distances and fulfillment bottlenecks significantly influence operational overhead, freight pricing, and customer churn.

This project designs and deploys a relational schema in **MySQL 8.0** modeling the public Olist Brazilian E-Commerce ecosystem comprising 99,441 orders, 112,650 line items, 103,886 payment records, and 99,224 customer reviews. Through 15 business queries leveraging joins, common table expressions (CTEs), and window functions, we diagnose revenue growth, logistics bottlenecks, payment tender distributions, and repeat purchasing behaviors.

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
- **SQL Techniques**: Primary & Foreign Key Constraints, B-Tree Indexes, Subqueries, CTEs, Window Functions (`ROW_NUMBER`, `DENSE_RANK`, `SUM() OVER`, `LAG()`), DateTime arithmetic (`DATEDIFF`, `TIMESTAMPDIFF`, `DATE_FORMAT`).

---

## 4. Repository & Folder Structure
```text
olist-ecommerce-sql-analysis/
├── schema/
│   ├── 01_create_schema.sql           # Complete DDL script with constraints and indexes
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
| `sellers` | `seller_id` | 3,094 | Referenced by `order_items.seller_id` |
| `product_category_name_translation` | `product_category_name` | 71 | Referenced by `products.product_category_name` |

*(Refer to [schema/ER_DIAGRAM.md](schema/ER_DIAGRAM.md) for the visual Mermaid diagram).*

---

## 6. Installation & Execution Guide

### Prerequisites
- MySQL Server 8.0 installed and running.
- MySQL Command Line client or MySQL Workbench.

### Execution Steps
```bash
# Connect to MySQL Server 8.0
mysql -u root -p

# Step 1: Create Database & Tables
mysql -u root -p < schema/01_create_schema.sql

# Step 2: Ingest Raw CSV Datasets
mysql --local-infile=1 -u root -p olist_ecommerce < schema/02_load_data_instructions.sql

# Step 3: Run Data Quality Checks
mysql -u root -p olist_ecommerce < queries/01_data_quality_checks.sql

# Step 4: Execute Analytical Business Queries
mysql -u root -p olist_ecommerce < queries/02_business_analytical_queries.sql
```

---

## 7. Key Findings & Empirical Results

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

## 8. Interview Preparation: 10 Core SQL Questions & Answers

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
