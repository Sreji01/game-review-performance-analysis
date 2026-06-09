\set ON_ERROR_STOP on
\timing on

\echo 'F1-N - Top reviewed games in 2024 using normalized reviews table'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    g.id,
    g.title,
    COUNT(*) AS review_count,
    AVG(r.rating) AS average_rating
FROM normalized.reviews r
JOIN normalized.games g ON g.id = r.game_id
WHERE r.created_at >= TIMESTAMPTZ '2024-01-01 00:00:00+00'
  AND r.created_at < TIMESTAMPTZ '2025-01-01 00:00:00+00'
GROUP BY g.id, g.title
ORDER BY review_count DESC, g.id
LIMIT 20;

\echo 'F1-F - Top reviewed games in 2024 using horizontal reviews_2024 fragment'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    g.id,
    g.title,
    COUNT(*) AS review_count,
    AVG(r.rating) AS average_rating
FROM fragmented.reviews_2024 r
JOIN normalized.games g ON g.id = r.game_id
GROUP BY g.id, g.title
ORDER BY review_count DESC, g.id
LIMIT 20;

\echo 'F2-N - Latest 2024 reviews for one active reviewer using normalized reviews table'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    r.id,
    r.user_id,
    r.game_id,
    r.platform_id,
    r.rating,
    r.review_title,
    r.created_at
FROM normalized.reviews r
WHERE r.created_at >= TIMESTAMPTZ '2024-01-01 00:00:00+00'
  AND r.created_at < TIMESTAMPTZ '2025-01-01 00:00:00+00'
  AND r.user_id = (
      SELECT user_id
      FROM normalized.reviews
      WHERE created_at >= TIMESTAMPTZ '2024-01-01 00:00:00+00'
        AND created_at < TIMESTAMPTZ '2025-01-01 00:00:00+00'
      GROUP BY user_id
      ORDER BY COUNT(*) DESC, user_id
      LIMIT 1
  )
ORDER BY r.created_at DESC
LIMIT 50;

\echo 'F2-F - Latest 2024 reviews for one active reviewer using horizontal reviews_2024 fragment'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    r.id,
    r.user_id,
    r.game_id,
    r.platform_id,
    r.rating,
    r.review_title,
    r.created_at
FROM fragmented.reviews_2024 r
WHERE r.user_id = (
    SELECT user_id
    FROM fragmented.reviews_2024
    GROUP BY user_id
    ORDER BY COUNT(*) DESC, user_id
    LIMIT 1
)
ORDER BY r.created_at DESC
LIMIT 50;

\echo 'F3-N - Active user public data using normalized users table'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    u.id,
    u.username,
    u.email,
    u.country_id,
    u.account_status,
    u.created_at,
    u.last_login_at
FROM normalized.users u
WHERE u.account_status = 'active'
ORDER BY u.id
LIMIT 1000;

\echo 'F3-F - Active user public data using vertical users_basic fragment'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    ub.id,
    ub.username,
    ub.email,
    ub.country_id,
    ub.account_status,
    ub.created_at,
    ub.last_login_at
FROM fragmented.users_basic ub
WHERE ub.account_status = 'active'
ORDER BY ub.id
LIMIT 1000;

\echo 'F4-F - Review count by horizontal fragment'
EXPLAIN (ANALYZE, BUFFERS)
SELECT 'reviews_2022' AS fragment_name, COUNT(*) AS review_count FROM fragmented.reviews_2022
UNION ALL
SELECT 'reviews_2023', COUNT(*) FROM fragmented.reviews_2023
UNION ALL
SELECT 'reviews_2024', COUNT(*) FROM fragmented.reviews_2024
UNION ALL
SELECT 'reviews_2025', COUNT(*) FROM fragmented.reviews_2025
UNION ALL
SELECT 'reviews_other', COUNT(*) FROM fragmented.reviews_other
ORDER BY fragment_name;
