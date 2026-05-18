//! ORE equality/inequality operator tests
//!
//! Tests range comparisons against the consolidated ORE schemes (Block ORE for
//! root scalars, ORE CLLW for STE-vec elements). Uses the ore table from
//! `migrations/002_install_ore_data.sql` (ids 1-1000) — those rows carry Block
//! ORE (`ob`) terms, so the range operators dispatch to
//! `eql_v2.compare_ore_block_u64_8_256` at the top of the compare priority
//! list.
//!
//! Post-consolidation the previously-split CLLW variants (`ore_cllw_u64_8`,
//! `ore_cllw_var_8`) collapse to a single `eql_v2.ore_cllw` reading from `oc`.
//! The duplicated test pair (fixed vs var) was therefore merged; the single
//! set below covers the operator surface end-to-end.

use anyhow::Result;
use eql_tests::{get_ore_encrypted, QueryAssertion};
use sqlx::PgPool;

// Equality / inequality removed: post-discipline, `=` and `<>` on
// `eql_v2_encrypted` require hmac at the root. The `ore` table fixtures
// carry only ORE terms (no hmac), so they are eligible for `<` / `<=` /
// `>` / `>=` (covered below) but not `=` / `<>`. ORE-only equality has no
// production analogue — equality is configured via the `unique` index,
// ordering via `ore`.

#[sqlx::test]
async fn ore_cllw_less_than(pool: PgPool) -> Result<()> {
    let encrypted = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e < '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(41).await;

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_less_than_or_equal(pool: PgPool) -> Result<()> {
    let encrypted = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e <= '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(42).await;

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_greater_than(pool: PgPool) -> Result<()> {
    let encrypted = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e > '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(958).await;

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_greater_than_or_equal(pool: PgPool) -> Result<()> {
    let encrypted = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e >= '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(959).await;

    Ok(())
}
