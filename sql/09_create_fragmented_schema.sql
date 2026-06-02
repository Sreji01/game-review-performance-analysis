\set ON_ERROR_STOP on
\timing on

CREATE SCHEMA IF NOT EXISTS fragmented;

DROP VIEW IF EXISTS fragmented.reviews_all;
DROP VIEW IF EXISTS fragmented.orders_all;
DROP TABLE IF EXISTS
    fragmented.orders_other,
    fragmented.orders_2024,
    fragmented.orders_2023,
    fragmented.orders_2022,
    fragmented.reviews_other,
    fragmented.reviews_2025,
    fragmented.reviews_2024,
    fragmented.reviews_2023,
    fragmented.reviews_2022,
    fragmented.users_profile,
    fragmented.users_basic
CASCADE;

\echo 'Creating vertical user fragments'

CREATE TABLE fragmented.users_basic AS
SELECT
    id,
    username,
    email,
    country_id,
    account_status,
    created_at,
    last_login_at
FROM normalized.users;

ALTER TABLE fragmented.users_basic
    ADD CONSTRAINT pk_users_basic PRIMARY KEY (id),
    ADD CONSTRAINT uq_users_basic_username UNIQUE (username),
    ADD CONSTRAINT uq_users_basic_email UNIQUE (email),
    ADD CONSTRAINT fk_users_basic_country
        FOREIGN KEY (country_id) REFERENCES normalized.countries (id);

CREATE TABLE fragmented.users_profile AS
SELECT
    id,
    password_hash,
    date_of_birth,
    bio,
    avatar_url
FROM normalized.users;

ALTER TABLE fragmented.users_profile
    ADD CONSTRAINT pk_users_profile PRIMARY KEY (id),
    ADD CONSTRAINT fk_users_profile_basic
        FOREIGN KEY (id) REFERENCES fragmented.users_basic (id) ON DELETE CASCADE;

\echo 'Creating horizontal review fragments'

CREATE TABLE fragmented.reviews_2022 AS
SELECT *
FROM normalized.reviews
WHERE created_at >= TIMESTAMPTZ '2022-01-01 00:00:00+00'
  AND created_at < TIMESTAMPTZ '2023-01-01 00:00:00+00';

ALTER TABLE fragmented.reviews_2022
    ADD CONSTRAINT pk_reviews_2022 PRIMARY KEY (id),
    ADD CONSTRAINT ck_reviews_2022_year CHECK (
        created_at >= TIMESTAMPTZ '2022-01-01 00:00:00+00'
        AND created_at < TIMESTAMPTZ '2023-01-01 00:00:00+00'
    ),
    ADD CONSTRAINT fk_reviews_2022_user
        FOREIGN KEY (user_id) REFERENCES normalized.users (id),
    ADD CONSTRAINT fk_reviews_2022_game_platform
        FOREIGN KEY (game_id, platform_id)
        REFERENCES normalized.game_platforms (game_id, platform_id);

CREATE TABLE fragmented.reviews_2023 AS
SELECT *
FROM normalized.reviews
WHERE created_at >= TIMESTAMPTZ '2023-01-01 00:00:00+00'
  AND created_at < TIMESTAMPTZ '2024-01-01 00:00:00+00';

ALTER TABLE fragmented.reviews_2023
    ADD CONSTRAINT pk_reviews_2023 PRIMARY KEY (id),
    ADD CONSTRAINT ck_reviews_2023_year CHECK (
        created_at >= TIMESTAMPTZ '2023-01-01 00:00:00+00'
        AND created_at < TIMESTAMPTZ '2024-01-01 00:00:00+00'
    ),
    ADD CONSTRAINT fk_reviews_2023_user
        FOREIGN KEY (user_id) REFERENCES normalized.users (id),
    ADD CONSTRAINT fk_reviews_2023_game_platform
        FOREIGN KEY (game_id, platform_id)
        REFERENCES normalized.game_platforms (game_id, platform_id);

CREATE TABLE fragmented.reviews_2024 AS
SELECT *
FROM normalized.reviews
WHERE created_at >= TIMESTAMPTZ '2024-01-01 00:00:00+00'
  AND created_at < TIMESTAMPTZ '2025-01-01 00:00:00+00';

ALTER TABLE fragmented.reviews_2024
    ADD CONSTRAINT pk_reviews_2024 PRIMARY KEY (id),
    ADD CONSTRAINT ck_reviews_2024_year CHECK (
        created_at >= TIMESTAMPTZ '2024-01-01 00:00:00+00'
        AND created_at < TIMESTAMPTZ '2025-01-01 00:00:00+00'
    ),
    ADD CONSTRAINT fk_reviews_2024_user
        FOREIGN KEY (user_id) REFERENCES normalized.users (id),
    ADD CONSTRAINT fk_reviews_2024_game_platform
        FOREIGN KEY (game_id, platform_id)
        REFERENCES normalized.game_platforms (game_id, platform_id);

