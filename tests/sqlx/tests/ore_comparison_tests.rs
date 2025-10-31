//! ORE comparison variant tests
//!
//! and src/operators/<=_ore_cllw_var_8_test.sql
//! Tests ORE CLLW comparison operators

use anyhow::Result;
use eql_tests::{get_ore_encrypted, get_ore_encrypted_as_jsonb, QueryAssertion};
use sqlx::PgPool;

#[sqlx::test]
async fn lte_operator_cllw_u64_8(pool: PgPool) -> Result<()> {
    // Test: <= operator with ORE CLLW U64 8
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

    let json_value = get_ore_encrypted_as_jsonb(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e <= '{}'::jsonb ORDER BY e",
        json_value
    );

    QueryAssertion::new(&pool, &sql).count(42).await;

    Ok(())
}
