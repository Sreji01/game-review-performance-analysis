\set ON_ERROR_STOP on
\timing on

CREATE SCHEMA IF NOT EXISTS denormalized;

DROP TABLE IF EXISTS denormalized.game_statistics;

\echo 'Creating denormalized game statistics table'

CREATE TABLE denormalized.game_statistics (
    game_id BIGINT PRIMARY KEY REFERENCES normalized.games (id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    developer_id BIGINT NOT NULL,
    developer_name VARCHAR(150) NOT NULL,
    publisher_id BIGINT NOT NULL,
    publisher_name VARCHAR(150) NOT NULL,
    release_date DATE,
    base_price NUMERIC(10, 2) NOT NULL,
    average_rating NUMERIC(5, 2),
    review_count BIGINT NOT NULL,
    recommended_review_count BIGINT NOT NULL,
    wishlist_count BIGINT NOT NULL,
    sold_item_count BIGINT NOT NULL,
    total_revenue NUMERIC(14, 2) NOT NULL,
    last_review_at TIMESTAMPTZ,
    refreshed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO denormalized.game_statistics (
    game_id,
    title,
    developer_id,
    developer_name,
    publisher_id,
    publisher_name,
    release_date,
    base_price,
    average_rating,
    review_count,
    recommended_review_count,
    wishlist_count,
    sold_item_count,
    total_revenue,
    last_review_at
)
SELECT
    g.id AS game_id,
    g.title,
    d.id AS developer_id,
    d.name AS developer_name,
    p.id AS publisher_id,
    p.name AS publisher_name,
    g.release_date,
    g.base_price,
    review_stats.average_rating,
    COALESCE(review_stats.review_count, 0) AS review_count,
    COALESCE(review_stats.recommended_review_count, 0) AS recommended_review_count,
    COALESCE(wishlist_stats.wishlist_count, 0) AS wishlist_count,
    COALESCE(sales_stats.sold_item_count, 0) AS sold_item_count,
    COALESCE(sales_stats.total_revenue, 0) AS total_revenue,
    review_stats.last_review_at
FROM normalized.games g
JOIN normalized.developers d ON d.id = g.developer_id
JOIN normalized.publishers p ON p.id = g.publisher_id
LEFT JOIN (
    SELECT
        game_id,
        ROUND(AVG(rating)::NUMERIC, 2) AS average_rating,
        COUNT(*) AS review_count,
        COUNT(*) FILTER (WHERE is_recommended) AS recommended_review_count,
        MAX(created_at) AS last_review_at
    FROM normalized.reviews
    GROUP BY game_id
) review_stats ON review_stats.game_id = g.id
LEFT JOIN (
    SELECT
        game_id,
        COUNT(*) AS wishlist_count
    FROM normalized.wishlists
    GROUP BY game_id
) wishlist_stats ON wishlist_stats.game_id = g.id
LEFT JOIN (
    SELECT
        game_id,
        COUNT(*) AS sold_item_count,
        SUM(unit_price - discount_amount) AS total_revenue
    FROM normalized.order_items
    GROUP BY game_id
) sales_stats ON sales_stats.game_id = g.id;

CREATE INDEX idx_game_statistics_average_rating
    ON denormalized.game_statistics (average_rating DESC, review_count DESC);

CREATE INDEX idx_game_statistics_total_revenue
    ON denormalized.game_statistics (total_revenue DESC);

CREATE INDEX idx_game_statistics_review_count
    ON denormalized.game_statistics (review_count DESC);

ANALYZE denormalized.game_statistics;

\echo 'Denormalized game statistics row count'

SELECT
    COUNT(*) AS game_statistics_count,
    SUM(review_count) AS total_reviews,
    SUM(wishlist_count) AS total_wishlists,
    SUM(sold_item_count) AS total_sold_items
FROM denormalized.game_statistics;
