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
#[cfg_attr(not(feature = "bench"), ignore = "perf-bench: gated, run via mise test:bench")]
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
#[cfg_attr(not(feature = "bench"), ignore = "perf-bench: gated, run via mise test:bench")]
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
#[cfg_attr(not(feature = "bench"), ignore = "perf-bench: gated, run via mise test:bench")]
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

/// eql_cast equality should use hash index — currently seq scans (CIP-2831)
///
/// "eql_cast" refers to the implicit JSONB-to-eql_v2_encrypted assignment cast
/// defined in `src/encrypted/casts.sql` (`CREATE CAST (jsonb AS eql_v2_encrypted)
/// WITH FUNCTION eql_v2.to_encrypted(jsonb)`). The SQL under test uses
/// `'...'::jsonb::eql_v2_encrypted`, which invokes that cast. PostgreSQL does not
/// recognise this cast path as equivalent to the indexed `hmac_256` term, so the
/// planner falls back to a sequential scan instead of using `bench_text_hmac_idx`.
///
/// Remove #[ignore] when eql_cast index usage is fixed. At 1M rows this query
/// takes 7.83s vs 0.4ms for hmac_256 — a 19,500x regression.
/// Passing with the 10K-row fixture confirms index usage — timing data above was measured at 1M rows.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[ignore = "CIP-2831: eql_cast equality performs full seq scan, no index used"]
async fn eql_cast_equality_uses_hash_index(pool: PgPool) -> Result<()> {
    let encrypted = get_bench_encrypted_text(&pool, 1).await?;

    let sql = format!(
        "SELECT * FROM bench WHERE encrypted_text = '{}'::jsonb::eql_v2_encrypted",
        encrypted
    );
    assert_uses_index(&pool, &sql, BENCH_TEXT_HMAC_IDX).await?;
    Ok(())
}

/// ORE equality via operator class should use btree — currently seq scans (CIP-2831)
///
/// Like `eql_cast_equality_uses_hash_index`, the SQL uses `'...'::jsonb::eql_v2_encrypted`
/// (the implicit JSONB assignment cast from `src/encrypted/casts.sql`). For integer
/// columns with ORE index terms the planner should satisfy equality via the btree
/// operator class, but the cast path prevents index recognition and causes a seq scan.
///
/// CIP-2831 covers both this and `eql_cast_equality_uses_hash_index` as a single root cause fix.
/// Remove #[ignore] when ORE equality index usage is fixed. At 1M rows this
/// query takes 18.47s vs 0.4ms for hmac_256.
/// Passing with the 10K-row fixture confirms index usage — timing data above was measured at 1M rows.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[ignore = "CIP-2831: ORE equality via operator class performs full seq scan"]
async fn ore_equality_uses_btree_index(pool: PgPool) -> Result<()> {
    let encrypted = get_bench_encrypted_int(&pool, 1).await?;

    let sql = format!(
        "SELECT * FROM bench WHERE encrypted_int = '{}'::jsonb::eql_v2_encrypted",
        encrypted
    );
    assert_uses_index(&pool, &sql, BENCH_INT_ORE_IDX).await?;
    Ok(())
}
