//! Test helper functions for EQL tests
//!
//! Common utilities for working with encrypted data in tests.

use anyhow::{Context, Result};
use serde_json;
use sqlx::{PgPool, Row};

/// Fetch ORE encrypted value from pre-seeded ore table
///
/// The ore table is created by migration `002_install_ore_data.sql`
/// and contains 1000 pre-seeded records (ids 1-1000) for testing.
pub async fn get_ore_encrypted(pool: &PgPool, id: i32) -> Result<String> {
    let sql = format!("SELECT e::text FROM ore WHERE id = {}", id);
    let row = sqlx::query(&sql)
        .fetch_one(pool)
        .await
        .with_context(|| format!("fetching ore encrypted value for id={}", id))?;

    let result: Option<String> = row
        .try_get(0)
        .with_context(|| format!("extracting text column for id={}", id))?;

    result.with_context(|| format!("ore table returned NULL for id={}", id))
}

/// Fetch ORE text encrypted value from pre-seeded ore_text table
///
/// The ore_text table is created by migration `006_install_ore_text_data.sql`
/// and contains 100 pre-seeded records (ids 1-100) with lexicographically sorted words.
pub async fn get_ore_text_encrypted(pool: &PgPool, id: i32) -> Result<String> {
    let sql = format!("SELECT e::text FROM ore_text WHERE id = {}", id);
    let row = sqlx::query(&sql)
        .fetch_one(pool)
        .await
        .with_context(|| format!("fetching ore_text encrypted for id={}", id))?;
    let result: Option<String> = row
        .try_get(0)
        .with_context(|| format!("extracting text column for id={}", id))?;
    result.with_context(|| format!("ore_text returned NULL for id={}", id))
}

/// Fetch encrypted_int value from the bench table by id
///
/// The bench table is created by the bench_data fixture (10K rows, ids 1-10000).
pub async fn get_bench_encrypted_int(pool: &PgPool, id: i32) -> Result<String> {
    let result: Option<String> =
        sqlx::query_scalar("SELECT (encrypted_int).data::text FROM bench WHERE id = $1")
            .bind(id)
            .fetch_one(pool)
            .await
            .with_context(|| format!("fetching bench encrypted_int for id={id}"))?;
    result.with_context(|| format!("bench.encrypted_int is NULL for id={id}"))
}

/// Fetch encrypted_text value from the bench table by id
///
/// The bench table is created by the bench_data fixture (10K rows, ids 1-10000).
pub async fn get_bench_encrypted_text(pool: &PgPool, id: i32) -> Result<String> {
    let result: Option<String> =
        sqlx::query_scalar("SELECT (encrypted_text).data::text FROM bench WHERE id = $1")
            .bind(id)
            .fetch_one(pool)
            .await
            .with_context(|| format!("fetching bench encrypted_text for id={id}"))?;
    result.with_context(|| format!("bench.encrypted_text is NULL for id={id}"))
}

/// Assert sorted rows match expected sequential id range
pub fn assert_sequential_ids(rows: &[sqlx::postgres::PgRow], start: i64, end: i64) {
    let ids: Vec<i64> = rows.iter().map(|r| r.try_get(0).unwrap()).collect();
    let expected: Vec<i64> = (start..=end).collect();
    assert_eq!(ids, expected, "Expected sequential ids {}..={}", start, end);
}

/// Extract encrypted term from encrypted table by selector
///
/// Extracts a field from the first record in the encrypted table using
/// the provided selector hash. Used for containment operator tests.
///
/// # Arguments
/// * `pool` - Database connection pool
/// * `selector` - Selector hash for the field to extract (e.g., from Selectors constants)
///
/// # Example
/// ```ignore
/// let term = get_encrypted_term(&pool, Selectors::HELLO).await?;
/// ```
pub async fn get_encrypted_term(pool: &PgPool, selector: &str) -> Result<String> {
    // Note: Must cast selector to ::text to disambiguate operator overload
    // The -> operator has multiple signatures (text, eql_v2_encrypted, integer)
    let sql = format!(
        "SELECT (e -> '{}'::text)::text FROM encrypted LIMIT 1",
        selector
    );
    let row = sqlx::query(&sql)
        .fetch_one(pool)
        .await
        .with_context(|| format!("extracting encrypted term for selector={}", selector))?;

    let result: Option<String> = row
        .try_get(0)
        .with_context(|| format!("getting text column for selector={}", selector))?;

    result.with_context(|| {
        format!(
            "encrypted term extraction returned NULL for selector={}",
            selector
        )
    })
}

