//! Tier 1 benchmark plan assertions
//!
//! EXPLAIN-based tests asserting each P0/P1 query pattern uses the expected
//! index access method. Tests for known-broken patterns are marked #[ignore].
//!
//! ANALYZE is run by the bench_setup fixture — planner statistics are populated at fixture load.

use anyhow::Result;
use eql_tests::{
    assert_uses_index, explain_query, get_bench_encrypted_int, get_bench_encrypted_text,
};
use sqlx::PgPool;

const BENCH_INT_ORE_IDX: &str = "bench_int_ore_idx";
const BENCH_TEXT_HMAC_IDX: &str = "bench_text_hmac_idx";
const BENCH_TEXT_BLOOM_IDX: &str = "bench_text_bloom_idx";

/// ORE range query (less-than) uses btree index
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
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
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
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
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
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

/// Bare LIKE against an encrypted column engages the bloom_filter functional
/// index. Requires `~~` operator + `eql_v2.like` helper to both inline so the
/// planner reaches `bloom_filter(a) @> bloom_filter(b)`.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn bare_like_uses_bloom_index(pool: PgPool) -> Result<()> {
    let encrypted = get_bench_encrypted_text(&pool, 1).await?;

    let sql = format!(
        "SELECT * FROM bench WHERE encrypted_text ~~ '{}'::jsonb::eql_v2_encrypted",
        encrypted
    );
    assert_uses_index(&pool, &sql, BENCH_TEXT_BLOOM_IDX).await?;
    Ok(())
}

/// Bare ILIKE engages the bloom_filter functional index — same mechanism as `~~`.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn bare_ilike_uses_bloom_index(pool: PgPool) -> Result<()> {
    let encrypted = get_bench_encrypted_text(&pool, 1).await?;

    let sql = format!(
        "SELECT * FROM bench WHERE encrypted_text ~~* '{}'::jsonb::eql_v2_encrypted",
        encrypted
    );
    assert_uses_index(&pool, &sql, BENCH_TEXT_BLOOM_IDX).await?;
    Ok(())
}

// ============================================================================
// Hash-strategy plans: GROUP BY / JOIN / DISTINCT on encrypted columns engage
// the hash operator class (#196). The plan-shape assertions below cover the
// surface PR #196 enabled; the corresponding timing thresholds in
// bench_regression_tests.rs are #[ignore]'d pending the hash-chain inlining
// work tracked in #202.
// ============================================================================

/// `GROUP BY encrypted_col` engages HashAggregate via the hash operator class.
/// Without the hash op class registered in #196 this would fall back to
/// GroupAggregate-after-Sort or — worse — degenerate to a Nested-Loop self-comparison.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn group_by_encrypted_uses_hash_aggregate(pool: PgPool) -> Result<()> {
    let sql = "SELECT count(*) FROM bench GROUP BY encrypted_text";
    let plan = explain_query(&pool, sql).await?;
    assert!(
        plan.contains("HashAggregate"),
        "Expected GROUP BY to use HashAggregate. EXPLAIN output:\n{}",
        plan
    );
    Ok(())
}

/// JOIN on `a.encrypted_col = b.encrypted_col` engages the hmac functional index.
/// Acceptable plan shapes: Hash Join (preferred), or Nested Loop + Memoize +
/// Index Scan via `bench_text_hmac_idx` (current planner choice — fine since
/// the index lookup remains the per-probe cost).
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn join_on_encrypted_uses_hmac_index(pool: PgPool) -> Result<()> {
    let sql = "SELECT count(*) FROM bench a JOIN bench b \
               ON a.encrypted_text = b.encrypted_text";
    assert_uses_index(&pool, sql, BENCH_TEXT_HMAC_IDX).await?;
    Ok(())
}

/// `SELECT DISTINCT encrypted_col FROM t` (unbounded) engages HashAggregate
/// via the hash operator class. The bounded variant (`... LIMIT N`) biases
/// the planner toward Index Only Scan over the ORE btree opclass — that's
/// fine on full installs but unavailable on Supabase, where this hash path
/// becomes the only viable one.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn distinct_encrypted_uses_hash_aggregate(pool: PgPool) -> Result<()> {
    let sql = "SELECT DISTINCT encrypted_text FROM bench";
    let plan = explain_query(&pool, sql).await?;
    assert!(
        plan.contains("HashAggregate"),
        "Expected DISTINCT to use HashAggregate. EXPLAIN output:\n{}",
        plan
    );
    Ok(())
}

// ============================================================================
// Field-level hash-strategy: GROUP BY on a JSON path extracted from an
// encrypted column. This is the "how many users per region" pattern against
// ste_vec encryption.
//
// Uses the bench_json fixture, which overlays `hm` onto the `$.hello` sv
// element of each bench row — simulating what `@cipherstash/protect` produces
// for a JSONB column where the `$.hello` path is configured with a `unique`
// index. Without that overlay, field-level GROUP BY raises today
// ("Cannot hash eql_v2_encrypted value: no hmac_256 index term found").
// ============================================================================

/// Documented EQL form for field-level GROUP BY:
/// `GROUP BY eql_v2.jsonb_path_query_first(col, '<selector>')`.
/// The planner engages a parallel Partial HashAggregate + Sort + GroupAggregate
/// merge — i.e., `HashAggregate` appears in the plan even if it's not the top
/// node. The bare-`->` form (`col -> '<sel>'::text`) currently picks
/// Sort + GroupAggregate instead; once #204 inlines the extractors, the
/// planner has the option of flattening to a single HashAggregate.
#[sqlx::test(fixtures(
    path = "../fixtures",
    scripts("bench_data", "bench_setup", "bench_json_data")
))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn group_by_jsonb_field_uses_hash_aggregate(pool: PgPool) -> Result<()> {
    // Selectors::HELLO = $.hello — see tests/sqlx/src/selectors.rs.
    let sql = "SELECT count(*) FROM bench_json \
               GROUP BY eql_v2.jsonb_path_query_first(e, 'a7cea93975ed8c01f861ccb6bd082784')";
    let plan = explain_query(&pool, sql).await?;
    assert!(
        plan.contains("HashAggregate"),
        "Expected field-level GROUP BY plan to include a HashAggregate node. EXPLAIN output:\n{}",
        plan
    );
    Ok(())
}
