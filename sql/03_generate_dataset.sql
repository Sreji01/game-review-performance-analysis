\set ON_ERROR_STOP on

SET search_path TO normalized, public;

CREATE TEMP TABLE dataset_config (
    dataset_size TEXT PRIMARY KEY,
    user_count INTEGER NOT NULL,
    developer_count INTEGER NOT NULL,
    publisher_count INTEGER NOT NULL,
    game_count INTEGER NOT NULL,
    review_count INTEGER NOT NULL,
    order_count INTEGER NOT NULL,
    order_item_count INTEGER NOT NULL,
    wishlist_count INTEGER NOT NULL,
    review_vote_count INTEGER NOT NULL
);

INSERT INTO dataset_config VALUES
    ('small', 1000, 50, 40, 200, 10000, 5000, 8000, 3000, 15000),
    ('medium', 10000, 250, 180, 2000, 100000, 50000, 80000, 30000, 150000),
    ('large', 100000, 1000, 700, 10000, 1000000, 500000, 800000, 300000, 1500000);

CREATE TEMP TABLE active_config AS
SELECT *
FROM dataset_config
WHERE dataset_size = :'dataset_size';

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM active_config) THEN
        RAISE EXCEPTION 'Unknown dataset_size. Use small, medium, or large.';
    END IF;
END $$;

TRUNCATE TABLE
    review_votes,
    order_items,
    orders,
    wishlists,
    reviews,
    game_genres,
    game_platforms,
    games,
    developers,
    publishers,
    users
RESTART IDENTITY CASCADE;

INSERT INTO users (
    username,
    email,
    password_hash,
    country_id,
    date_of_birth,
    account_status,
    created_at,
    last_login_at,
    bio,
    avatar_url
)
SELECT
    'user_' || gs,
    'user_' || gs || '@example.com',
    'synthetic_hash_' || gs,
    ((gs - 1) % country_counts.country_count + 1)::SMALLINT,
    DATE '1970-01-01' + ((gs * 17) % 12000),
    CASE
        WHEN gs % 97 = 0 THEN 'suspended'
        WHEN gs % 211 = 0 THEN 'deleted'
        ELSE 'active'
    END,
    TIMESTAMPTZ '2021-01-01 00:00:00+00' + ((gs % 1800) * INTERVAL '1 day'),
    TIMESTAMPTZ '2024-01-01 00:00:00+00' + ((gs % 730) * INTERVAL '1 day'),
    'Synthetic user profile for benchmark user ' || gs,
    'https://cdn.example.com/avatars/' || gs || '.png'
FROM active_config cfg
CROSS JOIN LATERAL generate_series(1, cfg.user_count) AS gs
CROSS JOIN LATERAL (SELECT COUNT(*)::INTEGER AS country_count FROM countries) AS country_counts;

INSERT INTO developers (name, country_id, founded_year, website_url)
SELECT
    'Developer Studio ' || gs,
    ((gs - 1) % country_counts.country_count + 1)::SMALLINT,
    (1980 + (gs % 44))::SMALLINT,
    'https://developers.example.com/studio-' || gs
FROM active_config cfg
CROSS JOIN LATERAL generate_series(1, cfg.developer_count) AS gs
CROSS JOIN LATERAL (SELECT COUNT(*)::INTEGER AS country_count FROM countries) AS country_counts;

INSERT INTO publishers (name, country_id, founded_year, website_url)
SELECT
    'Publisher Group ' || gs,
    ((gs * 3 - 1) % country_counts.country_count + 1)::SMALLINT,
    (1970 + (gs % 54))::SMALLINT,
    'https://publishers.example.com/group-' || gs
FROM active_config cfg
CROSS JOIN LATERAL generate_series(1, cfg.publisher_count) AS gs
CROSS JOIN LATERAL (SELECT COUNT(*)::INTEGER AS country_count FROM countries) AS country_counts;