/// Internal: fetch ORE encrypted value as JSONB from any ORE table
///
/// Creates a JSONB value from the specified table that can be used with JSONB comparison
/// operators. ORE table values only contain {"ob": [...]}, so we merge in the required
/// "i" (index metadata) and "v" (version) fields to create a valid eql_v2_encrypted structure.
async fn get_ore_table_encrypted_as_jsonb(pool: &PgPool, table: &str, id: i32) -> Result<String> {
    let sql = format!(
        "SELECT (e::jsonb || jsonb_build_object('i', jsonb_build_object('t', 'ore'), 'v', 2))::text FROM {} WHERE id = {}",
        table, id
    );

    let row = sqlx::query(&sql)
        .fetch_one(pool)
        .await
        .with_context(|| format!("fetching {} encrypted as jsonb for id={}", table, id))?;

    let result: Option<String> = row
        .try_get(0)
        .with_context(|| format!("extracting jsonb text for id={}", id))?;

    result.with_context(|| format!("{} table returned NULL for id={}", table, id))
}

/// Fetch ORE encrypted value as JSONB for comparison
///
/// This creates a JSONB value from the ore table that can be used with JSONB comparison
/// operators. The ore table values only contain {"ob": [...]}, so we merge in the required
/// "i" (index metadata) and "v" (version) fields to create a valid eql_v2_encrypted structure.
pub async fn get_ore_encrypted_as_jsonb(pool: &PgPool, id: i32) -> Result<String> {
    get_ore_table_encrypted_as_jsonb(pool, "ore", id).await
}

/// Fetch ORE text encrypted value as JSONB for comparison
///
/// This creates a JSONB value from the ore_text table that can be used with JSONB comparison
/// operators. The ore_text table values only contain {"ob": [...]}, so we merge in the required
/// "i" (index metadata) and "v" (version) fields to create a valid eql_v2_encrypted structure.
pub async fn get_ore_text_encrypted_as_jsonb(pool: &PgPool, id: i32) -> Result<String> {
    get_ore_table_encrypted_as_jsonb(pool, "ore_text", id).await
}

/// Fetch STE vec encrypted value from a specified table as serde_json::Value
///
/// Default tables:
/// - `ste_vec`: Created by migration `003_install_ste_vec_data.sql`, 10 records (ids 1-10)
/// - `ste_vec_vast`: Created by migration `005_install_ste_vec_vast_data.sql`, 10,000 records
///
/// Test data structure:
/// - Records have selectors for $.hello (a7cea93975ed8c01f861ccb6bd082784) with ore_cllw_var_8
/// - Records have selectors for $.n (2517068c0d1f9d4d41d2c666211f785e) with ore_cllw_u64_8
///
/// Returns the encrypted value as parsed JSON, allowing callers to:
/// - Inspect structure programmatically
/// - Use .to_string() when a literal string is needed
/// - Avoid double-quoting issues with embedded apostrophes
///
/// # Arguments
/// * `pool` - Database connection pool
/// * `table` - Table name to query (e.g., "ste_vec" or "ste_vec_vast")
/// * `id` - Row id to fetch
pub async fn get_ste_vec_encrypted(
    pool: &PgPool,
    table: &str,
    id: i32,
) -> Result<serde_json::Value> {
    let sql = format!("SELECT (e).data::jsonb FROM {} WHERE id = {}", table, id);
    let result: serde_json::Value = sqlx::query_scalar(&sql)
        .fetch_one(pool)
        .await
        .with_context(|| format!("fetching {} encrypted value for id={}", table, id))?;

    Ok(result)
}

/// Fetch two STE vec encrypted values from the same table
///
/// Useful for encrypted-to-encrypted containment tests where we need
/// two distinct encrypted values from the same table.
///
/// # Arguments
/// * `pool` - Database connection pool
/// * `table` - Table name to query
/// * `id1` - First row id
/// * `id2` - Second row id
///
/// # Returns
/// Tuple of (enc1, enc2) as serde_json::Value
pub async fn get_ste_vec_encrypted_pair(
    pool: &PgPool,
    table: &str,
    id1: i32,
    id2: i32,
) -> Result<(serde_json::Value, serde_json::Value)> {
    let enc1 = get_ste_vec_encrypted(pool, table, id1).await?;
    let enc2 = get_ste_vec_encrypted(pool, table, id2).await?;
    Ok((enc1, enc2))
}