CREATE TABLE fragmented.reviews_2025 AS
SELECT *
FROM normalized.reviews
WHERE created_at >= TIMESTAMPTZ '2025-01-01 00:00:00+00'
  AND created_at < TIMESTAMPTZ '2026-01-01 00:00:00+00';

ALTER TABLE fragmented.reviews_2025
    ADD CONSTRAINT pk_reviews_2025 PRIMARY KEY (id),
    ADD CONSTRAINT ck_reviews_2025_year CHECK (
        created_at >= TIMESTAMPTZ '2025-01-01 00:00:00+00'
        AND created_at < TIMESTAMPTZ '2026-01-01 00:00:00+00'
    ),
    ADD CONSTRAINT fk_reviews_2025_user
        FOREIGN KEY (user_id) REFERENCES normalized.users (id),
    ADD CONSTRAINT fk_reviews_2025_game_platform
        FOREIGN KEY (game_id, platform_id)
        REFERENCES normalized.game_platforms (game_id, platform_id);

CREATE TABLE fragmented.reviews_other AS
SELECT *
FROM normalized.reviews
WHERE created_at < TIMESTAMPTZ '2022-01-01 00:00:00+00'
   OR created_at >= TIMESTAMPTZ '2026-01-01 00:00:00+00';

ALTER TABLE fragmented.reviews_other
    ADD CONSTRAINT pk_reviews_other PRIMARY KEY (id),
    ADD CONSTRAINT ck_reviews_other_year CHECK (
        created_at < TIMESTAMPTZ '2022-01-01 00:00:00+00'
        OR created_at >= TIMESTAMPTZ '2026-01-01 00:00:00+00'
    ),
    ADD CONSTRAINT fk_reviews_other_user
        FOREIGN KEY (user_id) REFERENCES normalized.users (id),
    ADD CONSTRAINT fk_reviews_other_game_platform
        FOREIGN KEY (game_id, platform_id)
        REFERENCES normalized.game_platforms (game_id, platform_id);

CREATE VIEW fragmented.reviews_all AS
SELECT * FROM fragmented.reviews_2022
UNION ALL
SELECT * FROM fragmented.reviews_2023
UNION ALL
SELECT * FROM fragmented.reviews_2024
UNION ALL
SELECT * FROM fragmented.reviews_2025
UNION ALL
SELECT * FROM fragmented.reviews_other;

\echo 'Creating supporting indexes for fragmented tables'

CREATE INDEX idx_users_basic_country_id
    ON fragmented.users_basic (country_id);

CREATE INDEX idx_users_basic_account_status
    ON fragmented.users_basic (account_status);

CREATE INDEX idx_reviews_2022_game_id
    ON fragmented.reviews_2022 (game_id);

CREATE INDEX idx_reviews_2023_game_id
    ON fragmented.reviews_2023 (game_id);

CREATE INDEX idx_reviews_2024_game_id
    ON fragmented.reviews_2024 (game_id);

CREATE INDEX idx_reviews_2025_game_id
    ON fragmented.reviews_2025 (game_id);

CREATE INDEX idx_reviews_other_game_id
    ON fragmented.reviews_other (game_id);

CREATE INDEX idx_reviews_2022_user_id_created_at
    ON fragmented.reviews_2022 (user_id, created_at DESC);

CREATE INDEX idx_reviews_2023_user_id_created_at
    ON fragmented.reviews_2023 (user_id, created_at DESC);

CREATE INDEX idx_reviews_2024_user_id_created_at
    ON fragmented.reviews_2024 (user_id, created_at DESC);

CREATE INDEX idx_reviews_2025_user_id_created_at
    ON fragmented.reviews_2025 (user_id, created_at DESC);

CREATE INDEX idx_reviews_other_user_id_created_at
    ON fragmented.reviews_other (user_id, created_at DESC);

ANALYZE fragmented.users_basic;
ANALYZE fragmented.users_profile;
ANALYZE fragmented.reviews_2022;
ANALYZE fragmented.reviews_2023;
ANALYZE fragmented.reviews_2024;
ANALYZE fragmented.reviews_2025;
ANALYZE fragmented.reviews_other;

\echo 'Fragment row counts'

SELECT 'users_basic' AS fragment_name, COUNT(*) AS row_count FROM fragmented.users_basic
UNION ALL
SELECT 'users_profile', COUNT(*) FROM fragmented.users_profile
UNION ALL
SELECT 'reviews_2022', COUNT(*) FROM fragmented.reviews_2022
UNION ALL
SELECT 'reviews_2023', COUNT(*) FROM fragmented.reviews_2023
UNION ALL
SELECT 'reviews_2024', COUNT(*) FROM fragmented.reviews_2024
UNION ALL
SELECT 'reviews_2025', COUNT(*) FROM fragmented.reviews_2025
UNION ALL
SELECT 'reviews_other', COUNT(*) FROM fragmented.reviews_other
ORDER BY fragment_name;
