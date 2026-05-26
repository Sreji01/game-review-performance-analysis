# Game Marketplace Analytics

PostgreSQL projekat za analizu uticaja normalizacije, fragmentacije,
particionisanja, denormalizacije i indeksiranja na performanse upita u
sistemu za prodaju i recenziranje digitalnih igara.

## Database Setup

Lokalna baza za projekat:

```text
game_marketplace_analytics
```

Pocetna, normalizovana varijanta modela nalazi se u PostgreSQL semi
`normalized`.

Kreiranje baze i pokretanje pocetnih SQL skripti:

```bash
createdb game_marketplace_analytics
psql -d game_marketplace_analytics -v ON_ERROR_STOP=1 -f sql/01_schema_normalized.sql
psql -d game_marketplace_analytics -v ON_ERROR_STOP=1 -f sql/02_seed_reference_data.sql
```

## Normalized Model

Pocetni model sadrzi sledece tabele:

```text
countries
users
developers
publishers
games
genres
game_genres
platforms
game_platforms
reviews
review_votes
orders
order_items
wishlists
```

Ovaj model predstavlja baseline za kasnije poredjenje sa:

- vertikalno fragmentisanim korisnickim podacima
- horizontalno particionisanim recenzijama i/ili narudzbinama
- denormalizovanim agregatima za igre
- varijantama sa i bez dodatnih indeksa
