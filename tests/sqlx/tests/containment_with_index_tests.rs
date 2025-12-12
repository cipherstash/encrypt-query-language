//! Containment with index tests (@> and <@) for encrypted JSONB
//!
//! Tests cover all operator/type combinations in the coverage matrix:
//!
//! | Operator           | LHS          | RHS          | Test                            |
//! |--------------------|--------------|--------------|----------------------------------|
//! | jsonb_contains     | encrypted    | jsonb_param  | contains_encrypted_jsonb_param   |
//! | jsonb_contains     | encrypted    | encrypted    | contains_encrypted_encrypted     |
//! | jsonb_contains     | jsonb_param  | encrypted    | contains_jsonb_param_encrypted   |
//! | jsonb_contained_by | encrypted    | jsonb_param  | contained_by_encrypted_jsonb_param |
//! | jsonb_contained_by | encrypted    | encrypted    | contained_by_encrypted_encrypted |
//! | jsonb_contained_by | jsonb_param  | encrypted    | contained_by_jsonb_param_encrypted |
//!
//! Uses parameterized queries (jsonb_param) as the primary pattern since
//! that's what real clients use when integrating with EQL.
//!
//! Uses the ste_vec_vast table (500 rows) from migration 005_install_ste_vec_vast_data.sql

use anyhow::Result;
use eql_tests::{
    analyze_table, assert_uses_index, assert_uses_seq_scan, create_jsonb_gin_index, explain_query,
    get_ste_vec_encrypted, get_ste_vec_sv_element,
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

// ============================================================================
// Sanity Tests: Value Contains Itself (Exact Match)
// ============================================================================
//
// These tests verify basic functionality - a value trivially contains itself.
// They serve as sanity checks that the GIN index and containment functions work.

#[sqlx::test]
async fn sanity_before_after_index_creation(pool: PgPool) -> Result<()> {
    // Demonstrates GIN index impact: Seq Scan before, Index Scan after
    analyze_table(&pool, STE_VEC_VAST_TABLE).await?;

    let id = 1;
    let row = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    let sql = format!(
        "SELECT 1 FROM {} WHERE eql_v2.jsonb_array(e) @> eql_v2.jsonb_array('{}'::jsonb) LIMIT 1",
        STE_VEC_VAST_TABLE, row
    );

    // BEFORE: Without index, should use Seq Scan
    let explain_before = explain_query(&pool, &sql).await?;
    assert_uses_seq_scan(&explain_before);

    // Create the GIN index
    setup_ste_vec_vast_gin_index(&pool).await?;

    // AFTER: With index, should use the GIN index
    assert_uses_index(&pool, &sql, STE_VEC_VAST_GIN_INDEX).await?;

    Ok(())
}

#[sqlx::test]
async fn sanity_non_matching_returns_empty(pool: PgPool) -> Result<()> {
    // Non-existent value returns no results
    setup_ste_vec_vast_gin_index(&pool).await?;

    let sql = format!(
        "SELECT count(*) FROM {} WHERE eql_v2.jsonb_array(e) @> ARRAY['{{\"s\":\"nonexistent\",\"v\":1}}'::jsonb]",
        STE_VEC_VAST_TABLE
    );

    let count: (i64,) = sqlx::query_as(&sql).fetch_one(&pool).await?;
    assert_eq!(count.0, 0, "Expected no matches for non-existent selector");

    Ok(())
}

// ============================================================================
// Coverage Matrix Tests: All Operator/Type Combinations
// ============================================================================
//
// Each test covers exactly one operator/type combination.
// Uses parameterized queries (jsonb_param) as the primary pattern
// since that's what real clients use.

#[sqlx::test]
async fn contains_encrypted_jsonb_param(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contains(encrypted, jsonb_param)
    // Most common pattern - client sends jsonb parameter
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    let sv_element = get_ste_vec_sv_element(&pool, STE_VEC_VAST_TABLE, id, 0).await?;

    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contains(e, $1::jsonb) AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&sv_element)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "jsonb_contains(encrypted, jsonb_param) should find match"
    );
    assert_eq!(result.unwrap().0, id as i64);

    // Verify index usage with literal for EXPLAIN (can't EXPLAIN with params)
    let explain_sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contains(e, '{}'::jsonb) LIMIT 1",
        STE_VEC_VAST_TABLE, sv_element
    );
    assert_uses_index(&pool, &explain_sql, STE_VEC_VAST_GIN_INDEX).await?;

    Ok(())
}