/// Extract a single SV element from an encrypted value as serde_json::Value
///
/// Fetches an encrypted value from the specified table and extracts
/// a specific element from its sv array by index.
///
/// # Arguments
/// * `pool` - Database connection pool
/// * `table` - Table name to query (e.g., "ste_vec" or "ste_vec_vast")
/// * `id` - Row id to fetch
/// * `sv_index` - Index into the sv array (0-based)
///
/// # Returns
/// The sv element as serde_json::Value, suitable for use in containment queries
/// Use .to_string() when a literal string is needed for SQL interpolation
pub async fn get_ste_vec_sv_element(
    pool: &PgPool,
    table: &str,
    id: i32,
    sv_index: i32,
) -> Result<serde_json::Value> {
    let sql = format!(
        "SELECT ((e).data->'sv'->{})::jsonb FROM {} WHERE id = {}",
        sv_index, table, id
    );
    let result: Option<serde_json::Value> = sqlx::query_scalar(&sql)
        .fetch_one(pool)
        .await
        .with_context(|| {
            format!(
                "extracting sv element {} from {} id={}",
                sv_index, table, id
            )
        })?;

    result.with_context(|| {
        format!(
            "{} sv element extraction returned NULL for id={}, index={}",
            table, id, sv_index
        )
    })
}

/// Extract selector term using SQL helper functions
///
/// Uses the get_numeric_ste_vec_*() helper functions to extract a selector term.
/// This matches the SQL test pattern exactly.
///
/// # Arguments
/// * `pool` - Database connection pool
/// * `value` - Which STE vec value to use (10, 20, 30, or 42)
/// * `selector` - Selector hash to extract (e.g., Selectors::N, Selectors::HELLO)
///
/// # Example
/// ```ignore
/// // Extract $.n selector from n=30 test data
/// let term = get_ste_vec_selector_term(&pool, 30, Selectors::N).await?;
/// ```
pub async fn get_ste_vec_selector_term(
    pool: &PgPool,
    value: i32,
    selector: &str,
) -> Result<String> {
    // Call the appropriate get_numeric_ste_vec_*() function
    let func_name = match value {
        10 => "get_numeric_ste_vec_10",
        20 => "get_numeric_ste_vec_20",
        30 => "get_numeric_ste_vec_30",
        42 => "get_numeric_ste_vec_42",
        _ => {
            return Err(anyhow::anyhow!(
                "Invalid value: {}. Must be 10, 20, 30, or 42",
                value
            ))
        }
    };

    // SQL equivalent: sv := get_numeric_ste_vec_30()::eql_v2_encrypted;
    //                  term := sv->'2517068c0d1f9d4d41d2c666211f785e'::text;
    let sql = format!(
        "SELECT ({}()::eql_v2_encrypted -> '{}'::text)::text",
        func_name, selector
    );

    let row = sqlx::query(&sql).fetch_one(pool).await.with_context(|| {
        format!(
            "extracting selector '{}' from ste_vec value={}",
            selector, value
        )
    })?;

    let result: Option<String> = row.try_get(0).with_context(|| {
        format!(
            "getting text column for selector '{}' from value={}",
            selector, value
        )
    })?;

    result.with_context(|| {
        format!(
            "selector extraction returned NULL for selector='{}', value={}",
            selector, value
        )
    })
}

/// Extract a term from the ste_vec table by id and selector
///
/// Queries the ste_vec table (from migration 003_install_ste_vec_data.sql)
/// and extracts a field using the provided selector hash.
///
/// # Arguments
/// * `pool` - Database connection pool
/// * `id` - Row id in ste_vec table (1-10)
/// * `selector` - Selector hash to extract (e.g., Selectors::STE_VEC_HELLO)
///
/// # Example
/// ```ignore
/// // Extract $.hello selector from ste_vec row 1
/// let term = get_ste_vec_term_by_id(&pool, 1, Selectors::STE_VEC_HELLO).await?;
/// ```
pub async fn get_ste_vec_term_by_id(pool: &PgPool, id: i32, selector: &str) -> Result<String> {
    // Extract term from ste_vec table using the -> operator
    let sql = format!(
        "SELECT (e -> '{}'::text)::text FROM ste_vec WHERE id = {}",
        selector, id
    );

    let row = sqlx::query(&sql)
        .fetch_one(pool)
        .await
        .with_context(|| format!("extracting selector '{}' from ste_vec id={}", selector, id))?;

    let result: Option<String> = row.try_get(0).with_context(|| {
        format!(
            "getting text column for selector '{}' from id={}",
            selector, id
        )
    })?;

    result.with_context(|| {
        format!(
            "ste_vec term extraction returned NULL for selector='{}', id={}",
            selector, id
        )
    })
}

