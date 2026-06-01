\set ON_ERROR_STOP on
\timing on

SET search_path TO normalized, public;

\echo 'Dropping additional benchmark indexes'

DROP INDEX IF EXISTS normalized.idx_reviews_game_id;
DROP INDEX IF EXISTS normalized.idx_reviews_user_id_created_at;
DROP INDEX IF EXISTS normalized.idx_reviews_created_at;
DROP INDEX IF EXISTS normalized.idx_reviews_game_rating;
DROP INDEX IF EXISTS normalized.idx_review_votes_review_id;
DROP INDEX IF EXISTS normalized.idx_order_items_order_id;
DROP INDEX IF EXISTS normalized.idx_order_items_game_id;
DROP INDEX IF EXISTS normalized.idx_orders_billing_country_id;
DROP INDEX IF EXISTS normalized.idx_orders_order_date;
DROP INDEX IF EXISTS normalized.idx_game_platforms_platform_id;
DROP INDEX IF EXISTS normalized.idx_game_genres_genre_id;

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
