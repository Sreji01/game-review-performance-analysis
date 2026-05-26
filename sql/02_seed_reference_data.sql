SET search_path TO normalized, public;

INSERT INTO countries (code, name, region) VALUES
    ('RS', 'Serbia', 'Europe'),
    ('DE', 'Germany', 'Europe'),
    ('FR', 'France', 'Europe'),
    ('GB', 'United Kingdom', 'Europe'),
    ('PL', 'Poland', 'Europe'),
    ('US', 'United States', 'North America'),
    ('CA', 'Canada', 'North America'),
    ('BR', 'Brazil', 'South America'),
    ('JP', 'Japan', 'Asia'),
    ('KR', 'South Korea', 'Asia'),
    ('CN', 'China', 'Asia'),
    ('AU', 'Australia', 'Oceania'),
    ('ZA', 'South Africa', 'Africa')
ON CONFLICT (code) DO NOTHING;

INSERT INTO genres (name) VALUES
    ('Action'),
    ('Adventure'),
    ('RPG'),
    ('Strategy'),
    ('Simulation'),
    ('Sports'),
    ('Racing'),
    ('Puzzle'),
    ('Shooter'),
    ('Survival'),
    ('Horror'),
    ('Indie'),
    ('MMO'),
    ('Platformer')
ON CONFLICT (name) DO NOTHING;

INSERT INTO platforms (name, manufacturer) VALUES
    ('PC', NULL),
    ('PlayStation 5', 'Sony'),
    ('Xbox Series X/S', 'Microsoft'),
    ('Nintendo Switch', 'Nintendo'),
    ('Steam Deck', 'Valve')
ON CONFLICT (name) DO NOTHING;
