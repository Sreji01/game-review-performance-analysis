# Game Marketplace Analytics

Projekat predstavlja analizu performansi PostgreSQL baze podataka na primeru digitalne prodavnice video igara. Sistem modeluje korisnike, igre, developere, publishere, platforme, žanrove, recenzije, narudžbine, stavke narudžbina, liste želja i glasove na recenzije.

Glavni cilj projekta je da se na praktičnom primeru prikaže kako različite tehnike organizacije i optimizacije podataka utiču na brzinu izvršavanja SQL upita pri radu sa većim količinama podataka.

U projektu se analiziraju:

- normalizovana relaciona šema
- generisanje sintetičkih datasetova različitih veličina
- read i write benchmark upiti
- poređenje rada baze sa indeksima i bez indeksa
- vertikalna i horizontalna fragmentacija podataka
- odgovorna denormalizacija
- čuvanje i poređenje benchmark rezultata

## Tehnologije

- Java 17
- Spring Boot
- Spring Data JPA
- PostgreSQL
- SQL / PLpgSQL
- Maven

Spring Boot deo projekta sadrži JPA entitete koji odgovaraju normalizovanoj šemi baze, dok su performansni eksperimenti namerno realizovani kroz SQL skripte. Na taj način su svi koraci eksplicitni, ponovljivi i pogodni za analizu pomoću `EXPLAIN ANALYZE`.

## Struktura projekta

```text
.
├── pom.xml
├── src/main/java/com/sreji01/gamemarketplaceanalytics
│   ├── GameMarketplaceAnalyticsApplication.java
│   └── domain
│       ├── entity
│       └── enums
├── src/main/resources/application.properties
└── sql
    ├── 01_schema_normalized.sql
    ├── 02_seed_reference_data.sql
    ├── 03_generate_dataset.sql
    ├── 04_dataset_counts.sql
    ├── 05_baseline_read_queries.sql
    ├── 06_baseline_write_queries.sql
    ├── 07_create_indexes.sql
    ├── 08_drop_indexes.sql
    ├── 09_create_fragmented_schema.sql
    ├── 10_fragmented_benchmark_queries.sql
    ├── 11_create_denormalized_schema.sql
    ├── 12_denormalized_benchmark_queries.sql
    ├── 13_benchmark_results_schema.sql
    └── 14_benchmark_results_report.sql
```

## Domen sistema

Sistem je zamišljen kao marketplace za digitalne video igre. Korisnici mogu da kupuju igre, ostavljaju recenzije, dodaju igre u listu želja i glasaju da li su recenzije korisne.

Osnovni entiteti su:

- `countries` - države i regioni korisnika, developera, publishera i narudžbina
- `users` - korisnici sistema
- `developers` - razvojni studiji
- `publishers` - izdavači igara
- `games` - video igre
- `genres` - žanrovi igara
- `platforms` - platforme na kojima su igre dostupne
- `game_genres` - veza između igara i žanrova
- `game_platforms` - dostupnost igre na platformi
- `reviews` - recenzije korisnika
- `review_votes` - glasovi na recenzije
- `orders` - narudžbine
- `order_items` - stavke narudžbina
- `wishlists` - lista želja korisnika

Ovakav domen je pogodan za analizu performansi jer sadrži veliki broj povezanih tabela, različite tipove veza i upite koji uključuju filtriranje, spajanje, agregaciju i sortiranje.

## Priprema baze

Projekat koristi PostgreSQL bazu pod nazivom:

```text
game_marketplace_analytics
```

Ako baza ne postoji, može se kreirati komandom:

```bash
createdb game_marketplace_analytics
```

Alternativno, kroz `psql`:

```sql
CREATE DATABASE game_marketplace_analytics;
```

Sve SQL skripte se pokreću nad tom bazom:

```bash
psql -h localhost -d game_marketplace_analytics -f sql/<naziv_skripte>.sql
```

## Kreiranje normalizovane šeme

Prvi korak je kreiranje normalizovane šeme i referentnih podataka:

```bash
psql -h localhost -d game_marketplace_analytics \
  -v ON_ERROR_STOP=1 \
  -f sql/01_schema_normalized.sql

psql -h localhost -d game_marketplace_analytics \
  -v ON_ERROR_STOP=1 \
  -f sql/02_seed_reference_data.sql
```

Skripta `01_schema_normalized.sql` kreira šemu `normalized` i sve osnovne tabele. Skripta `02_seed_reference_data.sql` ubacuje referentne podatke, kao što su države, žanrovi i platforme.

## Generisanje datasetova

Podaci se generišu skriptom `03_generate_dataset.sql`. Podržane veličine su:

| Dataset | Korisnici | Igre | Recenzije | Narudžbine | Stavke narudžbina |
|---|---:|---:|---:|---:|---:|
| `small` | 1.000 | 200 | 10.000 | 5.000 | 8.000 |
| `medium` | 10.000 | 2.000 | 100.000 | 50.000 | 80.000 |
| `large` | 100.000 | 10.000 | 1.000.000 | 500.000 | 800.000 |

