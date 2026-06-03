-- ============================================================
-- Analysis 2: Delivery Performance & Review Score Correlation
--
-- Questions answered:
--   1. What is the overall on-time delivery rate?
--   2. How many days on average does delivery take vs. estimate?
--   3. Which customer states have the worst delivery performance?
--   4. Is there a correlation between late deliveries and low review scores?
--   5. How does avg review score differ between on-time and late orders?
--
-- Skills demonstrated: CTEs, CASE WHEN, DATEDIFF, GROUP BY,
-- aggregate functions, multi-table joins, ROW_NUMBER window function
-- ============================================================



-- ============================================================
-- CTE 1: delivery_base
--
-- This is the foundation of the analysis. It pulls one row per
-- delivered order with three key pieces of information:
--   - How many days early/late it arrived (delivery_delay_days)
--   - Whether it was on time or late (delivery_status)
--   - The customer's review score for that order (review_score)
--
-- We JOIN to customers to get the state (for geographic breakdown).
-- We LEFT JOIN to reviews so orders with no review still appear
-- (as NULL), rather than being dropped from the analysis.
--
-- A negative delivery_delay_days means the order arrived EARLY.
-- A positive value means it arrived LATE.
-- ============================================================

WITH delivery_base AS (
    SELECT
        o.order_id,
        c.customer_state,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,

        -- DATEDIFF(date_a, date_b) = date_a minus date_b in days.
        -- Positive = arrived after estimated date (late).
        -- Negative = arrived before estimated date (early).
        DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) AS delivery_delay_days,

        -- CASE WHEN works like an if/else statement.
        -- If delivered on or before the estimated date, mark as On Time.
        -- Otherwise mark as Late.
        CASE
            WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'On Time'
            ELSE 'Late'
        END AS delivery_status,

        -- review_score comes from the deduplicated reviews subquery below.
        -- Will be NULL if the order has no review.
        r.review_score

    FROM orders o

    -- JOIN to customers to pull customer_state for geographic analysis.
    -- This is an INNER JOIN, so orders with no matching customer are excluded.
    JOIN customers c ON o.customer_id = c.customer_id

    -- LEFT JOIN to the deduplicated reviews subquery.
    -- LEFT JOIN means: keep all orders even if they have no review.
    -- The subquery ensures exactly one review row per order.
    LEFT JOIN (
        SELECT order_id, review_score
        FROM (
            -- ROW_NUMBER() assigns a sequential number to each row
            -- within a group (PARTITION BY order_id).
            -- ORDER BY review_creation_date DESC puts the most recent
            -- review first (row 1). review_id DESC breaks ties.
            SELECT order_id, review_score,
                ROW_NUMBER() OVER (
                    PARTITION BY order_id
                    ORDER BY review_creation_date DESC, review_id DESC
                ) AS rn
            FROM order_reviews
        ) ranked
        -- Only keep row number 1 = the most recent review per order.
        -- This guarantees exactly one review row per order_id,
        -- preventing row duplication when we join.
        WHERE rn = 1
    ) r ON o.order_id = r.order_id

    -- Filter to delivered orders only with valid date fields.
    -- Cancelled, shipped, or processing orders are excluded.
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
),

-- ============================================================
-- CTE 2: overall_summary
--
-- Aggregates delivery_base into a single summary row.
-- Uses conditional aggregation (SUM + CASE WHEN) to count
-- on-time and late orders without needing multiple subqueries.
--
-- Conditional aggregation pattern:
--   SUM(CASE WHEN condition THEN 1 ELSE 0 END)
--   = count of rows where condition is true
-- ============================================================