// ============================================================================
// GIN Index Testing Helpers
// ============================================================================

/// Create a GIN index on the jsonb_array extraction for a table
///
/// Creates a functional GIN index on `eql_v2.jsonb_array(e)` which extracts
/// the encrypted JSONB as a jsonb[] array. Using jsonb[] instead of eql_v2_encrypted[]
/// leverages PostgreSQL's native hash support for jsonb elements.
///
/// # Arguments
/// * `pool` - Database connection pool
/// * `table` - Table name to create index on
/// * `index_name` - Name for the index
///
/// # Example
/// ```ignore
/// create_jsonb_gin_index(&pool, "jsonb_table", "jsonb_gin_idx").await?;
/// ```
pub async fn create_jsonb_gin_index(pool: &PgPool, table: &str, index_name: &str) -> Result<()> {
    let sql = format!(
        "CREATE INDEX IF NOT EXISTS {} ON {} USING GIN (eql_v2.jsonb_array(e))",
        index_name, table
    );
    sqlx::query(&sql)
        .execute(pool)
        .await
        .with_context(|| format!("creating GIN index {} on {}", index_name, table))?;
    Ok(())
}

/// Run ANALYZE on a table to update query planner statistics
///
/// Should be called after creating indexes to ensure the query planner
/// has accurate statistics for choosing optimal query plans.
///
/// # Arguments
/// * `pool` - Database connection pool
/// * `table` - Table name to analyze
pub async fn analyze_table(pool: &PgPool, table: &str) -> Result<()> {
    let sql = format!("ANALYZE {}", table);
    sqlx::query(&sql)
        .execute(pool)
        .await
        .with_context(|| format!("analyzing table {}", table))?;
    Ok(())
}

/// Run EXPLAIN on a query and return the plan as a string
///
/// Executes EXPLAIN and concatenates all output rows into a single string.
/// Useful for verifying index usage in query plans.
///
/// # Arguments
/// * `pool` - Database connection pool
/// * `query` - SQL query to explain (without EXPLAIN prefix).
///   Must be a trusted/hardcoded string — not user-supplied input,
///   as it is interpolated directly into the SQL statement.
///
/// # Returns
/// The EXPLAIN output as a newline-separated string
///
/// # Example
/// ```ignore
/// let plan = explain_query(&pool, "SELECT * FROM foo WHERE x = 1").await?;
/// assert!(plan.contains("Index Scan"));
/// ```
pub async fn explain_query(pool: &PgPool, query: &str) -> Result<String> {
    let sql = format!("EXPLAIN {}", query);
    let rows: Vec<(String,)> = sqlx::query_as(&sql)
        .fetch_all(pool)
        .await
        .with_context(|| format!("running EXPLAIN on query: {}", query))?;

    Ok(rows
        .iter()
        .map(|r| r.0.clone())
        .collect::<Vec<_>>()
        .join("\n"))
}

/// Assert that a query uses a specific index
///
/// Runs EXPLAIN on the query and verifies the specified index is used.
/// Follows the same pattern as assert_contains for consistency.
///
/// # Arguments
/// * `pool` - Database connection pool
/// * `sql` - SQL query with `{}` placeholder for the value
/// * `value` - Value to substitute into the query
/// * `index_name` - Expected index name to find in the plan
///
/// # Example
/// ```ignore
/// let sql = "SELECT * FROM t WHERE eql_v2.ste_vec(e) @> eql_v2.ste_vec('{}'::eql_v2_encrypted)";
/// assert_uses_index(&pool, sql, &row_b, "my_gin_idx").await?;
/// ```
pub async fn assert_uses_index(pool: &PgPool, sql: &str, index_name: &str) -> Result<()> {
    let explain_output = explain_query(pool, sql).await?;
    assert!(
        explain_output.contains(index_name),
        "Expected index '{}' to be used. EXPLAIN output:\n{}",
        index_name,
        explain_output
    );
    Ok(())
}

