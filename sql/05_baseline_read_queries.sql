\set ON_ERROR_STOP on
\timing on

SET search_path TO normalized, public;

\echo 'Q1 - Reviews for a single game'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    r.id,
    r.user_id,
    r.game_id,
    r.platform_id,
    r.rating,
    r.review_title,
    r.created_at
FROM reviews r
WHERE r.game_id = (
    SELECT game_id
    FROM reviews
    GROUP BY game_id
    ORDER BY COUNT(*) DESC, game_id
    LIMIT 1
)
ORDER BY r.created_at DESC;

\echo 'Q2 - Reviews written by one active user with game and platform info'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    r.id,
    r.rating,
    r.review_title,
    r.created_at,
    g.title,
    p.name AS platform_name
FROM reviews r
JOIN games g ON g.id = r.game_id
JOIN platforms p ON p.id = r.platform_id
WHERE r.user_id = (
    SELECT user_id
    FROM reviews
    GROUP BY user_id
    ORDER BY COUNT(*) DESC, user_id
    LIMIT 1
)
ORDER BY r.created_at DESC;

\echo 'Q3 - Average rating and review count for one game'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    g.id,
    g.title,
    AVG(r.rating) AS average_rating,
    COUNT(*) AS review_count
FROM games g
JOIN reviews r ON r.game_id = g.id
WHERE g.id = (
    SELECT game_id
    FROM reviews
    GROUP BY game_id
    ORDER BY COUNT(*) DESC, game_id
    LIMIT 1
)
GROUP BY g.id, g.title;

\echo 'Q4 - Top rated games with at least 50 reviews'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    g.id,
    g.title,
    AVG(r.rating) AS average_rating,
    COUNT(*) AS review_count
FROM games g
JOIN reviews r ON r.game_id = g.id
GROUP BY g.id, g.title
HAVING COUNT(*) >= 50
ORDER BY average_rating DESC, review_count DESC
LIMIT 10;

\echo 'Q5 - Revenue by genre'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    ge.name AS genre,
    COUNT(*) AS sold_items,
    SUM(oi.unit_price - oi.discount_amount) AS revenue
FROM order_items oi
JOIN game_genres gg ON gg.game_id = oi.game_id
JOIN genres ge ON ge.id = gg.genre_id
GROUP BY ge.id, ge.name
ORDER BY revenue DESC;

\echo 'Q6 - Revenue and orders by customer billing region'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.region,
    COUNT(DISTINCT o.id) AS order_count,
    COUNT(oi.id) AS item_count,
    SUM(oi.unit_price - oi.discount_amount) AS revenue
FROM orders o
JOIN countries c ON c.id = o.billing_country_id
JOIN order_items oi ON oi.order_id = o.id
GROUP BY c.region
ORDER BY revenue DESC;

\echo 'Q7 - Reviews per year'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    EXTRACT(YEAR FROM r.created_at) AS review_year,
    COUNT(*) AS review_count,
    AVG(r.rating) AS average_rating
FROM reviews r
GROUP BY EXTRACT(YEAR FROM r.created_at)
ORDER BY review_year;

\echo 'Q8 - Platform catalog size and average price'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    p.name AS platform,
    COUNT(*) AS available_games,
    AVG(gp.price) AS average_price,
    MIN(gp.release_date) AS first_release,
    MAX(gp.release_date) AS latest_release
FROM game_platforms gp
JOIN platforms p ON p.id = gp.platform_id
GROUP BY p.id, p.name
ORDER BY available_games DESC;

\echo 'Q9 - Most active reviewers'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    u.id,
    u.username,
    c.region,
    COUNT(r.id) AS review_count,
    AVG(r.rating) AS average_rating
FROM users u
JOIN reviews r ON r.user_id = u.id
LEFT JOIN countries c ON c.id = u.country_id
GROUP BY u.id, u.username, c.region
ORDER BY review_count DESC, u.id
LIMIT 20;

\echo 'Q10 - Helpful votes by review and game'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    r.id AS review_id,
    g.title,
    r.rating,
    COUNT(rv.id) AS total_votes,
    COUNT(*) FILTER (WHERE rv.is_helpful) AS helpful_votes
FROM reviews r
JOIN games g ON g.id = r.game_id
JOIN review_votes rv ON rv.review_id = r.id
GROUP BY r.id, g.title, r.rating
ORDER BY helpful_votes DESC, total_votes DESC
LIMIT 20;
