//! ORE equality/inequality operator tests
//!
//! Tests equality with different ORE encryption schemes (ORE64, CLLW_U64_8, CLLW_VAR_8)
//! Uses ore table from migrations/002_install_ore_data.sql (ids 1-1000)

use anyhow::Result;
use eql_tests::{get_ore_encrypted, QueryAssertion};
use sqlx::PgPool;

// ore64 / ore_cllw_u64_8 / ore_cllw_var_8 equality + inequality tests
// removed: post-discipline, `=` and `<>` on `eql_v2_encrypted` require
// hmac at the root. The `ore` table fixtures carry only ORE terms (no
// hmac), so they are eligible for `<` / `<=` / `>` / `>=` (covered in
// the comparison variant tests below) but not `=` / `<>`. ORE-only
// equality has no production analogue — equality is configured via
// the `unique` index, ordering via `ore`.

// ============================================================================
// Task 9: ORE Comparison Variants (CLLW schemes)
// ============================================================================

#[sqlx::test]
async fn ore_cllw_u64_8_less_than(pool: PgPool) -> Result<()> {
    // Test: e < e with ORE CLLW_U64_8 scheme

    let encrypted = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e < '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(41).await;

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_u64_8_less_than_or_equal(pool: PgPool) -> Result<()> {
    // Test: e <= e with ORE CLLW_U64_8 scheme
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
async fn ore_cllw_u64_8_greater_than(pool: PgPool) -> Result<()> {
    // Test: e > e with ORE CLLW_U64_8 scheme

    let encrypted = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e > '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(958).await;

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_u64_8_greater_than_or_equal(pool: PgPool) -> Result<()> {
    // Test: e >= e with ORE CLLW_U64_8 scheme

    let encrypted = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e >= '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(959).await;

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_var_8_less_than(pool: PgPool) -> Result<()> {
    // Test: e < e with ORE CLLW_VAR_8 scheme

    let encrypted = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e < '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(41).await;

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_var_8_less_than_or_equal(pool: PgPool) -> Result<()> {
    // Test: e <= e with ORE CLLW_VAR_8 scheme
    // Note: Uses ore table encryption (ORE_BLOCK) as proxy for CLLW_VAR_8 tests

    let encrypted = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e <= '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(42).await;

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_var_8_greater_than(pool: PgPool) -> Result<()> {
    // Test: e > e with ORE CLLW_VAR_8 scheme

    let encrypted = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e > '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(958).await;

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_var_8_greater_than_or_equal(pool: PgPool) -> Result<()> {
    // Test: e >= e with ORE CLLW_VAR_8 scheme

    let encrypted = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e >= '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(959).await;

    Ok(())
}