/// Assert that an EXPLAIN plan uses a sequential scan (no index)
///
/// Useful for testing that small tables don't force index usage.
///
/// # Arguments
/// * `explain_output` - Output from explain_query()
pub fn assert_uses_seq_scan(explain_output: &str) {
    assert!(
        explain_output.contains("Seq Scan"),
        "Expected Seq Scan to be used. EXPLAIN output:\n{}",
        explain_output
    );
}

// ============================================================================
// Benchmarking / EXPLAIN Helpers
// ============================================================================

/// Statistics extracted from EXPLAIN ANALYZE JSON output
///
/// Contains timing and plan information for benchmarking queries.
/// Used by `explain_analyze_avg` to return averaged statistics.
#[derive(Debug, Clone)]
pub struct ExplainStats {
    /// Average execution time in milliseconds across runs
    pub execution_time_ms: f64,
    /// Average planning time in milliseconds across runs
    pub planning_time_ms: f64,
    /// Top-level node type from the query plan (e.g., "Index Scan", "Seq Scan")
    pub node_type: String,
}

/// Run EXPLAIN with JSON format on a query and return the parsed plan
///
/// Executes `EXPLAIN (FORMAT JSON) {query}` and parses the result.
/// PostgreSQL returns a single-element JSON array containing the plan tree.
///
/// This is distinct from `explain_query()` which returns plain text output.
/// The JSON format provides structured access to plan nodes, costs, and types.
///
/// # Arguments
/// * `pool` - Database connection pool
/// * `query` - SQL query to explain (without EXPLAIN prefix).
///   Must be a trusted/hardcoded string — not user-supplied input,
///   as it is interpolated directly into the SQL statement.
///
/// # Returns
/// The full EXPLAIN JSON output as a `serde_json::Value`
///
/// # Example
/// ```ignore
/// let plan = explain_json(&pool, "SELECT * FROM foo WHERE x = 1").await?;
/// let node_type = plan[0]["Plan"]["Node Type"].as_str().unwrap();
/// ```
pub async fn explain_json(pool: &PgPool, query: &str) -> Result<serde_json::Value> {
    let sql = format!("EXPLAIN (FORMAT JSON) {}", query);
    let plan: serde_json::Value = sqlx::query_scalar(&sql)
        .fetch_one(pool)
        .await
        .with_context(|| format!("running EXPLAIN (FORMAT JSON) on query: {}", query))?;

    Ok(plan)
}

/// Run EXPLAIN ANALYZE multiple times and return averaged statistics
///
/// Executes `EXPLAIN (ANALYZE, FORMAT JSON) {query}` the specified number of times
/// and returns the arithmetic mean of execution and planning times.
///
/// **Warning**: EXPLAIN ANALYZE actually executes the query. If the query has
/// side effects (INSERT, UPDATE, DELETE), those effects will occur on every run.
///
/// **Note**: The first run may include cold-start overhead (buffer cache misses,
/// plan cache population). No runs are discarded — callers should account for this
/// when setting thresholds or increase the run count to dilute the effect.
///
/// # Arguments
/// * `pool` - Database connection pool
/// * `query` - SQL query to explain and execute (without EXPLAIN prefix).
///   Must be a trusted/hardcoded string — not user-supplied input,
///   as it is interpolated directly into the SQL statement.
/// * `runs` - Number of times to execute (must be >= 1)
///
/// # Returns
/// Averaged `ExplainStats` with mean execution_time_ms, mean planning_time_ms,
/// and the node_type from the first run's top-level plan node
///
/// # Example
/// ```ignore
/// let stats = explain_analyze_avg(&pool, "SELECT * FROM foo WHERE x = 1", 5).await?;
/// assert!(stats.execution_time_ms < 10.0, "Query too slow: {}ms", stats.execution_time_ms);
/// assert_eq!(stats.node_type, "Index Scan");
/// ```
pub async fn explain_analyze_avg(pool: &PgPool, query: &str, runs: usize) -> Result<ExplainStats> {
    anyhow::ensure!(runs >= 1, "runs must be >= 1, got {}", runs);

    let sql = format!("EXPLAIN (ANALYZE, FORMAT JSON) {}", query);

    let mut total_execution_ms = 0.0_f64;
    let mut total_planning_ms = 0.0_f64;
    let mut node_type = String::new();

    for i in 0..runs {
        let plan: serde_json::Value = sqlx::query_scalar(&sql)
            .fetch_one(pool)
            .await
            .with_context(|| {
                format!(
                    "running EXPLAIN ANALYZE (run {}/{}) on query: {}",
                    i + 1,
                    runs,
                    query
                )
            })?;

        // EXPLAIN (ANALYZE, FORMAT JSON) returns:
        // [{"Plan": {...}, "Planning Time": N, "Execution Time": N}]
        let entry = &plan[0];

        let exec_time = entry["Execution Time"]
            .as_f64()
            .with_context(|| format!("extracting Execution Time on run {}/{}", i + 1, runs))?;

        let plan_time = entry["Planning Time"]
            .as_f64()
            .with_context(|| format!("extracting Planning Time on run {}/{}", i + 1, runs))?;

        total_execution_ms += exec_time;
        total_planning_ms += plan_time;

        // Capture node type from first run only
        if i == 0 {
            node_type = entry["Plan"]["Node Type"]
                .as_str()
                .with_context(|| "extracting Node Type from first run")?
                .to_string();
        }
    }

    let n = runs as f64;
    Ok(ExplainStats {
        execution_time_ms: total_execution_ms / n,
        planning_time_ms: total_planning_ms / n,
        node_type,
    })
}

