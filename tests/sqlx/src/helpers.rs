//! Test helper functions for EQL tests
//!
//! Common utilities for working with encrypted data in tests.

use anyhow::{Context, Result};
use serde_json;
use sqlx::{PgPool, Row};

/// Fetch ORE encrypted value from pre-seeded ore table
///
/// The ore table is created by migration `002_install_ore_data.sql`
/// and contains 99 pre-seeded records (ids 1-99) for testing.
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

/// Fetch ORE encrypted value as JSONB for comparison
///
/// This creates a JSONB value from the ore table that can be used with JSONB comparison
/// operators. The ore table values only contain {"ob": [...]}, so we merge in the required
/// "i" (index metadata) and "v" (version) fields to create a valid eql_v2_encrypted structure.
pub async fn get_ore_encrypted_as_jsonb(pool: &PgPool, id: i32) -> Result<String> {
    let sql = format!(
        "SELECT (e::jsonb || jsonb_build_object('i', jsonb_build_object('t', 'ore'), 'v', 2))::text FROM ore WHERE id = {}",
        id
    );

    let row = sqlx::query(&sql)
        .fetch_one(pool)
        .await
        .with_context(|| format!("fetching ore encrypted as jsonb for id={}", id))?;

    let result: Option<String> = row
        .try_get(0)
        .with_context(|| format!("extracting jsonb text for id={}", id))?;

    result.with_context(|| format!("ore table returned NULL for id={}", id))
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
/// * `query` - SQL query to explain (without EXPLAIN prefix)
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