Primer generisanja small dataseta:

```bash
psql -h localhost -d game_marketplace_analytics \
  -v dataset_size=small \
  -f sql/03_generate_dataset.sql
```

Primer za medium:

```bash
psql -h localhost -d game_marketplace_analytics \
  -v dataset_size=medium \
  -f sql/03_generate_dataset.sql
```

Primer za large:

```bash
psql -h localhost -d game_marketplace_analytics \
  -v dataset_size=large \
  -f sql/03_generate_dataset.sql
```

Provera broja redova:

```bash
psql -h localhost -d game_marketplace_analytics \
  -f sql/04_dataset_counts.sql
```

## Benchmark metodologija

Za merenje performansi koristi se:

```sql
EXPLAIN (ANALYZE, BUFFERS)
```

Kao glavna vrednost za poređenje koristi se `Execution Time`, izražen u milisekundama.

U projektu postoje dve vrste benchmark upita:

- read upiti - testiraju pretragu, spajanje tabela, agregaciju i sortiranje
- write upiti - testiraju unos i izmenu podataka

Write upiti se izvršavaju unutar transakcije koja se završava sa `ROLLBACK`, kako bi se izmerila cena operacije bez trajne izmene dataseta.

## Baseline benchmark bez dodatnih indeksa

Pre baseline merenja mogu se ukloniti dodatni benchmark indeksi:

```bash
psql -h localhost -d game_marketplace_analytics \
  -v ON_ERROR_STOP=1 \
  -f sql/08_drop_indexes.sql
```

Read benchmark:

```bash
psql -h localhost -d game_marketplace_analytics \
  -v ON_ERROR_STOP=1 \
  -f sql/05_baseline_read_queries.sql
```

Write benchmark:

```bash
psql -h localhost -d game_marketplace_analytics \
  -v ON_ERROR_STOP=1 \
  -f sql/06_baseline_write_queries.sql
```

## Benchmark sa indeksima

Dodatni indeksi se kreiraju skriptom:

```bash
psql -h localhost -d game_marketplace_analytics \
  -v ON_ERROR_STOP=1 \
  -f sql/07_create_indexes.sql
```

Nakon toga se ponovo pokreću isti read i write upiti:

```bash
psql -h localhost -d game_marketplace_analytics \
  -v ON_ERROR_STOP=1 \
  -f sql/05_baseline_read_queries.sql

psql -h localhost -d game_marketplace_analytics \
  -v ON_ERROR_STOP=1 \
  -f sql/06_baseline_write_queries.sql
```

Ovo omogućava direktno poređenje istih SQL upita pre i posle indeksiranja.

## Fragmentacija podataka

Fragmentacija se realizuje skriptom:

```bash
psql -h localhost -d game_marketplace_analytics \
  -v ON_ERROR_STOP=1 \
  -f sql/09_create_fragmented_schema.sql
```

U projektu se koristi:

- vertikalna fragmentacija korisnika
- horizontalna fragmentacija recenzija

Vertikalna fragmentacija deli korisničke podatke na:

- `fragmented.users_basic`
- `fragmented.users_profile`

Horizontalna fragmentacija deli recenzije po godinama:

- `fragmented.reviews_2022`
- `fragmented.reviews_2023`
- `fragmented.reviews_2024`
- `fragmented.reviews_2025`
- `fragmented.reviews_other`

Benchmark upiti nad fragmentisanom šemom:

```bash
psql -h localhost -d game_marketplace_analytics \
  -v ON_ERROR_STOP=1 \
  -f sql/10_fragmented_benchmark_queries.sql
```

Fragmentacija nije zamišljena kao univerzalno ubrzanje svih upita. Njena prednost se vidi kada upit može da koristi samo potreban deo podataka, na primer određeni skup kolona ili recenzije iz jedne godine.

## Denormalizacija

Denormalizovana šema se kreira skriptom:

```bash
psql -h localhost -d game_marketplace_analytics \
  -v ON_ERROR_STOP=1 \
  -f sql/11_create_denormalized_schema.sql
```

Glavna denormalizovana tabela je:

```text
denormalized.game_statistics
```

Ona čuva unapred izračunate podatke po igri, kao što su:

- broj recenzija
- prosečna ocena
- broj pojavljivanja u listama želja
- broj prodatih stavki
- ukupan prihod
- naziv developera
- naziv publishera

Benchmark upiti nad denormalizovanom tabelom:

```bash
psql -h localhost -d game_marketplace_analytics \
  -v ON_ERROR_STOP=1 \
  -f sql/12_denormalized_benchmark_queries.sql
```

Denormalizacija je korisna za analitičke upite jer smanjuje broj `JOIN` operacija i izbegava ponovno računanje agregacija. Glavna mana je potreba za održavanjem konzistentnosti redundantnih podataka.

## Čuvanje benchmark rezultata

Za čuvanje rezultata merenja koristi se posebna šema `benchmark`.

Kreiranje tabela za rezultate:

```bash
psql -h localhost -d game_marketplace_analytics \
  -v ON_ERROR_STOP=1 \
  -f sql/13_benchmark_results_schema.sql
```

Skripta kreira tabele:

- `benchmark.runs`
- `benchmark.query_results`

Izveštaji nad unetim rezultatima:

```bash
psql -h localhost -d game_marketplace_analytics \
  -v ON_ERROR_STOP=1 \
  -f sql/14_benchmark_results_report.sql
```

Ova skripta prikazuje pregled izvršenih merenja, prosečna vremena izvršavanja i poređenja između normalizovane, indeksirane, fragmentisane i denormalizovane varijante.

## Preporučeni redosled pokretanja

Za kompletno testiranje jednog dataseta preporučen je sledeći redosled:

```bash
# 1. Normalizovana šema i referentni podaci
psql -h localhost -d game_marketplace_analytics -v ON_ERROR_STOP=1 -f sql/01_schema_normalized.sql
psql -h localhost -d game_marketplace_analytics -v ON_ERROR_STOP=1 -f sql/02_seed_reference_data.sql

# 2. Generisanje dataseta
psql -h localhost -d game_marketplace_analytics -v dataset_size=medium -f sql/03_generate_dataset.sql

# 3. Baseline bez dodatnih indeksa
psql -h localhost -d game_marketplace_analytics -v ON_ERROR_STOP=1 -f sql/08_drop_indexes.sql
psql -h localhost -d game_marketplace_analytics -v ON_ERROR_STOP=1 -f sql/05_baseline_read_queries.sql
psql -h localhost -d game_marketplace_analytics -v ON_ERROR_STOP=1 -f sql/06_baseline_write_queries.sql

# 4. Test sa indeksima
psql -h localhost -d game_marketplace_analytics -v ON_ERROR_STOP=1 -f sql/07_create_indexes.sql
psql -h localhost -d game_marketplace_analytics -v ON_ERROR_STOP=1 -f sql/05_baseline_read_queries.sql
psql -h localhost -d game_marketplace_analytics -v ON_ERROR_STOP=1 -f sql/06_baseline_write_queries.sql

# 5. Fragmentacija
psql -h localhost -d game_marketplace_analytics -v ON_ERROR_STOP=1 -f sql/09_create_fragmented_schema.sql
psql -h localhost -d game_marketplace_analytics -v ON_ERROR_STOP=1 -f sql/10_fragmented_benchmark_queries.sql

# 6. Denormalizacija
psql -h localhost -d game_marketplace_analytics -v ON_ERROR_STOP=1 -f sql/11_create_denormalized_schema.sql
psql -h localhost -d game_marketplace_analytics -v ON_ERROR_STOP=1 -f sql/12_denormalized_benchmark_queries.sql
```

Za drugi dataset dovoljno je ponovo pokrenuti `03_generate_dataset.sql` sa drugom vrednošću `dataset_size`, a zatim ponoviti benchmark korake.

## Pokretanje Spring Boot aplikacije

Spring Boot aplikacija koristi postojeću PostgreSQL bazu i šemu `normalized`.

Podrazumevani connection string:

```text
jdbc:postgresql://localhost:5432/game_marketplace_analytics?currentSchema=normalized
```

Pokretanje:

```bash
./mvnw spring-boot:run
```

Ako `mvnw` nije dostupan:

```bash
mvn spring-boot:run
```

Mogu se podesiti i environment promenljive:

```bash
export DB_URL=jdbc:postgresql://localhost:5432/game_marketplace_analytics?currentSchema=normalized
export DB_USERNAME=postgres
export DB_PASSWORD=postgres
```

Hibernate je podešen na `validate`, što znači da aplikacija ne kreira šemu automatski. Šema se kreira SQL skriptama da bi eksperimenti ostali eksplicitni i ponovljivi.

## Napomena o rezultatima

Rezultati benchmarka zavise od:

- veličine dataseta
- lokalnog računara
- dostupne memorije
- trenutnog stanja PostgreSQL cache-a
- plana izvršavanja koji odabere PostgreSQL optimizator
- toga da li su podaci već učitani u memoriju

Zbog toga konkretna vremena mogu da se razlikuju između različitih računara. Važniji od apsolutnih vrednosti je odnos između varijanti: bez indeksa, sa indeksima, fragmentisana šema i denormalizovana šema.

## Zaključak

Projekat pokazuje da performanse baze podataka ne zavise samo od količine podataka, već i od načina na koji su podaci organizovani. Normalizovana šema je dobra osnova za integritet i konzistentnost, ali kod velikih datasetova pojedini analitički upiti zahtevaju dodatnu optimizaciju.

Indeksi mogu značajno ubrzati selektivne upite, fragmentacija može smanjiti količinu podataka koju upit obrađuje, a denormalizacija može ubrzati izveštajne upite koji često koriste agregirane vrednosti. Svaka tehnika ima prednosti i mane, pa je za efikasno rešenje potrebno razumeti konkretan način korišćenja sistema i donositi odluke na osnovu merenja.