/// Assert that a JSON EXPLAIN plan does not use any sequential scan
///
/// Recursively walks the JSON plan tree checking all "Node Type" fields.
/// A plan can have nested nodes (e.g., Aggregate -> Seq Scan), so all levels
/// are checked. Both "Seq Scan" and "Parallel Seq Scan" are rejected.
///
/// This is the structured (JSON) counterpart to `assert_uses_seq_scan()` which
/// operates on plain text output.
///
/// # Arguments
/// * `plan` - JSON EXPLAIN output from `explain_json()` or `EXPLAIN (FORMAT JSON)`
///
/// # Panics
/// Panics if any node in the plan tree has a "Seq Scan" or "Parallel Seq Scan" node type
///
/// # Example
/// ```ignore
/// let plan = explain_json(&pool, "SELECT * FROM foo WHERE x = 1").await?;
/// assert_no_seq_scan(&plan);
/// ```
pub fn assert_no_seq_scan(plan: &serde_json::Value) {
    let mut seq_scan_nodes = Vec::new();
    collect_seq_scan_nodes(plan, &mut seq_scan_nodes);

    assert!(
        seq_scan_nodes.is_empty(),
        "Expected no sequential scans but found {} node(s): {:?}\nFull plan: {}",
        seq_scan_nodes.len(),
        seq_scan_nodes,
        serde_json::to_string_pretty(plan).unwrap_or_else(|_| plan.to_string())
    );
}

/// Recursively collect all sequential scan node types from a JSON EXPLAIN plan
///
/// Checks standard PostgreSQL node types only ("Seq Scan", "Parallel Seq Scan").
/// Custom scan providers (e.g., from extensions) are not currently detected.
fn collect_seq_scan_nodes(value: &serde_json::Value, found: &mut Vec<String>) {
    match value {
        serde_json::Value::Object(map) => {
            if let Some(node_type) = map.get("Node Type").and_then(|v| v.as_str()) {
                if node_type == "Seq Scan" || node_type == "Parallel Seq Scan" {
                    let relation = map
                        .get("Relation Name")
                        .and_then(|v| v.as_str())
                        .unwrap_or("unknown");
                    found.push(format!("{} on {}", node_type, relation));
                }
            }
            for v in map.values() {
                collect_seq_scan_nodes(v, found);
            }
        }
        serde_json::Value::Array(arr) => {
            for item in arr {
                collect_seq_scan_nodes(item, found);
            }
        }
        _ => {}
    }
}

// ============================================================================
// pg_stat_statements Helpers (Tier 2)
// ============================================================================

/// Statistics from pg_stat_statements for a matched query
///
/// Contains key performance metrics from the pg_stat_statements view.
/// See PostgreSQL documentation for pg_stat_statements column definitions.
#[derive(Debug, Clone)]
pub struct PgStatEntry {
    /// Number of times the query was executed
    pub calls: i64,
    /// Mean execution time in milliseconds
    pub mean_exec_time: f64,
    /// Population standard deviation of execution time in milliseconds
    pub stddev_exec_time: f64,
    /// Total execution time in milliseconds across all calls
    pub total_exec_time: f64,
    /// The normalized query string from pg_stat_statements
    pub query: String,
}