#[sqlx::test]
async fn contains_encrypted_encrypted(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contains(encrypted, encrypted)
    // Encrypted column contains another encrypted value
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    // Get full encrypted value - should contain itself
    let encrypted = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    // Use parameterized query with encrypted value as jsonb
    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contains(e, $1::jsonb) AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&encrypted)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "jsonb_contains(encrypted, encrypted) should find match (value contains itself)"
    );
    assert_eq!(result.unwrap().0, id as i64);

    Ok(())
}

#[sqlx::test]
async fn contains_jsonb_param_encrypted(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contains(jsonb_param, encrypted)
    // Check if jsonb parameter contains the encrypted column
    // This is the inverse - rarely used but must work
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    // Get full encrypted value - it contains its own sv elements
    let encrypted = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    // Check if the full encrypted value (as param) contains the column
    // This should match because encrypted contains itself
    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contains($1::jsonb, e) AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&encrypted)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "jsonb_contains(jsonb_param, encrypted) should find match"
    );
    assert_eq!(result.unwrap().0, id as i64);

    Ok(())
}

#[sqlx::test]
async fn contains_encrypted_param_encrypted(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contains(encrypted_param, encrypted)
    // Check if encrypted parameter contains the encrypted column
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    // Get full encrypted value - it contains its own sv elements
    let encrypted_param = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    // Check if the encrypted value (as param) contains the column
    // Should match because encrypted contains itself
    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contains($1::jsonb, e) AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&encrypted_param)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "jsonb_contains(encrypted_param, encrypted) should find match"
    );
    assert_eq!(result.unwrap().0, id as i64);

    Ok(())
}

#[sqlx::test]
async fn contains_encrypted_encrypted_param(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contains(encrypted, encrypted_param)
    // Encrypted column contains an encrypted value passed as parameter
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    // Get full encrypted value to use as parameter
    let encrypted_param = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contains(e, $1::jsonb) AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&encrypted_param)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "jsonb_contains(encrypted, encrypted_param) should find match"
    );
    assert_eq!(result.unwrap().0, id as i64);

    Ok(())
}

// ============================================================================
// Helper Function Tests
// ============================================================================

#[sqlx::test]
async fn test_get_ste_vec_encrypted_returns_json_value(pool: PgPool) -> Result<()> {
    // Test that get_ste_vec_encrypted returns serde_json::Value
    let encrypted = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, 1).await?;

    // Should be an object with expected encrypted structure
    assert!(
        encrypted.is_object(),
        "encrypted value should be a JSON object"
    );
    assert!(
        encrypted.get("sv").is_some(),
        "encrypted value should have 'sv' field"
    );

    Ok(())
}

#[sqlx::test]
async fn test_get_ste_vec_sv_element_returns_json_value(pool: PgPool) -> Result<()> {
    // Test that get_ste_vec_sv_element returns serde_json::Value with expected fields
    let sv_element = get_ste_vec_sv_element(&pool, STE_VEC_VAST_TABLE, 1, 0).await?;

    // Should be an object with expected fields
    assert!(sv_element.is_object(), "sv element should be a JSON object");
    assert!(
        sv_element.get("s").is_some(),
        "sv element should have 's' (selector) field"
    );

    Ok(())
}

#[sqlx::test]
async fn contained_by_encrypted_jsonb_param(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contained_by(encrypted, jsonb_param)
    // Is encrypted column contained by the jsonb parameter?
    // True when param equals or is superset of encrypted
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    // Get full encrypted value - column is contained by itself
    let encrypted = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contained_by(e, $1::jsonb) AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&encrypted)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "jsonb_contained_by(encrypted, jsonb_param) should find match"
    );
    assert_eq!(result.unwrap().0, id as i64);

    Ok(())
}

#[sqlx::test]
async fn contained_by_encrypted_encrypted(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contained_by(encrypted, encrypted)
    // Is encrypted column contained by another encrypted value?
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    // Get full encrypted value - column is contained by itself
    let encrypted = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contained_by(e, $1::jsonb) AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&encrypted)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "jsonb_contained_by(encrypted, encrypted) should find match"
    );
    assert_eq!(result.unwrap().0, id as i64);

    Ok(())
}

