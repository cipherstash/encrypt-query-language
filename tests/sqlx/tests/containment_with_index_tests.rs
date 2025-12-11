//! Containment with index tests (@> and <@) for encrypted JSONB
//!
//! Tests that encrypted JSONB containment operations work correctly with
//! GIN indexes using the jsonb_array() function which returns jsonb[] arrays.
//!
//! The jsonb_array approach leverages PostgreSQL's native hash support for jsonb
//! elements, enabling efficient GIN indexed containment queries at scale.
//!
//! Uses the ste_vec_vast table (500 rows) from migration 005_install_ste_vec_vast_data.sql

use anyhow::Result;
use eql_tests::{
    analyze_table, assert_uses_index, create_jsonb_gin_index, get_ste_vec_encrypted,
};
use sqlx::PgPool;

// Constants for ste_vec_vast table testing
const STE_VEC_VAST_TABLE: &str = "ste_vec_vast";
const STE_VEC_VAST_GIN_INDEX: &str = "ste_vec_vast_gin_idx";

// ============================================================================
// GIN Index Helper Functions
// ============================================================================

/// Setup GIN index on ste_vec_vast table for testing
///
/// Creates the GIN index and runs ANALYZE to ensure query planner
/// has accurate statistics.
async fn setup_ste_vec_vast_gin_index(pool: &PgPool) -> Result<()> {
    create_jsonb_gin_index(pool, STE_VEC_VAST_TABLE, STE_VEC_VAST_GIN_INDEX).await?;
    analyze_table(pool, STE_VEC_VAST_TABLE).await?;
    Ok(())
}


/// Assert that a containment query returns at least one row
///
/// # Arguments
/// * `pool` - Database connection pool
/// * `sql` - SQL query with `{}` placeholder for the encrypted value
/// * `value` - Encrypted value to substitute into the query
///
/// # Example
/// ```ignore
/// let sql = "SELECT 1 FROM t WHERE eql_v2.ste_vec(e) @> eql_v2.ste_vec('{}'::eql_v2_encrypted) LIMIT 1";
/// assert_contains(&pool, sql, &row_b).await?;
/// ```
async fn assert_contains(pool: &PgPool, sql: &str) -> Result<()> {
    let result: Option<(i32,)> = sqlx::query_as(&sql).fetch_optional(pool).await?;
    assert!(
        result.is_some(),
        "containment check failed - no rows returned: {}",
        sql
    );
    Ok(())
}

// ============================================================================
// Two-Value Containment Tests (from legacy @>_test.sql)
// ============================================================================

#[sqlx::test]
async fn jsonb_identical_values_contain_each_other_uses_index(pool: PgPool) -> Result<()> {
    // Test: GIN indexed ste_vec containment with identical values
    //
    // 1. Create GIN index on eql_v2.ste_vec(e)
    // 2. Verify contains operator returns true
    // 3. Verify index is used via EXPLAIN
    //
    // Uses ste_vec_vast table (500 rows) from migration 005_install_ste_vec_vast_data.sql
    // The dataset size ensures PostgreSQL's query planner naturally chooses the GIN index
    // over sequential scan without needing to disable seqscan.
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;

    // Fetch a record to use as the containment target
    let row_b = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    // println!("{}", row_b);

    // Test containment: a @> b using jsonb_array arrays (jsonb[] has native GIN support)
    // SQL has containment in WHERE clause so GIN index can be used
    let sql = format!(
        "SELECT 1 FROM {} WHERE eql_v2.jsonb_array(e) @> eql_v2.jsonb_array('{}'::eql_v2_encrypted) LIMIT 1",
        STE_VEC_VAST_TABLE, row_b
    );

    assert_contains(&pool, &sql).await?;
    assert_uses_index(&pool, &sql, STE_VEC_VAST_GIN_INDEX).await?;

    Ok(())
}

#[sqlx::test]
async fn jsonb_contains_helper_uses_index(pool: PgPool) -> Result<()> {
    // Test: The jsonb_contains helper function with GIN index
    //
    // Verifies that the convenience wrapper function works correctly
    // and the underlying query uses the GIN index.
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    let row_b = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    // Test using the helper function
    let sql = format!(
        "SELECT 1 FROM {} WHERE eql_v2.jsonb_contains(e, '{}'::eql_v2_encrypted) LIMIT 1",
        STE_VEC_VAST_TABLE, row_b
    );

    assert_contains(&pool, &sql).await?;
    assert_uses_index(&pool, &sql, STE_VEC_VAST_GIN_INDEX).await?;

    Ok(())
}

#[sqlx::test]
async fn jsonb_array_containment_multiple_rows(pool: PgPool) -> Result<()> {
    // Test: Verify containment works for multiple different rows
    //
    // Tests that several different rows can find themselves via containment,
    // ensuring the GIN index works across the dataset.
    setup_ste_vec_vast_gin_index(&pool).await?;

    // Test several different rows across the 500-row dataset
    // Selected IDs test distribution across dataset: beginning (1), sparse early (5, 10),
    // mid-range powers of ten (50, 100), near-end (250), and end (499)
    for id in [1, 5, 10, 50, 100, 250, 499] {
        let row = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

        let sql = format!(
            "SELECT 1 FROM {} WHERE eql_v2.jsonb_array(e) @> eql_v2.jsonb_array('{}'::eql_v2_encrypted) LIMIT 1",
            STE_VEC_VAST_TABLE, row
        );

        assert_contains(&pool, &sql).await?;
    }

    Ok(())
}

#[sqlx::test]
async fn jsonb_array_non_matching_returns_empty(pool: PgPool) -> Result<()> {
    // Test: Non-matching value returns no results
    //
    // Verifies that searching for a non-existent value correctly returns empty.
    setup_ste_vec_vast_gin_index(&pool).await?;

    // Create a fake encrypted value that won't match anything
    // We'll use a modified version of an existing row
    let sql = format!(
        "SELECT count(*) FROM {} WHERE eql_v2.jsonb_array(e) @> ARRAY['{{\"s\":\"nonexistent\",\"v\":1}}'::jsonb]",
        STE_VEC_VAST_TABLE
    );

    let count: (i64,) = sqlx::query_as(&sql).fetch_one(&pool).await?;
    assert_eq!(count.0, 0, "Expected no matches for non-existent selector");

    Ok(())
}

#[sqlx::test]
async fn jsonb_array_count_with_index(pool: PgPool) -> Result<()> {
    // Test: Count query uses GIN index efficiently
    //
    // Verifies that counting matches also uses the index.
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    let row = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    let sql = format!(
        "SELECT count(*) FROM {} WHERE eql_v2.jsonb_array(e) @> eql_v2.jsonb_array('{}'::eql_v2_encrypted)",
        STE_VEC_VAST_TABLE, row
    );

    let count: (i64,) = sqlx::query_as(&sql).fetch_one(&pool).await?;
    // Should find at least one match (the row itself)
    assert!(count.0 >= 1, "Expected at least one match, got {}", count.0);

    // Verify index is used for count queries too
    assert_uses_index(&pool, &sql, STE_VEC_VAST_GIN_INDEX).await?;

    Ok(())
}
