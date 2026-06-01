\set ON_ERROR_STOP on
\timing on

SET search_path TO normalized, public;

\echo 'Creating additional benchmark indexes'

CREATE INDEX IF NOT EXISTS idx_reviews_game_id
    ON reviews (game_id);

CREATE INDEX IF NOT EXISTS idx_reviews_user_id_created_at
    ON reviews (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_reviews_created_at
    ON reviews (created_at);

CREATE INDEX IF NOT EXISTS idx_reviews_game_rating
    ON reviews (game_id, rating);

CREATE INDEX IF NOT EXISTS idx_review_votes_review_id
    ON review_votes (review_id);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id
    ON order_items (order_id);

CREATE INDEX IF NOT EXISTS idx_order_items_game_id
    ON order_items (game_id);

CREATE INDEX IF NOT EXISTS idx_orders_billing_country_id
    ON orders (billing_country_id);

CREATE INDEX IF NOT EXISTS idx_orders_order_date
    ON orders (order_date);

CREATE INDEX IF NOT EXISTS idx_game_platforms_platform_id
    ON game_platforms (platform_id);

CREATE INDEX IF NOT EXISTS idx_game_genres_genre_id
    ON game_genres (genre_id);

ANALYZE normalized.reviews;
ANALYZE normalized.review_votes;
ANALYZE normalized.order_items;
ANALYZE normalized.orders;
ANALYZE normalized.game_platforms;
ANALYZE normalized.game_genres;

SELECT
    schemaname,
    tablename,
    indexname
FROM pg_indexes
WHERE schemaname = 'normalized'
  AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;
