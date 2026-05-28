CREATE SCHEMA IF NOT EXISTS normalized;

SET search_path TO normalized, public;

CREATE TABLE IF NOT EXISTS countries (
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code CHAR(2) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL UNIQUE,
    region VARCHAR(30) NOT NULL CHECK (
        region IN ('Europe', 'North America', 'South America', 'Asia', 'Africa', 'Oceania')
    )
);

CREATE TABLE IF NOT EXISTS users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    country_id SMALLINT REFERENCES countries (id),
    date_of_birth DATE,
    account_status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (
        account_status IN ('active', 'suspended', 'deleted')
    ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMPTZ,
    bio TEXT,
    avatar_url TEXT
);

CREATE TABLE IF NOT EXISTS developers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    country_id SMALLINT REFERENCES countries (id),
    founded_year SMALLINT CHECK (founded_year BETWEEN 1800 AND 2100),
    website_url TEXT,
    UNIQUE (name, country_id)
);

CREATE TABLE IF NOT EXISTS publishers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    country_id SMALLINT REFERENCES countries (id),
    founded_year SMALLINT CHECK (founded_year BETWEEN 1800 AND 2100),
    website_url TEXT,
    UNIQUE (name, country_id)
);

CREATE TABLE IF NOT EXISTS games (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    developer_id BIGINT NOT NULL REFERENCES developers (id),
    publisher_id BIGINT NOT NULL REFERENCES publishers (id),
    release_date DATE,
    base_price NUMERIC(10, 2) NOT NULL CHECK (base_price >= 0),
    age_rating VARCHAR(10) CHECK (age_rating IN ('E', 'E10+', 'T', 'M', 'AO', 'RP')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (title, developer_id, release_date)
);

CREATE TABLE IF NOT EXISTS genres (
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS game_genres (
    game_id BIGINT NOT NULL REFERENCES games (id) ON DELETE CASCADE,
    genre_id SMALLINT NOT NULL REFERENCES genres (id),
    PRIMARY KEY (game_id, genre_id)
);

CREATE TABLE IF NOT EXISTS platforms (
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(80) NOT NULL UNIQUE,
    manufacturer VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS game_platforms (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    game_id BIGINT NOT NULL REFERENCES games (id) ON DELETE CASCADE,
    platform_id SMALLINT NOT NULL REFERENCES platforms (id),
    release_date DATE NOT NULL,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    UNIQUE (game_id, platform_id)
);

CREATE TABLE IF NOT EXISTS reviews (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users (id),
    game_id BIGINT NOT NULL,
    platform_id SMALLINT NOT NULL,
    rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 10),
    review_title VARCHAR(150),
    review_text TEXT NOT NULL,
    playtime_hours NUMERIC(10, 1) CHECK (playtime_hours >= 0),
    is_recommended BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,
    CONSTRAINT fk_reviews_game_platform
        FOREIGN KEY (game_id, platform_id)
        REFERENCES game_platforms (game_id, platform_id),
    CONSTRAINT uq_reviews_user_game_platform UNIQUE (user_id, game_id, platform_id),
    CONSTRAINT ck_reviews_updated_at CHECK (
        updated_at IS NULL OR updated_at >= created_at
    )
);

CREATE TABLE IF NOT EXISTS review_votes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    review_id BIGINT NOT NULL REFERENCES reviews (id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    is_helpful BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (review_id, user_id)
);

CREATE TABLE IF NOT EXISTS orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users (id),
    billing_country_id SMALLINT NOT NULL REFERENCES countries (id),
    order_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_status VARCHAR(20) NOT NULL CHECK (
        payment_status IN ('pending', 'paid', 'failed', 'refunded', 'cancelled')
    ),
    payment_method VARCHAR(20) NOT NULL CHECK (
        payment_method IN ('card', 'paypal', 'wallet', 'gift_card')
    )
);

CREATE TABLE IF NOT EXISTS order_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
    game_id BIGINT NOT NULL,
    platform_id SMALLINT NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    discount_amount NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    UNIQUE (order_id, game_id, platform_id),
    CONSTRAINT fk_order_items_game_platform
        FOREIGN KEY (game_id, platform_id)
        REFERENCES game_platforms (game_id, platform_id),
    CONSTRAINT ck_order_items_discount CHECK (discount_amount <= unit_price)
);

CREATE TABLE IF NOT EXISTS wishlists (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    game_id BIGINT NOT NULL REFERENCES games (id) ON DELETE CASCADE,
    added_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, game_id)
);
