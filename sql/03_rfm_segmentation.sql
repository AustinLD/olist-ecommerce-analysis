-- ============================================================
-- Analysis 3: RFM Customer Segmentation
--
-- RFM stands for Recency, Frequency, Monetary. It is a proven
-- marketing framework for ranking customers by value.
--
--   Recency   = how recently did they last order?
--               (fewer days since last order = better)
--   Frequency = how many orders have they placed?
--               (more orders = better)
--   Monetary  = how much have they spent in total?
--               (higher spend = better)
--
-- Each customer gets a score of 1-4 on each dimension using
-- NTILE(4), which splits all customers into 4 equal buckets.
-- Score 4 is best. We then combine scores into a segment label.
--
-- Skills demonstrated: CTEs, NTILE window function, DATEDIFF,
-- CASE WHEN, multi-table joins, customer segmentation logic
-- ============================================================



-- ============================================================
-- CTE 1: customer_orders
--
-- Aggregates order history to one row per unique customer.
-- Uses customer_unique_id (not customer_id) because Olist
-- assigns a new customer_id for every order -- the same real
-- person can appear multiple times. customer_unique_id is the
-- true identifier for a returning customer.
--
-- We calculate the three raw RFM inputs here:
--   days_since_last_order  = recency input
--   total_orders           = frequency input
--   total_spend            = monetary input
-- ============================================================

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,

        -- Most recent order date for this customer.
        -- Used to calculate how long ago they last purchased.
        MAX(o.order_purchase_timestamp) AS last_order_date,

        -- Days between their last order and the latest date in the dataset.
        -- We use MAX() over the whole orders table as a proxy for "today"
        -- since this is a historical dataset with no current date.
        -- Lower value = more recent = better recency score.
        DATEDIFF(
            (SELECT MAX(order_purchase_timestamp) FROM orders),
            MAX(o.order_purchase_timestamp)
        ) AS days_since_last_order,

        -- Total number of orders placed by this customer.
        -- Higher = better frequency score.
        COUNT(DISTINCT o.order_id) AS total_orders,

        -- Total amount spent across all orders.
        -- We use order_payments because it captures the true payment
        -- value including installments and freight.
        -- Higher = better monetary score.
        ROUND(SUM(op.payment_value), 2) AS total_spend

    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id

    -- Only include delivered orders to reflect actual completed revenue.
    WHERE o.order_status = 'delivered'

    -- Group by the true customer identifier (not the per-order customer_id).
    GROUP BY c.customer_unique_id
),

-- ============================================================
-- CTE 2: rfm_scores
--
-- Assigns a score of 1-4 to each customer on each RFM dimension
-- using NTILE(4), a window function that divides all rows into
-- 4 equal-sized buckets ranked by the specified column.
--
-- NTILE(4) ORDER BY days_since_last_order ASC:
--   Bucket 1 = longest time since last order (worst recency)
--   Bucket 4 = most recent customers (best recency)
--   Note: we flip the order so that 4 always means "best."
--
-- NTILE(4) ORDER BY total_orders ASC:
--   Bucket 1 = fewest orders (worst frequency)
--   Bucket 4 = most orders (best frequency)
--
-- NTILE(4) ORDER BY total_spend ASC:
--   Bucket 1 = lowest spend (worst monetary)
--   Bucket 4 = highest spend (best monetary)
-- ============================================================

rfm_scores AS (
    SELECT
        customer_unique_id,
        last_order_date,
        days_since_last_order,
        total_orders,
        total_spend,

        -- Recency score: 4 = most recent, 1 = least recent.
        -- We ORDER BY DESC so the most recent customers get bucket 4.
        NTILE(4) OVER (ORDER BY days_since_last_order DESC) AS r_score,

        -- Frequency score: 4 = most orders, 1 = fewest orders.
        NTILE(4) OVER (ORDER BY total_orders ASC)           AS f_score,

        -- Monetary score: 4 = highest spend, 1 = lowest spend.
        NTILE(4) OVER (ORDER BY total_spend ASC)            AS m_score

    FROM customer_orders
),

-- ============================================================
-- CTE 3: rfm_segments
--
-- Combines the three scores into a single segment label using
-- CASE WHEN logic. The combined score (r + f + m) ranges from
-- 3 (worst: 1+1+1) to 12 (best: 4+4+4).
--
-- Segment definitions:
--   Champions      = top scores on all three dimensions
--   Loyal          = high frequency and monetary, decent recency
--   At Risk        = previously good customers, now lapsing
--   Promising      = recent but low frequency/spend (new customers)
--   Needs Attention = mid-range on everything
--   Lost           = low scores across the board
-- ============================================================

rfm_segments AS (
    SELECT
        customer_unique_id,
        last_order_date,
        days_since_last_order,
        total_orders,
        total_spend,
        r_score,
        f_score,
        m_score,

        -- Combined RFM score: sum of all three scores (3 to 12).
        r_score + f_score + m_score AS rfm_total,

        -- Segment label based on score combinations.
        -- Champions: top recency + high frequency + high monetary.
        -- At Risk: low recency but previously high frequency/monetary.
        -- Promising: recent buyers who haven't spent much yet.
        -- Lost: low on everything, unlikely to return.
        CASE
            WHEN r_score = 4 AND f_score >= 3 AND m_score >= 3
                THEN 'Champions'
            WHEN f_score >= 3 AND m_score >= 3
                THEN 'Loyal'
            WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3
                THEN 'At Risk'
            WHEN r_score >= 3 AND f_score <= 2
                THEN 'Promising'
            WHEN r_score + f_score + m_score >= 7
                THEN 'Needs Attention'
            ELSE 'Lost'
        END AS segment

    FROM rfm_scores
)

-- ============================================================
-- Final Output: Segment summary
--
-- Rather than returning one row per customer (which would be
-- 90,000+ rows), we aggregate to one row per segment.
-- This gives a clear picture of how customers are distributed
-- and what each segment looks like on average.
-- ============================================================

SELECT
    segment,

    -- Number of customers in this segment
    COUNT(*)                            AS customer_count,

    -- What percentage of total customers this segment represents
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 2) AS pct_of_customers,

    -- Average days since last order (lower = more recent)
    ROUND(AVG(days_since_last_order), 0) AS avg_days_since_last_order,

    -- Average number of orders per customer in this segment
    ROUND(AVG(total_orders), 2)         AS avg_orders,

    -- Average total spend per customer in this segment
    ROUND(AVG(total_spend), 2)          AS avg_spend,

    -- Total revenue generated by this segment
    ROUND(SUM(total_spend), 2)          AS total_segment_revenue,

    -- Average RFM combined score for context
    ROUND(AVG(r_score + f_score + m_score), 1) AS avg_rfm_score

FROM rfm_segments
GROUP BY segment
ORDER BY avg_rfm_score DESC;
