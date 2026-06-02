-- ============================================================
-- Analysis 1: Monthly Revenue & Order Volume Trends
--
-- Questions answered:
--   1. How has monthly revenue trended over time?
--   2. What is the month-over-month (MoM) revenue change?
--   3. How many orders were placed each month?
--   4. What is the average order value (AOV) per month?
--   5. What is the cumulative (running total) revenue over time?
--
-- Skills demonstrated: CTEs, window functions (LAG, SUM OVER),
-- date functions, aggregation, filtering on order status
-- ============================================================


-- ============================================================
-- CTE 1: monthly_revenue
-- Aggregates revenue, order count, and AOV per month.
-- Only includes delivered orders to reflect actual revenue.
-- Joins order_payments because payment_value is the true
-- revenue figure (includes freight, handles installments).
-- ============================================================

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        COUNT(DISTINCT o.order_id)                       AS total_orders,
        ROUND(SUM(op.payment_value), 2)                  AS total_revenue,
        ROUND(SUM(op.payment_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
    FROM orders o
    JOIN order_payments op ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
),

-- ============================================================
-- CTE 2: revenue_with_changes
-- Adds MoM revenue change and running total using window functions.
--   LAG()    : pulls the previous month's revenue for comparison
--   SUM OVER : calculates cumulative revenue up to each month
-- ============================================================

revenue_with_changes AS (
    SELECT
        order_month,
        total_orders,
        total_revenue,
        avg_order_value,

        -- Previous month revenue using LAG window function
        LAG(total_revenue) OVER (ORDER BY order_month) AS prev_month_revenue,

        -- Month-over-month change in revenue
        ROUND(
            total_revenue - LAG(total_revenue) OVER (ORDER BY order_month),
        2) AS mom_revenue_change,

        -- Month-over-month percentage change
        ROUND(
            (total_revenue - LAG(total_revenue) OVER (ORDER BY order_month))
            / LAG(total_revenue) OVER (ORDER BY order_month) * 100,
        2) AS mom_revenue_pct_change,

        -- Cumulative running total of revenue
        ROUND(
            SUM(total_revenue) OVER (ORDER BY order_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
        2) AS cumulative_revenue

    FROM monthly_revenue
)

-- ============================================================
-- Final output: all months with full trend metrics
-- Ordered chronologically. First month will have NULL for
-- LAG-based columns since there is no prior month.
-- ============================================================

SELECT
    order_month,
    total_orders,
    total_revenue,
    avg_order_value,
    prev_month_revenue,
    mom_revenue_change,
    mom_revenue_pct_change,
    cumulative_revenue
FROM revenue_with_changes
ORDER BY order_month;
