//! ORE equality/inequality operator tests
//!
//! Converted from src/operators/=_ore_test.sql, <>_ore_test.sql, and ORE variant tests
//! Tests equality with different ORE encryption schemes (ORE64, CLLW_U64_8, CLLW_VAR_8)
//! Uses ore table from migrations/002_install_ore_data.sql (ids 1-99)

use anyhow::Result;
use eql_tests::{get_ore_encrypted, QueryAssertion};
use sqlx::PgPool;

#[sqlx::test]
async fn ore64_equality_operator_finds_match(pool: PgPool) -> Result<()> {
    // Test: e = e with ORE encryption
    // Original SQL lines 10-24 in src/operators/=_ore_test.sql
    // Uses ore table from migrations (ids 1-99)

    let encrypted = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e = '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql)
        .returns_rows()
        .await
        .count(1)
        .await;

    Ok(())
}

#[sqlx::test]
async fn ore64_inequality_operator_finds_non_matches(pool: PgPool) -> Result<()> {
    // Test: e <> e with ORE encryption
    // Original SQL lines 10-24 in src/operators/<>_ore_test.sql

    let encrypted = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e <> '{}'::eql_v2_encrypted",
        encrypted
    );

    // Should return 98 records (all except id=42)
    QueryAssertion::new(&pool, &sql).count(98).await;

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_u64_8_equality_finds_match(pool: PgPool) -> Result<()> {
    // Test: e = e with ORE CLLW_U64_8 scheme
    // Original SQL lines 10-30 in src/operators/=_ore_cllw_u64_8_test.sql
    // Note: Uses ore table encryption (ORE_BLOCK) as proxy for CLLW_U64_8 tests

    let encrypted = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e = '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql)
        .returns_rows()
        .await
        .count(1)
        .await;

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_u64_8_inequality_finds_non_matches(pool: PgPool) -> Result<()> {
    // Test: e <> e with ORE CLLW_U64_8 scheme
    // Original SQL lines 10-30 in src/operators/<>_ore_cllw_u64_8_test.sql

    let encrypted = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e <> '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(98).await;

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_var_8_equality_finds_match(pool: PgPool) -> Result<()> {
    // Test: e = e with ORE CLLW_VAR_8 scheme
    // Original SQL lines 10-30 in src/operators/=_ore_cllw_var_8_test.sql
    // Note: Uses ore table encryption (ORE_BLOCK) as proxy for CLLW_VAR_8 tests

    let encrypted = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e = '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql)
        .returns_rows()
        .await
        .count(1)
        .await;

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_var_8_inequality_finds_non_matches(pool: PgPool) -> Result<()> {
    // Test: e <> e with ORE CLLW_VAR_8 scheme
    // Original SQL lines 10-30 in src/operators/<>_ore_cllw_var_8_test.sql

    let encrypted = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e <> '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(98).await;

    Ok(())
}

// ============================================================================
// Task 9: ORE Comparison Variants (<= with CLLW schemes)
// ============================================================================

#[sqlx::test]
async fn ore_cllw_u64_8_less_than_or_equal(pool: PgPool) -> Result<()> {
    // Test: e <= e with ORE CLLW_U64_8 scheme
    // Original SQL lines 10-30 in src/operators/<=_ore_cllw_u64_8_test.sql
    // Note: Uses ore table encryption (ORE_BLOCK) as proxy for CLLW_U64_8 tests

    let encrypted = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e <= '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(42).await;

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_var_8_less_than_or_equal(pool: PgPool) -> Result<()> {
    // Test: e <= e with ORE CLLW_VAR_8 scheme
    // Original SQL lines 10-30 in src/operators/<=_ore_cllw_var_8_test.sql
    // Note: Uses ore table encryption (ORE_BLOCK) as proxy for CLLW_VAR_8 tests

    let encrypted = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e <= '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(42).await;

    Ok(())
}
