-- =============================================================================
-- Brazilian E-Commerce: Core Business Analytical Queries
-- Environment: MySQL 8.0
-- Dataset: Olist E-Commerce Database
-- Topics: Joins, Aggregation, Subqueries, CTEs, Window Functions (LAG, SUM OVER, DENSE_RANK)
-- =============================================================================

USE olist_ecommerce;

-- -----------------------------------------------------------------------------
-- QUERY 1: Financial Reconciliation — Item Revenue vs. Freight vs. Payments
-- Business Question: What is the grand total of product sales, logistics freight,
-- and recorded customer payments?
-- Technical Note: Aggregates items and payments separately before joining to prevent
-- join fan-out multiplication.
-- -----------------------------------------------------------------------------
WITH item_totals AS (
    SELECT 
        ROUND(SUM(price), 2) AS total_item_revenue,
        ROUND(SUM(freight_value), 2) AS total_freight_value,
        ROUND(SUM(price + freight_value), 2) AS total_charged_to_items
    FROM order_items
),
payment_totals AS (
    SELECT 
        ROUND(SUM(payment_value), 2) AS total_payment_value,
        COUNT(DISTINCT order_id) AS orders_with_payments
    FROM order_payments
)
SELECT 
    i.total_item_revenue,
    i.total_freight_value,
    i.total_charged_to_items,
    p.total_payment_value,
    ROUND(p.total_payment_value - i.total_charged_to_items, 2) AS financial_reconciliation_variance
FROM item_totals i
CROSS JOIN payment_totals p;


-- -----------------------------------------------------------------------------
-- QUERY 2: Monthly Sales Trajectory & Key Performance Indicators
-- Business Question: How has revenue, order volume, and Average Order Value (AOV)
-- evolved over time?
-- -----------------------------------------------------------------------------
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_year_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS gross_item_revenue,
    ROUND(SUM(oi.freight_value), 2) AS total_freight,
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS average_order_value_aov
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY order_year_month
ORDER BY order_year_month;


-- -----------------------------------------------------------------------------
-- QUERY 3: Month-over-Month (MoM) Growth Rate using Window Function LAG()
-- Business Question: What is the percentage growth in delivered revenue month-over-month?
-- -----------------------------------------------------------------------------
WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS sales_month,
        ROUND(SUM(oi.price), 2) AS monthly_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY sales_month
)
SELECT 
    sales_month,
    monthly_revenue,
    LAG(monthly_revenue, 1) OVER (ORDER BY sales_month) AS prior_month_revenue,
    ROUND(
        (monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY sales_month)) / 
        LAG(monthly_revenue, 1) OVER (ORDER BY sales_month) * 100, 
        2
    ) AS mom_growth_pct
FROM monthly_revenue;


-- -----------------------------------------------------------------------------
-- QUERY 4: Cumulative Running Revenue using SUM() OVER (ORDER BY ...)
-- Business Question: How has cumulative marketplace gross merchandise value (GMV)
-- accumulated since inception?
-- -----------------------------------------------------------------------------
WITH monthly_summary AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS sales_month,
        ROUND(SUM(oi.price), 2) AS monthly_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY sales_month
)
SELECT 
    sales_month,
    monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (ORDER BY sales_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS running_cumulative_revenue
FROM monthly_summary;


-- -----------------------------------------------------------------------------
-- QUERY 5: Top 10 Product Categories by Revenue (with English Translations)
-- Business Question: Which categories represent our highest revenue drivers?
-- -----------------------------------------------------------------------------
SELECT 
    COALESCE(t.product_category_name_english, p.product_category_name, 'Uncategorized') AS category_english,
    COUNT(oi.order_item_id) AS items_sold,
    COUNT(DISTINCT oi.order_id) AS unique_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS avg_item_price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
GROUP BY category_english
ORDER BY total_revenue DESC
LIMIT 10;


-- -----------------------------------------------------------------------------
-- QUERY 6: Customer Geographic Distribution & Freight Burden
-- Business Question: How do orders, spending, and freight ratios vary across Brazilian states?
-- -----------------------------------------------------------------------------
SELECT 
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS total_item_spend,
    ROUND(SUM(oi.freight_value), 2) AS total_freight_paid,
    ROUND(SUM(oi.freight_value) / SUM(oi.price) * 100, 2) AS freight_to_price_ratio_pct
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_item_spend DESC;


-- -----------------------------------------------------------------------------
-- QUERY 7: On-Time vs. Late Delivery Performance Analysis
-- Business Question: What proportion of delivered orders arrived on or before
-- the estimated delivery promise, and what is the average delay for late orders?
-- -----------------------------------------------------------------------------
SELECT 
    CASE 
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On-Time'
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'Delayed'
        ELSE 'Missing Delivery Date'
    END AS fulfillment_status,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders WHERE order_status = 'delivered'), 2) AS pct_of_delivered_orders,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) AS avg_delivery_lead_time_days
FROM orders
WHERE order_status = 'delivered'
GROUP BY fulfillment_status;