INSERT INTO games (
    title,
    description,
    developer_id,
    publisher_id,
    release_date,
    base_price,
    age_rating,
    created_at
)
SELECT
    'Game ' || gs || ': ' ||
        CASE gs % 8
            WHEN 0 THEN 'Shadow Circuit'
            WHEN 1 THEN 'Neon Quest'
            WHEN 2 THEN 'Ancient Frontier'
            WHEN 3 THEN 'Pixel Arena'
            WHEN 4 THEN 'Crystal Kingdom'
            WHEN 5 THEN 'Rocket League Manager'
            WHEN 6 THEN 'Deep Space Colony'
            ELSE 'Midnight Rally'
        END,
    'Synthetic benchmark game ' || gs || ' used for database performance experiments.',
    ((gs - 1) % cfg.developer_count + 1)::BIGINT,
    ((gs * 5 - 1) % cfg.publisher_count + 1)::BIGINT,
    DATE '2016-01-01' + ((gs * 11) % 3650),
    ROUND((9.99 + ((gs * 137) % 7000) / 100.0)::NUMERIC, 2),
    CASE gs % 6
        WHEN 0 THEN 'E'
        WHEN 1 THEN 'E10+'
        WHEN 2 THEN 'T'
        WHEN 3 THEN 'M'
        WHEN 4 THEN 'AO'
        ELSE 'RP'
    END,
    TIMESTAMPTZ '2020-01-01 00:00:00+00' + ((gs % 1200) * INTERVAL '1 day')
FROM active_config cfg
CROSS JOIN LATERAL generate_series(1, cfg.game_count) AS gs;

INSERT INTO game_genres (game_id, genre_id)
SELECT DISTINCT
    g.id,
    (((g.id + offset_values.offset_value - 2) % genre_counts.genre_count) + 1)::SMALLINT
FROM games g
CROSS JOIN LATERAL (VALUES (1), (2), (3)) AS offset_values(offset_value)
CROSS JOIN LATERAL (SELECT COUNT(*)::INTEGER AS genre_count FROM genres) AS genre_counts;

INSERT INTO game_platforms (game_id, platform_id, release_date, price)
SELECT
    g.id,
    p.id,
    COALESCE(g.release_date, DATE '2018-01-01') + ((p.id - 1) * INTERVAL '30 days'),
    ROUND((g.base_price * (1 + ((p.id - 1) * 0.05)))::NUMERIC, 2)
FROM games g
JOIN platforms p
    ON p.id = 1
    OR ((g.id + p.id) % 2 = 0)
    OR (g.id % 5 = 0);

CREATE TEMP TABLE review_source AS
SELECT
    row_number() OVER (ORDER BY u.id, gp.id) AS rn,
    u.id AS user_id,
    gp.game_id,
    gp.platform_id,
    gp.id AS game_platform_id
FROM users u
JOIN game_platforms gp ON true
ORDER BY u.id, gp.id
LIMIT (SELECT review_count FROM active_config);

INSERT INTO reviews (
    user_id,
    game_id,
    platform_id,
    rating,
    review_title,
    review_text,
    playtime_hours,
    is_recommended,
    created_at,
    updated_at
)
SELECT
    user_id,
    game_id,
    platform_id,
    ((rn * 7) % 10 + 1)::SMALLINT,
    CASE rn % 5
        WHEN 0 THEN 'Excellent game'
        WHEN 1 THEN 'Solid experience'
        WHEN 2 THEN 'Mixed feelings'
        WHEN 3 THEN 'Worth trying'
        ELSE 'Needs polish'
    END,
    'Synthetic review ' || rn || ' for game ' || game_id || ' on platform ' || platform_id || '.',
    ROUND((((rn * 13) % 5000) / 10.0)::NUMERIC, 1),
    ((rn * 7) % 10 + 1) >= 6,
    TIMESTAMPTZ '2022-01-01 00:00:00+00' + ((rn % 1460) * INTERVAL '1 day'),
    CASE WHEN rn % 4 = 0 THEN TIMESTAMPTZ '2022-01-01 00:00:00+00' + ((rn % 1460) * INTERVAL '1 day') + INTERVAL '2 days' END