#[sqlx::test]
async fn contained_by_encrypted_encrypted_param(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contained_by(encrypted, encrypted_param)
    // Is encrypted column contained by the encrypted parameter?
    // True when param equals or is superset of encrypted
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    // Get full encrypted value - column is contained by itself
    let encrypted_param = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contained_by(e, $1::jsonb) AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&encrypted_param)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "jsonb_contained_by(encrypted, encrypted_param) should find match"
    );
    assert_eq!(result.unwrap().0, id as i64);

    Ok(())
}

#[sqlx::test]
async fn contained_by_jsonb_param_encrypted(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contained_by(jsonb_param, encrypted)
    // Is jsonb parameter contained by the encrypted column?
    // Single sv element should be contained in the full encrypted value
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    let sv_element = get_ste_vec_sv_element(&pool, STE_VEC_VAST_TABLE, id, 0).await?;

    println!("\n=== contained_by_jsonb_param_encrypted ===");
    println!("Testing: jsonb_contained_by(jsonb_param, encrypted)");
    println!("Row ID: {}", id);
    println!("sv_element (jsonb_param): {}", serde_json::to_string_pretty(&sv_element)?);

    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contained_by($1::jsonb, e) AND id = $2",
        STE_VEC_VAST_TABLE
    );
    println!("SQL: {}", sql);

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&sv_element)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    println!("Result: {:?}", result);

    assert!(
        result.is_some(),
        "jsonb_contained_by(jsonb_param, encrypted) should find match"
    );
    assert_eq!(result.unwrap().0, id as i64);

    // Verify index usage
    let explain_sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contained_by('{}'::jsonb, e) LIMIT 1",
        STE_VEC_VAST_TABLE, sv_element
    );
    println!("EXPLAIN SQL: {}", explain_sql);

    let explain_output = crate::explain_query(&pool, &explain_sql).await?;
    println!("EXPLAIN output:\n{}", explain_output);

    assert_uses_index(&pool, &explain_sql, STE_VEC_VAST_GIN_INDEX).await?;
    println!("=== TEST PASSED ===\n");

    Ok(())
}

#[sqlx::test]
async fn contained_by_encrypted_param_encrypted(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contained_by(encrypted_param, encrypted)
    // Is encrypted parameter contained by the encrypted column?
    // True when column equals or is superset of parameter
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    // Get full encrypted value - parameter is contained by itself in column
    let encrypted_param = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contained_by($1::jsonb, e) AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&encrypted_param)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "jsonb_contained_by(encrypted_param, encrypted) should find match"
    );
    assert_eq!(result.unwrap().0, id as i64);

    Ok(())
}

// ============================================================================
// Macro-Based Coverage Matrix Tests
// ============================================================================
//
// These tests use a declarative macro pattern to generate containment tests
// for all operator/type combinations systematically.

/// Containment operator under test
#[derive(Debug, Clone, Copy)]
enum ContainmentOp {
    /// jsonb_contains(lhs, rhs) - LHS contains RHS
    Contains,
    /// jsonb_contained_by(lhs, rhs) - LHS is contained by RHS
    ContainedBy,
}

/// Argument type for LHS or RHS position in containment query
#[derive(Debug, Clone, Copy, PartialEq)]
enum ArgumentType {
    /// Table column reference: `e`
    EncryptedColumn,
    /// Full encrypted value as parameter: `$N::jsonb`
    EncryptedParam,
    /// Single sv element as parameter: `$N::jsonb`
    SvElementParam,
}

/// Test case configuration for containment operator tests
struct ContainmentTestCase {
    operator: ContainmentOp,
    lhs: ArgumentType,
    rhs: ArgumentType,
}

/// Generate a containment test from operator and argument types
macro_rules! containment_test {
    ($name:ident, op = $op:ident, lhs = $lhs:ident, rhs = $rhs:ident) => {
        #[sqlx::test]
        async fn $name(pool: PgPool) -> Result<()> {
            let test_case = ContainmentTestCase {
                operator: ContainmentOp::$op,
                lhs: ArgumentType::$lhs,
                rhs: ArgumentType::$rhs,
            };
            test_case.run(&pool, STE_VEC_VAST_TABLE, STE_VEC_VAST_GIN_INDEX).await
        }
    };
}

// First test: encrypted column contains encrypted parameter (self-containment)
containment_test!(
    macro_contains_encrypted_encrypted_param,
    op = Contains,
    lhs = EncryptedColumn,
    rhs = EncryptedParam
);