/// Ensure pg_stat_statements extension is available
///
/// Creates the extension if it doesn't exist. Should be called once
/// at the start of benchmark tests that need pg_stat_statements.
///
/// Requires `shared_preload_libraries=pg_stat_statements` in the PostgreSQL
/// server configuration (see docker-compose.yml).
pub async fn ensure_pg_stat_statements(pool: &PgPool) -> Result<()> {
    sqlx::query("CREATE EXTENSION IF NOT EXISTS pg_stat_statements")
        .execute(pool)
        .await
        .with_context(|| "creating pg_stat_statements extension")?;
    Ok(())
}

/// Reset all pg_stat_statements counters
///
/// Clears cumulative per-query statistics so the next sampling window starts
/// from zero. Call this before the measurement phase of a benchmark case to
/// ensure `read_pg_stat_statements` reflects only the queries executed after
/// the reset — not leftovers from prior cases or setup work.
///
/// Requires the `pg_stat_statements` extension to be loaded
/// (see `ensure_pg_stat_statements`).
///
/// # Example
/// ```ignore
/// ensure_pg_stat_statements(&pool).await?;
/// reset_pg_stat_statements(&pool).await?;
/// // ... run benchmark queries ...
/// let stats = read_pg_stat_statements(&pool, "%FROM bench%").await?;
/// ```
pub async fn reset_pg_stat_statements(pool: &PgPool) -> Result<()> {
    sqlx::query("SELECT pg_stat_statements_reset(NULL::oid, (SELECT oid FROM pg_database WHERE datname = current_database()), 0::bigint)")
        .execute(pool)
        .await
        .with_context(|| "resetting pg_stat_statements counters for current database")?;
    Ok(())
}

/// Read query statistics from pg_stat_statements
///
/// Looks up a query in the `pg_stat_statements` view using a SQL LIKE pattern.
/// Requires the `pg_stat_statements` extension to be loaded
/// (see `ensure_pg_stat_statements`).
///
/// # Arguments
/// * `pool` - Database connection pool
/// * `query_pattern` - SQL LIKE pattern to match against normalized query text
///   (e.g., `"%FROM ore WHERE%"`).
///   Note: `pg_stat_statements` normalizes queries by replacing literal values
///   with `$N` placeholders. Patterns must match the normalized form
///   (e.g., `"%FROM bench WHERE e = $1%"`, not `"%FROM bench WHERE e = 'abc'%"`).
///
/// # Returns
/// `PgStatEntry` for the matched query. Returns error if no match or multiple matches.
///
/// # Example
/// ```ignore
/// ensure_pg_stat_statements(&pool).await?;
/// let stats = read_pg_stat_statements(&pool, "%FROM ore WHERE%").await?;
/// assert!(stats.mean_exec_time < 5.0, "Query regression: {}ms", stats.mean_exec_time);
/// ```
pub async fn read_pg_stat_statements(pool: &PgPool, query_pattern: &str) -> Result<PgStatEntry> {
    let sql = "SELECT query, calls, mean_exec_time, stddev_exec_time, total_exec_time \
               FROM pg_stat_statements \
               WHERE query LIKE $1 \
               AND dbid = (SELECT oid FROM pg_database WHERE datname = current_database())";

    let rows: Vec<(String, i64, f64, f64, f64)> = sqlx::query_as(sql)
        .bind(query_pattern)
        .fetch_all(pool)
        .await
        .with_context(|| format!("reading pg_stat_statements for pattern: {}", query_pattern))?;

    match rows.len() {
        0 => Err(anyhow::anyhow!(
            "No pg_stat_statements entry found matching pattern: {}",
            query_pattern
        )),
        1 => {
            let (query, calls, mean_exec_time, stddev_exec_time, total_exec_time) =
                rows.into_iter().next().unwrap();
            Ok(PgStatEntry {
                calls,
                mean_exec_time,
                stddev_exec_time,
                total_exec_time,
                query,
            })
        }
        n => Err(anyhow::anyhow!(
            "Expected 1 pg_stat_statements entry but found {} matching pattern: {}",
            n,
            query_pattern
        )),
    }
}
