-- ============================================================
-- Analysis 4: Product Category Performance
--
-- Questions answered:
--   1. Which product categories generate the most revenue?
--   2. Which categories have the highest order volume?
--   3. Which categories have the best and worst review scores?
--   4. Which categories have the highest average order value?
--   5. How does each category rank across these dimensions?
--
-- Skills demonstrated: CTEs, multi-table joins, RANK() window
-- function, aggregate functions, LEFT JOIN for NULL handling,
-- revenue contribution percentage
-- ============================================================



-- ============================================================
-- CTE 1: category_metrics
--
-- Joins five tables to build a complete picture of each
-- product category's performance.
--
-- Table join chain:
--   order_items  (line items with price and product_id)
--   -> products  (product_id to category_name)
--   -> product_category_translation (Portuguese to English)
--   -> orders    (to filter by status and get order date)
--   -> order_payments (to get actual payment value)
--
-- We use the English category name for readability.
-- LEFT JOIN to translation handles products with no English name
-- (they appear as NULL in category_name_english).
-- ============================================================

WITH category_metrics AS (
    SELECT
        -- Use English category name where available, otherwise Portuguese.
        -- COALESCE returns the first non-NULL value from left to right.
        COALESCE(t.product_category_name_english, p.product_category_name) AS category,

        -- Count of individual order line items (not unique orders).
        -- One order can contain multiple items from different categories.
        COUNT(oi.order_id)                          AS total_items_sold,

        -- Count of unique orders that contain this category.
        COUNT(DISTINCT oi.order_id)                 AS total_orders,

        -- Total revenue from this category.
        -- We use item price (not payment value) here because payment value
        -- is at the order level and would double-count for multi-item orders.
        ROUND(SUM(oi.price), 2)                     AS total_revenue,

        -- Average price per item in this category.
        ROUND(AVG(oi.price), 2)                     AS avg_item_price,

        -- Average freight cost for items in this category.
        -- High freight relative to price can hurt conversion.
        ROUND(AVG(oi.freight_value), 2)             AS avg_freight_value,

        -- Average review score for orders containing this category.
        -- LEFT JOIN to reviews in the outer query handles missing reviews.
        ROUND(AVG(r.review_score), 2)               AS avg_review_score,

        -- Revenue as a percentage of total revenue across all categories.
        -- SUM() OVER () with no PARTITION BY gives the grand total.
        ROUND(
            SUM(oi.price) / SUM(SUM(oi.price)) OVER () * 100, 2
        )                                           AS revenue_pct_of_total

    FROM order_items oi

    -- Join to products to get the category name
    JOIN products p ON oi.product_id = p.product_id

    -- LEFT JOIN to translation so uncategorized products still appear
    LEFT JOIN product_category_translation t
        ON p.product_category_name = t.product_category_name

    -- Join to orders to filter on delivered status only
    JOIN orders o ON oi.order_id = o.order_id

    -- LEFT JOIN to deduplicated reviews (same ROW_NUMBER pattern as Analysis 2)
    LEFT JOIN (
        SELECT order_id, review_score
        FROM (
            SELECT order_id, review_score,
                   ROW_NUMBER() OVER (
                       PARTITION BY order_id
                       ORDER BY review_creation_date DESC, review_id DESC
                   ) AS rn
            FROM order_reviews
        ) ranked
        WHERE rn = 1
    ) r ON oi.order_id = r.order_id

    -- Delivered orders only
    WHERE o.order_status = 'delivered'

    -- Group by the English category name (or Portuguese fallback)
    GROUP BY COALESCE(t.product_category_name_english, p.product_category_name)
),

-- ============================================================
-- CTE 2: category_ranked
--
-- Adds RANK() columns to each category so we can see how it
-- compares to all other categories on each metric.
--
-- RANK() gives the same rank to ties and skips the next number.
-- For example: 1, 2, 2, 4 (not 1, 2, 2, 3).
--
-- We rank by revenue DESC so rank 1 = highest revenue.
-- We rank by review score DESC so rank 1 = highest rated.
-- We rank by avg_item_price DESC so rank 1 = most expensive.
-- ============================================================

category_ranked AS (
    SELECT
        category,
        total_items_sold,
        total_orders,
        total_revenue,
        revenue_pct_of_total,
        avg_item_price,
        avg_freight_value,
        avg_review_score,

        -- Revenue rank: 1 = highest revenue category
        RANK() OVER (ORDER BY total_revenue DESC)       AS revenue_rank,

        -- Volume rank: 1 = most items sold
        RANK() OVER (ORDER BY total_items_sold DESC)    AS volume_rank,

        -- Review rank: 1 = highest average review score
        RANK() OVER (ORDER BY avg_review_score DESC)    AS review_rank,

        -- Price rank: 1 = highest average item price
        RANK() OVER (ORDER BY avg_item_price DESC)      AS price_rank

    FROM category_metrics
    -- Only include categories with at least 50 orders to filter noise
    WHERE total_orders >= 50
)

-- ============================================================
-- Final Output: Top 20 categories by revenue
--
-- Shows the full picture for each category: volume, revenue,
-- pricing, freight, reviews, and rank on each dimension.
-- Filtered to top 20 by revenue for readability.
-- ============================================================

SELECT
    revenue_rank,
    category,
    total_items_sold,
    total_orders,
    total_revenue,
    revenue_pct_of_total,
    avg_item_price,
    avg_freight_value,
    avg_review_score,
    volume_rank,
    review_rank,
    price_rank
FROM category_ranked
ORDER BY revenue_rank
LIMIT 20;