-- -----------------------------------------------------------------------------
-- QUERY 8: Impact of Delivery Delays on Customer Review Scores
-- Business Question: Does shipping delay directly degrade review ratings?
-- -----------------------------------------------------------------------------
SELECT 
    CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'Delivered On-Time'
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Delivered Late'
        ELSE 'Status Unknown'
    END AS delivery_outcome,
    COUNT(r.review_id) AS total_reviews,
    ROUND(AVG(r.review_score), 2) AS average_review_score,
    ROUND(SUM(CASE WHEN r.review_score = 5 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_5_star_reviews,
    ROUND(SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_1_star_reviews
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY delivery_outcome;


-- -----------------------------------------------------------------------------
-- QUERY 9: Customer Payment Tender Breakdown & Installment Usage
-- Business Question: What payment methods are most popular and what is the installment behavior?
-- -----------------------------------------------------------------------------
SELECT 
    payment_type,
    COUNT(*) AS total_payment_records,
    ROUND(SUM(payment_value), 2) AS total_payment_amount,
    ROUND(SUM(payment_value) * 100.0 / (SELECT SUM(payment_value) FROM order_payments), 2) AS pct_share_of_payments,
    ROUND(AVG(payment_installments), 1) AS avg_installments,
    MAX(payment_installments) AS max_installments
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment_amount DESC;


-- -----------------------------------------------------------------------------
-- QUERY 10: Customer Repeat Purchase Behavior
-- Business Question: What percentage of individual buyers place repeat orders?
-- Technical Note: customer_unique_id identifies distinct natural persons.
-- -----------------------------------------------------------------------------
WITH customer_order_counts AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS lifetime_orders,
        ROUND(SUM(oi.price), 2) AS lifetime_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    CASE 
        WHEN lifetime_orders = 1 THEN '1 Order (One-Time Customer)'
        WHEN lifetime_orders = 2 THEN '2 Orders (Repeat Customer)'
        ELSE '3+ Orders (Loyal Customer)'
    END AS customer_cohort,
    COUNT(*) AS unique_customers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_order_counts), 2) AS pct_of_customer_base,
    ROUND(SUM(lifetime_spend), 2) AS total_spend_contributed
FROM customer_order_counts
GROUP BY customer_cohort
ORDER BY unique_customers DESC;


-- -----------------------------------------------------------------------------
-- QUERY 11: Top 10 Sellers by Revenue & Fulfillment Speed
-- Business Question: Who are our highest-grossing marketplace sellers and how fast do they dispatch?
-- -----------------------------------------------------------------------------
SELECT 
    s.seller_id,
    s.seller_state,
    COUNT(oi.order_item_id) AS total_items_sold,
    ROUND(SUM(oi.price), 2) AS total_seller_revenue,
    ROUND(AVG(DATEDIFF(oi.shipping_limit_date, o.order_purchase_timestamp)), 1) AS avg_shipping_lead_window_days
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id, s.seller_state
ORDER BY total_seller_revenue DESC
LIMIT 10;


-- -----------------------------------------------------------------------------
-- QUERY 12: Seller Ranking by State using DENSE_RANK()
-- Business Question: Rank the top 3 sellers within each top state by revenue.
-- -----------------------------------------------------------------------------
WITH ranked_sellers AS (
    SELECT 
        s.seller_state,
        s.seller_id,
        ROUND(SUM(oi.price), 2) AS seller_revenue,
        DENSE_RANK() OVER (PARTITION BY s.seller_state ORDER BY SUM(oi.price) DESC) AS state_rank
    FROM sellers s
    JOIN order_items oi ON s.seller_id = oi.seller_id
    GROUP BY s.seller_state, s.seller_id
)
SELECT 
    seller_state,
    state_rank,
    seller_id,
    seller_revenue
FROM ranked_sellers
WHERE state_rank <= 3 AND seller_state IN ('SP', 'RJ', 'MG', 'PR')
ORDER BY seller_state, state_rank;


-- -----------------------------------------------------------------------------
-- QUERY 13: Multi-Item Basket Analysis
-- Business Question: How many orders contain multiple items, and what revenue do they generate?
-- -----------------------------------------------------------------------------
WITH order_item_counts AS (
    SELECT 
        order_id,
        COUNT(order_item_id) AS total_items,
        SUM(price) AS order_price
    FROM order_items
    GROUP BY order_id
)
SELECT 
    CASE 
        WHEN total_items = 1 THEN '1 Item'
        WHEN total_items = 2 THEN '2 Items'
        WHEN total_items BETWEEN 3 AND 5 THEN '3 - 5 Items'
        ELSE '6+ Items'
    END AS basket_size_category,
    COUNT(order_id) AS order_count,
    ROUND(COUNT(order_id) * 100.0 / (SELECT COUNT(*) FROM order_item_counts), 2) AS pct_of_orders,
    ROUND(SUM(order_price), 2) AS total_revenue
FROM order_item_counts
GROUP BY basket_size_category
ORDER BY order_count DESC;


-- -----------------------------------------------------------------------------
-- QUERY 14: Order Processing Time by Hour of Day
-- Business Question: At what hours do orders take longest to get approved?
-- -----------------------------------------------------------------------------
SELECT 
    HOUR(order_purchase_timestamp) AS purchase_hour,
    COUNT(*) AS total_orders_placed,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, order_purchase_timestamp, order_approved_at)), 1) AS avg_approval_minutes
FROM orders
WHERE order_approved_at IS NOT NULL
GROUP BY purchase_hour
ORDER BY purchase_hour;


-- -----------------------------------------------------------------------------
-- QUERY 15: Review Response Latency Analysis
-- Business Question: How quickly are customer reviews answered by merchant support teams?
-- -----------------------------------------------------------------------------
SELECT 
    review_score,
    COUNT(*) AS review_count,
    ROUND(AVG(DATEDIFF(review_answer_timestamp, review_creation_date)), 1) AS avg_response_delay_days,
    ROUND(SUM(CASE WHEN review_comment_message IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_with_written_comment
FROM order_reviews
GROUP BY review_score
ORDER BY review_score DESC;
