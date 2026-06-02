\set ON_ERROR_STOP on
\timing on

\echo 'F1 - Most active reviewers using vertical users_basic fragment'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    ub.id,
    ub.username,
    c.region,
    COUNT(r.id) AS review_count,
    AVG(r.rating) AS average_rating
FROM fragmented.users_basic ub
JOIN normalized.reviews r ON r.user_id = ub.id
LEFT JOIN normalized.countries c ON c.id = ub.country_id
GROUP BY ub.id, ub.username, c.region
ORDER BY review_count DESC, ub.id
LIMIT 20;

\echo 'F2 - Reconstruct user data from vertical fragments'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    ub.id,
    ub.username,
    ub.email,
    ub.account_status,
    up.date_of_birth,
    up.bio,
    up.avatar_url
FROM fragmented.users_basic ub
JOIN fragmented.users_profile up ON up.id = ub.id
WHERE ub.account_status = 'active'
ORDER BY ub.id
LIMIT 100;

\echo 'F3 - Average rating for one game using reviews_2024 fragment'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    g.id,
    g.title,
    AVG(r.rating) AS average_rating,
    COUNT(*) AS review_count
FROM normalized.games g
JOIN fragmented.reviews_2024 r ON r.game_id = g.id
WHERE g.id = (
    SELECT game_id
    FROM fragmented.reviews_2024
    GROUP BY game_id
    ORDER BY COUNT(*) DESC, game_id
    LIMIT 1
)
GROUP BY g.id, g.title;

\echo 'F4 - Reviews per year using all horizontal review fragments'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    EXTRACT(YEAR FROM r.created_at) AS review_year,
    COUNT(*) AS review_count,
    AVG(r.rating) AS average_rating
FROM fragmented.reviews_all r
GROUP BY EXTRACT(YEAR FROM r.created_at)
ORDER BY review_year;

\echo 'F5 - Review count by horizontal fragment'
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
