\set ON_ERROR_STOP on
\timing on

CREATE SCHEMA IF NOT EXISTS benchmark;

DROP TABLE IF EXISTS benchmark.query_results;
DROP TABLE IF EXISTS benchmark.runs;

\echo 'Creating benchmark result tables'

CREATE TABLE benchmark.runs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    run_label VARCHAR(120) NOT NULL UNIQUE,
    dataset_size VARCHAR(20) NOT NULL CHECK (dataset_size IN ('small', 'medium', 'large')),
    database_variant VARCHAR(40) NOT NULL CHECK (
        database_variant IN ('normalized', 'indexed', 'fragmented', 'denormalized')
    ),
    workload_type VARCHAR(20) NOT NULL CHECK (workload_type IN ('read', 'write')),
    executed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

CREATE TABLE benchmark.query_results (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    run_id BIGINT NOT NULL REFERENCES benchmark.runs (id) ON DELETE CASCADE,
    query_code VARCHAR(20) NOT NULL,
    query_name VARCHAR(200) NOT NULL,
    planning_time_ms NUMERIC(12, 3),
    execution_time_ms NUMERIC(12, 3) NOT NULL CHECK (execution_time_ms >= 0),
    total_psql_time_ms NUMERIC(12, 3),
    rows_returned BIGINT,
    plan_summary TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (run_id, query_code)
);

CREATE INDEX idx_benchmark_runs_lookup
    ON benchmark.runs (dataset_size, database_variant, workload_type);

CREATE INDEX idx_benchmark_query_results_run_id
    ON benchmark.query_results (run_id);

CREATE INDEX idx_benchmark_query_results_query_code
    ON benchmark.query_results (query_code);

\echo 'Example insert template'

/*
INSERT INTO benchmark.runs (
    run_label,
    dataset_size,
    database_variant,
    workload_type,
    notes
)
VALUES (
    'medium_normalized_read_001',
    'medium',
    'normalized',
    'read',
    'Baseline read benchmark without additional indexes.'
);

INSERT INTO benchmark.query_results (
    run_id,
    query_code,
    query_name,
    planning_time_ms,
    execution_time_ms,
    total_psql_time_ms,
    plan_summary
)
SELECT
    r.id,
    'Q1',
    'Reviews for a single game',
    1.234,
    50.678,
    55.000,
    'Seq Scan on reviews'
FROM benchmark.runs r
WHERE r.run_label = 'medium_normalized_read_001';
*/

SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'benchmark'
ORDER BY table_name;
