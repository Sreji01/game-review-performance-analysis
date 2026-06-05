\set ON_ERROR_STOP on
\timing on

\echo 'Benchmark run overview'

SELECT
    dataset_size,
    database_variant,
    workload_type,
    COUNT(*) AS run_count,
    MIN(executed_at) AS first_run_at,
    MAX(executed_at) AS latest_run_at
FROM benchmark.runs
GROUP BY dataset_size, database_variant, workload_type
ORDER BY dataset_size, workload_type, database_variant;

\echo 'Average execution time by query'

SELECT
    r.dataset_size,
    r.database_variant,
    r.workload_type,
    qr.query_code,
    qr.query_name,
    ROUND(AVG(qr.execution_time_ms), 3) AS avg_execution_time_ms,
    ROUND(MIN(qr.execution_time_ms), 3) AS min_execution_time_ms,
    ROUND(MAX(qr.execution_time_ms), 3) AS max_execution_time_ms,
    COUNT(*) AS measurement_count
FROM benchmark.runs r
JOIN benchmark.query_results qr ON qr.run_id = r.id
GROUP BY
    r.dataset_size,
    r.database_variant,
    r.workload_type,
    qr.query_code,
    qr.query_name
ORDER BY
    r.dataset_size,
    r.workload_type,
    qr.query_code,
    r.database_variant;

\echo 'Normalized baseline vs indexed comparison'

WITH averaged AS (
    SELECT
        r.dataset_size,
        r.workload_type,
        r.database_variant,
        qr.query_code,
        qr.query_name,
        AVG(qr.execution_time_ms) AS avg_execution_time_ms
    FROM benchmark.runs r
    JOIN benchmark.query_results qr ON qr.run_id = r.id
    WHERE r.database_variant IN ('normalized', 'indexed')
    GROUP BY
        r.dataset_size,
        r.workload_type,
        r.database_variant,
        qr.query_code,
        qr.query_name
)
SELECT
    normalized.dataset_size,
    normalized.workload_type,
    normalized.query_code,
    normalized.query_name,
    ROUND(normalized.avg_execution_time_ms, 3) AS normalized_ms,
    ROUND(indexed.avg_execution_time_ms, 3) AS indexed_ms,
    ROUND(
        normalized.avg_execution_time_ms / NULLIF(indexed.avg_execution_time_ms, 0),
        2
    ) AS speedup_ratio
FROM averaged normalized
JOIN averaged indexed
  ON indexed.dataset_size = normalized.dataset_size
 AND indexed.workload_type = normalized.workload_type
 AND indexed.query_code = normalized.query_code
WHERE normalized.database_variant = 'normalized'
  AND indexed.database_variant = 'indexed'
ORDER BY normalized.dataset_size, normalized.workload_type, normalized.query_code;

\echo 'Normalized vs fragmented or denormalized comparison'

WITH averaged AS (
    SELECT
        r.dataset_size,
        r.workload_type,
        r.database_variant,
        qr.query_code,
        qr.query_name,
        AVG(qr.execution_time_ms) AS avg_execution_time_ms
    FROM benchmark.runs r
    JOIN benchmark.query_results qr ON qr.run_id = r.id
    WHERE r.database_variant IN ('normalized', 'fragmented', 'denormalized')
    GROUP BY
        r.dataset_size,
        r.workload_type,
        r.database_variant,
        qr.query_code,
        qr.query_name
)
SELECT
    base.dataset_size,
    base.workload_type,
    optimized.database_variant AS compared_variant,
    base.query_code,
    base.query_name,
    ROUND(base.avg_execution_time_ms, 3) AS normalized_ms,
    ROUND(optimized.avg_execution_time_ms, 3) AS optimized_ms,
    ROUND(
        base.avg_execution_time_ms / NULLIF(optimized.avg_execution_time_ms, 0),
        2
    ) AS speedup_ratio
FROM averaged base
JOIN averaged optimized
  ON optimized.dataset_size = base.dataset_size
 AND optimized.workload_type = base.workload_type
 AND optimized.query_code = base.query_code
WHERE base.database_variant = 'normalized'
  AND optimized.database_variant IN ('fragmented', 'denormalized')
ORDER BY base.dataset_size, optimized.database_variant, base.workload_type, base.query_code;
