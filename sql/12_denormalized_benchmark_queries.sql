\set ON_ERROR_STOP on
\timing on

\echo 'D1 - Top rated games from denormalized game_statistics'
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

\echo 'D2 - Highest revenue games from denormalized game_statistics'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    game_id,
    title,
    developer_name,
    publisher_name,
    sold_item_count,
    total_revenue
FROM denormalized.game_statistics
ORDER BY total_revenue DESC
LIMIT 10;

\echo 'D3 - Most reviewed games from denormalized game_statistics'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    game_id,
    title,
    average_rating,
    review_count,
    recommended_review_count,
    last_review_at
FROM denormalized.game_statistics
ORDER BY review_count DESC, game_id
LIMIT 20;

\echo 'D4 - Marketplace summary from denormalized game_statistics'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    COUNT(*) AS game_count,
    SUM(review_count) AS review_count,
    ROUND(AVG(average_rating), 2) AS average_game_rating,
    SUM(wishlist_count) AS wishlist_count,
    SUM(sold_item_count) AS sold_item_count,
    SUM(total_revenue) AS total_revenue
FROM denormalized.game_statistics;

\echo 'D5 - Developer performance from denormalized game_statistics'
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
ORDER BY total_revenue DESC
LIMIT 20;
