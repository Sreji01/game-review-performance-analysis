SET search_path TO normalized, public;

SELECT 'users' AS table_name, COUNT(*) AS row_count FROM users
UNION ALL
SELECT 'developers', COUNT(*) FROM developers
UNION ALL
SELECT 'publishers', COUNT(*) FROM publishers
UNION ALL
SELECT 'games', COUNT(*) FROM games
UNION ALL
SELECT 'game_genres', COUNT(*) FROM game_genres
UNION ALL
SELECT 'game_platforms', COUNT(*) FROM game_platforms
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL
SELECT 'review_votes', COUNT(*) FROM review_votes
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'wishlists', COUNT(*) FROM wishlists
ORDER BY table_name;
