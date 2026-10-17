# Project Walkthrough: Brazilian E-Commerce Analysis in MySQL 8.0

## 1. Relational Schema & Table Ingestion Workflow
```
CSV Ingestion 
  ──> MySQL Tables with PKs & Foreign Keys 
  ──> Referential Integrity Verification (0 orphans)
  ──> CTE Aggregations (Prevent Cartesian explosion)
  ──> Window Function Analytics (LAG, DENSE_RANK, Running SUM)
  ──> Executive Business Recommendations
```

---

## 2. Deep Dive: Overcoming Common SQL Pitfalls

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

### Pitfall 2: Reserved Keyword Collision (`YEAR_MONTH`)
- In MySQL, `YEAR_MONTH` is a reserved interval keyword (e.g., used in `DATE_ADD(col, INTERVAL 1 YEAR_MONTH)`). Using `year_month` as an unquoted column alias raises syntax error 1064. Always use aliases such as `sales_month`, `order_period`, or escape with backticks (`` `year_month` ``).

---

## 3. Three Improvements You Can Personally Implement

1. **Automated Weekly Refresh Stored Procedure**:
   - Write a MySQL stored procedure `sp_refresh_monthly_kpis()` that calculates monthly GMV, AOV, and on-time fulfillment rates into a pre-aggregated reporting table.
2. **Customer Cohort Retention Matrix via SQL**:
   - Write a dynamic query calculating the month of first order for each `customer_unique_id` and pivoting months 1 through 6 to show retention percentages.
3. **Database Index Tuning & EXPLAIN Analysis**:
   - Run `EXPLAIN ANALYZE` on Query 5 and Query 7. Test composite indexes such as `(order_status, order_delivered_customer_date)` to optimize query execution time.

---

## 4. Hands-On Practice Exercises
- **Exercise 1**: Write a query using `NTILE(4)` to segment sellers into 4 revenue quartiles based on their lifetime sales.
- **Exercise 2**: Write a query that computes the correlation between product weight (`product_weight_g`) and freight cost (`freight_value`).
- **Exercise 3**: Identify the top 5 cities where customers experience the longest delivery delays relative to the estimated delivery promise.
