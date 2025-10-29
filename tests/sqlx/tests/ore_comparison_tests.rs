//! ORE comparison variant tests
//!
//! Converted from src/operators/<=_ore_cllw_u64_8_test.sql
//! and src/operators/<=_ore_cllw_var_8_test.sql
//! Tests ORE CLLW comparison operators

use anyhow::{Context, Result};
use eql_tests::{get_ore_encrypted, QueryAssertion};
use sqlx::{PgPool, Row};

/// Helper to fetch ORE encrypted value as JSONB for comparison
///
/// This creates a JSONB value from the ore table that can be used with JSONB comparison
/// operators. The ore table values only contain {"ob": [...]}, so we merge in the required
/// "i" (index metadata) and "v" (version) fields to create a valid eql_v2_encrypted structure.
async fn get_ore_encrypted_as_jsonb(pool: &PgPool, id: i32) -> Result<String> {
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

#[sqlx::test]
async fn lte_operator_cllw_u64_8(pool: PgPool) -> Result<()> {
    // Test: <= operator with ORE CLLW U64 8
    // Original SQL lines 13-35 in src/operators/<=_ore_cllw_u64_8_test.sql
    // Uses ore table from migrations/002_install_ore_data.sql (ids 1-99)

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e <= '{}'::eql_v2_encrypted ORDER BY e",
        ore_term
    );

    // Should return 42 records (1-42 inclusive)
    QueryAssertion::new(&pool, &sql).count(42).await;

    Ok(())
}

#[sqlx::test]
async fn lte_function_cllw_u64_8(pool: PgPool) -> Result<()> {
    // Test: lte() function with ORE CLLW U64 8
    // Original SQL lines 37-42 in src/operators/<=_ore_cllw_u64_8_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE eql_v2.lte(e, '{}'::eql_v2_encrypted) ORDER BY e",
        ore_term
    );

    QueryAssertion::new(&pool, &sql).count(42).await;

    Ok(())
}

#[sqlx::test]
async fn lte_with_jsonb_cllw_u64_8(pool: PgPool) -> Result<()> {
    // Test: <= with JSONB (ORE CLLW U64 8)
    // Original SQL lines 44-56 in src/operators/<=_ore_cllw_u64_8_test.sql

    let json_value = get_ore_encrypted_as_jsonb(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e <= '{}'::jsonb ORDER BY e",
        json_value
    );

    QueryAssertion::new(&pool, &sql).count(42).await;

    Ok(())
}

#[sqlx::test]
async fn lte_operator_cllw_var_8(pool: PgPool) -> Result<()> {
    // Test: <= operator with ORE CLLW VAR 8
    // Original SQL lines 13-31 in src/operators/<=_ore_cllw_var_8_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e <= '{}'::eql_v2_encrypted ORDER BY e",
        ore_term
    );

    QueryAssertion::new(&pool, &sql).count(42).await;

    Ok(())
}

#[sqlx::test]
async fn lte_function_cllw_var_8(pool: PgPool) -> Result<()> {
    // Test: lte() function with ORE CLLW VAR 8
    // Original SQL lines 33-38 in src/operators/<=_ore_cllw_var_8_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE eql_v2.lte(e, '{}'::eql_v2_encrypted) ORDER BY e",
        ore_term
    );

    QueryAssertion::new(&pool, &sql).count(42).await;

    Ok(())
}

#[sqlx::test]
async fn lte_with_jsonb_cllw_var_8(pool: PgPool) -> Result<()> {
    // Test: <= with JSONB (ORE CLLW VAR 8)
    // Original SQL lines 40-52 in src/operators/<=_ore_cllw_var_8_test.sql

    let json_value = get_ore_encrypted_as_jsonb(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e <= '{}'::jsonb ORDER BY e",
        json_value
    );

    QueryAssertion::new(&pool, &sql).count(42).await;

    Ok(())
}
