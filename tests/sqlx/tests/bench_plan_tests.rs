//! Tier 1 benchmark plan assertions
//!
//! EXPLAIN-based tests asserting each P0/P1 query pattern uses the expected
//! index access method. Tests for known-broken patterns are marked #[ignore].
//!
//! ANALYZE is run by the bench_setup fixture — planner statistics are populated at fixture load.

use anyhow::Result;
use eql_tests::{assert_uses_index, get_bench_encrypted_int, get_bench_encrypted_text};
use sqlx::PgPool;

const BENCH_INT_ORE_IDX: &str = "bench_int_ore_idx";
const BENCH_TEXT_HMAC_IDX: &str = "bench_text_hmac_idx";

/// ORE range query (less-than) uses btree index
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
async fn ore_int_range_lt_uses_btree_index(pool: PgPool) -> Result<()> {
    let encrypted = get_bench_encrypted_int(&pool, 50).await?;

    let sql = format!(
        "SELECT * FROM bench WHERE encrypted_int < '{}'::jsonb::eql_v2_encrypted \
         ORDER BY encrypted_int LIMIT 10",
        encrypted
    );
    assert_uses_index(&pool, &sql, BENCH_INT_ORE_IDX).await?;
    Ok(())
}

/// ORE range query (greater-than) uses btree index
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
async fn ore_int_range_gt_uses_btree_index(pool: PgPool) -> Result<()> {
    let encrypted = get_bench_encrypted_int(&pool, 50).await?;

    let sql = format!(
        "SELECT * FROM bench WHERE encrypted_int > '{}'::jsonb::eql_v2_encrypted \
         ORDER BY encrypted_int LIMIT 10",
        encrypted
    );
    assert_uses_index(&pool, &sql, BENCH_INT_ORE_IDX).await?;
    Ok(())
}

/// ORE combined range (>= low AND <= high) uses btree index
///
/// Uses explicit >= / <= rather than BETWEEN — BETWEEN's operator resolution
/// against eql_v2_encrypted is untested and may not resolve to the btree family.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
async fn ore_int_range_combined_uses_btree_index(pool: PgPool) -> Result<()> {
    let low = get_bench_encrypted_int(&pool, 10).await?;
    let high = get_bench_encrypted_int(&pool, 90).await?;

    let sql = format!(
        "SELECT * FROM bench \
         WHERE encrypted_int >= '{}'::jsonb::eql_v2_encrypted \
           AND encrypted_int <= '{}'::jsonb::eql_v2_encrypted \
         ORDER BY encrypted_int LIMIT 10",
        low, high
    );
    assert_uses_index(&pool, &sql, BENCH_INT_ORE_IDX).await?;
    Ok(())
}

/// Equality on encrypted_text with `'...'::jsonb::eql_v2_encrypted` operand
/// uses the btree index (same-type `=` is an opfamily member).
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
async fn eql_cast_text_equality_uses_btree_index(pool: PgPool) -> Result<()> {
    let encrypted = get_bench_encrypted_text(&pool, 1).await?;

    let sql = format!(
        "SELECT * FROM bench WHERE encrypted_text = '{}'::jsonb::eql_v2_encrypted",
        encrypted
    );
    assert_uses_index(&pool, &sql, "bench_text_ore_idx").await?;
    Ok(())
}

/// Equality on encrypted_int with `'...'::jsonb::eql_v2_encrypted` operand
/// uses the btree index.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
async fn ore_equality_uses_btree_index(pool: PgPool) -> Result<()> {
    let encrypted = get_bench_encrypted_int(&pool, 1).await?;

    let sql = format!(
        "SELECT * FROM bench WHERE encrypted_int = '{}'::jsonb::eql_v2_encrypted",
        encrypted
    );
    assert_uses_index(&pool, &sql, BENCH_INT_ORE_IDX).await?;
    Ok(())
}

/// Equality on encrypted_int with bare `'...'::jsonb` operand (no second cast)
/// uses the btree index. Validates the cross-type opfamily registration in
/// `src/operators/cross_type_operator_class.sql`. Without it, this query falls
/// back to a parallel sequential scan because the `(eql_v2_encrypted, jsonb)`
/// `=` operator isn't an opfamily member.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
async fn ore_equality_with_bare_jsonb_uses_btree_index(pool: PgPool) -> Result<()> {
    let encrypted = get_bench_encrypted_int(&pool, 1).await?;

    let sql = format!(
        "SELECT * FROM bench WHERE encrypted_int = '{}'::jsonb",
        encrypted
    );
    assert_uses_index(&pool, &sql, BENCH_INT_ORE_IDX).await?;
    Ok(())
}

/// Range query on encrypted_int with bare `'...'::jsonb` operand uses the
/// btree index as an Index Cond (predicate pushdown), not just an Index Scan
/// + Filter. Without the cross-type opfamily entry the predicate would only
/// be applied as a row-level filter via ORDER BY traversal.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
async fn ore_range_with_bare_jsonb_uses_btree_index(pool: PgPool) -> Result<()> {
    let encrypted = get_bench_encrypted_int(&pool, 50).await?;

    let sql = format!(
        "SELECT * FROM bench WHERE encrypted_int > '{}'::jsonb \
         ORDER BY encrypted_int LIMIT 10",
        encrypted
    );
    assert_uses_index(&pool, &sql, BENCH_INT_ORE_IDX).await?;
    Ok(())
}
