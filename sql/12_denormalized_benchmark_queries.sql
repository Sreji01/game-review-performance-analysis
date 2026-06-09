\set ON_ERROR_STOP on
\timing on

\echo 'D1-N - Top rated games using normalized joins and aggregation'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    g.id AS game_id,
    g.title,
    d.name AS developer_name,
    p.name AS publisher_name,
    AVG(r.rating) AS average_rating,
    COUNT(*) AS review_count
FROM normalized.games g
JOIN normalized.developers d ON d.id = g.developer_id
JOIN normalized.publishers p ON p.id = g.publisher_id
JOIN normalized.reviews r ON r.game_id = g.id
GROUP BY g.id, g.title, d.name, p.name
HAVING COUNT(*) >= 50
ORDER BY average_rating DESC, review_count DESC
LIMIT 10;

\echo 'D1-D - Top rated games using denormalized game_statistics'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    game_id,
    title,
    developer_name,
    publisher_name,
    average_rating,
    review_count
FROM denormalized.game_statistics
WHERE review_count >= 50
ORDER BY average_rating DESC, review_count DESC
LIMIT 10;

\echo 'D2-N - Highest revenue games using normalized joins and aggregation'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    g.id AS game_id,
    g.title,
    d.name AS developer_name,
    p.name AS publisher_name,
    COUNT(oi.id) AS sold_item_count,
    COALESCE(SUM(oi.unit_price - oi.discount_amount), 0) AS total_revenue
FROM normalized.games g
JOIN normalized.developers d ON d.id = g.developer_id
JOIN normalized.publishers p ON p.id = g.publisher_id
LEFT JOIN normalized.order_items oi ON oi.game_id = g.id
GROUP BY g.id, g.title, d.name, p.name
ORDER BY total_revenue DESC, sold_item_count DESC, g.id
LIMIT 10;

\echo 'D2-D - Highest revenue games using denormalized game_statistics'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    game_id,
    title,
    developer_name,
    publisher_name,
    sold_item_count,
    total_revenue
FROM denormalized.game_statistics
ORDER BY total_revenue DESC, sold_item_count DESC, game_id
LIMIT 10;

\echo 'D3-N - Developer performance using normalized aggregated subqueries'
EXPLAIN (ANALYZE, BUFFERS)
WITH review_stats AS (
    SELECT
        game_id,
        COUNT(*) AS review_count,
        AVG(rating) AS average_rating
    FROM normalized.reviews
    GROUP BY game_id
),
sales_stats AS (
    SELECT
        game_id,
        COUNT(*) AS sold_item_count,
        SUM(unit_price - discount_amount) AS total_revenue
    FROM normalized.order_items
    GROUP BY game_id
)
SELECT
    d.id AS developer_id,
    d.name AS developer_name,
    COUNT(g.id) AS game_count,
    COALESCE(SUM(rs.review_count), 0) AS review_count,
    ROUND(AVG(rs.average_rating), 2) AS average_rating,
    COALESCE(SUM(ss.sold_item_count), 0) AS sold_item_count,
    COALESCE(SUM(ss.total_revenue), 0) AS total_revenue
FROM normalized.developers d
JOIN normalized.games g ON g.developer_id = d.id
LEFT JOIN review_stats rs ON rs.game_id = g.id
LEFT JOIN sales_stats ss ON ss.game_id = g.id
GROUP BY d.id, d.name
ORDER BY total_revenue DESC, developer_id
LIMIT 20;

\echo 'D3-D - Developer performance using denormalized game_statistics'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    developer_id,
    developer_name,
    COUNT(*) AS game_count,
    SUM(review_count) AS review_count,
    ROUND(AVG(average_rating), 2) AS average_rating,
    SUM(sold_item_count) AS sold_item_count,
    SUM(total_revenue) AS total_revenue
FROM denormalized.game_statistics
GROUP BY developer_id, developer_name
ORDER BY total_revenue DESC, developer_id
LIMIT 20;
