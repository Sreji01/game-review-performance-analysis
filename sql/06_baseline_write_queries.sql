\set ON_ERROR_STOP on
\timing on

SET search_path TO normalized, public;

\echo 'W1 - Insert one review and roll back'
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO reviews (
    user_id,
    game_id,
    platform_id,
    rating,
    review_title,
    review_text,
    playtime_hours,
    is_recommended,
    created_at
)
SELECT
    candidate.user_id,
    candidate.game_id,
    candidate.platform_id,
    9,
    'Benchmark insert review',
    'This review is inserted only for write benchmark measurement.',
    42.5,
    TRUE,
    CURRENT_TIMESTAMP
FROM (
    SELECT
        u.id AS user_id,
        gp.game_id,
        gp.platform_id
    FROM (
        SELECT id
        FROM users
        ORDER BY id DESC
        LIMIT 1
    ) u
    JOIN game_platforms gp ON true
    WHERE NOT EXISTS (
        SELECT 1
        FROM reviews r
        WHERE r.user_id = u.id
          AND r.game_id = gp.game_id
          AND r.platform_id = gp.platform_id
    )
    ORDER BY u.id, gp.id
    LIMIT 1
) candidate;

ROLLBACK;

\echo 'W2 - Update one review rating and roll back'
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
UPDATE reviews
SET
    rating = CASE WHEN rating = 10 THEN 9 ELSE rating + 1 END,
    updated_at = CURRENT_TIMESTAMP
WHERE id = (
    SELECT id
    FROM reviews
    ORDER BY id DESC
    LIMIT 1
);

ROLLBACK;

\echo 'W3 - Insert one paid order and one order item, then roll back'
BEGIN;

CREATE TEMP TABLE benchmark_order_source AS
SELECT
    u.id AS user_id,
    COALESCE(u.country_id, (SELECT id FROM countries ORDER BY id LIMIT 1)) AS billing_country_id,
    gp.game_id,
    gp.platform_id,
    gp.price
FROM (
    SELECT id, country_id
    FROM users
    ORDER BY id DESC
    LIMIT 1
) u
JOIN game_platforms gp ON true
ORDER BY u.id DESC, gp.id DESC
LIMIT 1;

EXPLAIN (ANALYZE, BUFFERS)
WITH inserted_order AS (
    INSERT INTO orders (
        user_id,
        billing_country_id,
        order_date,
        payment_status,
        payment_method
    )
    SELECT
        user_id,
        billing_country_id,
        CURRENT_TIMESTAMP,
        'paid',
        'card'
    FROM benchmark_order_source
    RETURNING id
)
INSERT INTO order_items (
    order_id,
    game_id,
    platform_id,
    unit_price,
    discount_amount
)
SELECT
    inserted_order.id,
    benchmark_order_source.game_id,
    benchmark_order_source.platform_id,
    benchmark_order_source.price,
    0
FROM inserted_order
CROSS JOIN benchmark_order_source;

ROLLBACK;