FROM review_source;

INSERT INTO wishlists (user_id, game_id, added_at)
SELECT
    user_id,
    game_id,
    TIMESTAMPTZ '2023-01-01 00:00:00+00' + ((rn % 500) * INTERVAL '1 day')
FROM (
    SELECT
        row_number() OVER (ORDER BY u.id, g.id) AS rn,
        u.id AS user_id,
        g.id AS game_id
    FROM users u
    JOIN games g ON ((u.id * 31 + g.id * 17) % 101) < 7
    ORDER BY u.id, g.id
) wishlist_source
WHERE rn <= (SELECT wishlist_count FROM active_config);

INSERT INTO orders (
    user_id,
    billing_country_id,
    order_date,
    payment_status,
    payment_method
)
SELECT
    ((gs - 1) % cfg.user_count + 1)::BIGINT,
    ((gs * 7 - 1) % country_counts.country_count + 1)::SMALLINT,
    TIMESTAMPTZ '2022-01-01 00:00:00+00' + ((gs % 1095) * INTERVAL '1 day') + ((gs % 24) * INTERVAL '1 hour'),
    CASE
        WHEN gs % 101 = 0 THEN 'refunded'
        WHEN gs % 89 = 0 THEN 'failed'
        WHEN gs % 53 = 0 THEN 'cancelled'
        WHEN gs % 17 = 0 THEN 'pending'
        ELSE 'paid'
    END,
    CASE gs % 4
        WHEN 0 THEN 'card'
        WHEN 1 THEN 'paypal'
        WHEN 2 THEN 'wallet'
        ELSE 'gift_card'
    END
FROM active_config cfg
CROSS JOIN LATERAL generate_series(1, cfg.order_count) AS gs
CROSS JOIN LATERAL (SELECT COUNT(*)::INTEGER AS country_count FROM countries) AS country_counts;

CREATE TEMP TABLE order_item_source AS
SELECT
    row_number() OVER (ORDER BY o.id, gp.id) AS rn,
    o.id AS order_id,
    gp.game_id,
    gp.platform_id,
    gp.price
FROM orders o
JOIN game_platforms gp ON ((o.id * 19 + gp.id * 23) % 100) < 12
ORDER BY o.id, gp.id
LIMIT (SELECT order_item_count FROM active_config);

INSERT INTO order_items (
    order_id,
    game_id,
    platform_id,
    unit_price,
    discount_amount
)
SELECT
    order_id,
    game_id,
    platform_id,
    price,
    ROUND((price * ((rn % 4) * 0.05))::NUMERIC, 2)
FROM order_item_source;

CREATE TEMP TABLE review_vote_source AS
SELECT
    row_number() OVER (ORDER BY r.id, u.id) AS rn,
    r.id AS review_id,
    u.id AS user_id
FROM reviews r
JOIN users u ON u.id <> r.user_id
WHERE ((r.id * 13 + u.id * 29) % 100) < 5
ORDER BY r.id, u.id
LIMIT (SELECT review_vote_count FROM active_config);

INSERT INTO review_votes (
    review_id,
    user_id,
    is_helpful,
    created_at
)
SELECT
    review_id,
    user_id,
    rn % 10 <> 0,
    TIMESTAMPTZ '2023-01-01 00:00:00+00' + ((rn % 600) * INTERVAL '1 day')
FROM review_vote_source;

ANALYZE normalized.users;
ANALYZE normalized.developers;
ANALYZE normalized.publishers;
ANALYZE normalized.games;
ANALYZE normalized.game_genres;
ANALYZE normalized.game_platforms;
ANALYZE normalized.reviews;
ANALYZE normalized.review_votes;
ANALYZE normalized.orders;
ANALYZE normalized.order_items;
ANALYZE normalized.wishlists;

SELECT
    dataset_size,
    user_count,
    game_count,
    review_count,
    order_count,
    order_item_count,
    wishlist_count,
    review_vote_count
FROM active_config;