overall_summary AS (
    SELECT
        -- Total number of delivered orders in the dataset
        COUNT(*) AS total_delivered_orders,

        -- Count of on-time orders using conditional aggregation
        SUM(CASE WHEN delivery_status = 'On Time' THEN 1 ELSE 0 END) AS on_time_orders,

        -- Count of late orders
        SUM(CASE WHEN delivery_status = 'Late' THEN 1 ELSE 0 END) AS late_orders,

        -- On-time rate as a percentage, rounded to 2 decimal places
        ROUND(
            SUM(CASE WHEN delivery_status = 'On Time' THEN 1 ELSE 0 END)
            / COUNT(*) * 100.0, 2
        ) AS on_time_rate_pct,

        -- Average delay across all orders (negative = typically early)
        ROUND(AVG(delivery_delay_days), 2) AS avg_delay_days,

        -- Average review score for on-time orders only.
        -- AVG ignores NULLs, so CASE WHEN returning NULL for late
        -- orders effectively filters them out of this average.
        ROUND(AVG(CASE WHEN delivery_status = 'On Time' THEN review_score END), 2) AS avg_review_on_time,

        -- Average review score for late orders only (same pattern)
        ROUND(AVG(CASE WHEN delivery_status = 'Late' THEN review_score END), 2) AS avg_review_late

    FROM delivery_base
),

-- ============================================================
-- CTE 3: state_performance
--
-- Breaks down delivery performance by Brazilian state.
-- Uses RANK() window function to rank states by late rate,
-- so the worst-performing states appear at the top of the output.
--
-- RANK() vs ROW_NUMBER(): RANK() allows ties (two states with
-- the same late rate get the same rank number). ROW_NUMBER()
-- would force a unique number even for tied values.
-- ============================================================

state_performance AS (
    SELECT
        customer_state,

        -- Total orders shipped to this state
        COUNT(*) AS total_orders,

        -- Number of on-time orders to this state
        SUM(CASE WHEN delivery_status = 'On Time' THEN 1 ELSE 0 END) AS on_time_orders,

        -- Number of late orders to this state
        SUM(CASE WHEN delivery_status = 'Late' THEN 1 ELSE 0 END) AS late_orders,

        -- Late rate as a percentage for this state
        ROUND(
            SUM(CASE WHEN delivery_status = 'Late' THEN 1 ELSE 0 END)
            / COUNT(*) * 100.0, 2
        ) AS late_rate_pct,

        -- Average delivery delay for this state (negative = typically early)
        ROUND(AVG(delivery_delay_days), 2) AS avg_delay_days,

        -- Average review score across all orders to this state
        ROUND(AVG(review_score), 2) AS avg_review_score,

        -- RANK() orders states from highest late rate (rank 1) to lowest.
        -- States with the worst delivery performance appear first.
        RANK() OVER (
            ORDER BY
                SUM(CASE WHEN delivery_status = 'Late' THEN 1 ELSE 0 END)
                / COUNT(*) DESC
        ) AS late_rate_rank

    FROM delivery_base
    GROUP BY customer_state
)

-- ============================================================
-- Final Output: Overall summary + state breakdown in one result
--
-- We use UNION ALL to combine two SELECT statements into one result set.
-- UNION ALL (vs UNION) keeps all rows including duplicates and is faster.
--
-- The state rows are padded with NULLs to match the column count
-- of the overall summary row (9 columns total).
--
-- ORDER BY puts the OVERALL SUMMARY row first (value 0),
-- then sorts state rows alphabetically after it (value 1).
-- ============================================================

SELECT
    'OVERALL SUMMARY'                                      AS report_section,
    total_delivered_orders,
    on_time_orders,
    late_orders,
    on_time_rate_pct,
    avg_delay_days,
    avg_review_on_time,
    avg_review_late,
    ROUND(avg_review_on_time - avg_review_late, 2)        AS review_score_gap
FROM overall_summary

UNION ALL

SELECT
    CONCAT('STATE: ', customer_state)                     AS report_section,
    total_orders,
    on_time_orders,
    late_orders,
    late_rate_pct,
    avg_delay_days,
    avg_review_score,
    NULL,           -- avg_review_on_time not broken out at state level
    NULL            -- review_score_gap not broken out at state level
FROM state_performance
ORDER BY
    CASE WHEN report_section = 'OVERALL SUMMARY' THEN 0 ELSE 1 END,
    report_section;
