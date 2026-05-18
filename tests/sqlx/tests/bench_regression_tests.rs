//! Tier 1 benchmark magnitude regression tests
//!
//! Asserts execution time stays under generous thresholds to catch catastrophic regressions
//! while tolerating CI runner variance. Most thresholds are ~100x the expected baseline;
//! ore_order_by uses 4x (543ms observed baseline leaves little headroom for a 100x multiple
//! without creating a test that never fails).
//! Uses EXPLAIN ANALYZE averaged over 5 runs for server-side timing.
//!
//! Patterns known to be broken (P0 seq scans) are NOT included here — encoding
//! bad performance as "acceptable" defeats the purpose. See bench_plan_tests.rs
//! for their #[ignore] plan assertions.

use anyhow::Result;
use eql_tests::{
    explain_analyze_avg, get_bench_encrypted_int, get_bench_encrypted_text, ExplainStats,
};
use sqlx::PgPool;

/// hmac_256 equality must stay under 50ms on 10K rows (expected ~0.5ms)
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn hmac_equality_under_threshold(pool: PgPool) -> Result<()> {
    // id=1 maps to 1 of 100 distinct values → ~100 matching rows at 10K
    let encrypted = get_bench_encrypted_text(&pool, 1).await?;

    let sql = format!(
        "SELECT * FROM bench WHERE eql_v2.hmac_256(encrypted_text) = eql_v2.hmac_256('{}'::jsonb::eql_v2_encrypted)",
        encrypted
    );
    let stats: ExplainStats = explain_analyze_avg(&pool, &sql, 5).await?;
    assert!(
        stats.execution_time_ms < 50.0,
        "hmac_256 equality took {:.1}ms, threshold 50ms (expected ~0.5ms at 10K rows, node_type={})",
        stats.execution_time_ms, stats.node_type
    );
    Ok(())
}

/// bloom_filter containment must stay under 100ms on 10K rows (expected ~1ms)
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn bloom_filter_containment_under_threshold(pool: PgPool) -> Result<()> {
    // id=1 maps to 1 of 100 distinct values → ~100 matching rows at 10K
    let encrypted = get_bench_encrypted_text(&pool, 1).await?;

    let sql = format!(
        "SELECT * FROM bench WHERE eql_v2.bloom_filter(encrypted_text) @> eql_v2.bloom_filter('{}'::jsonb::eql_v2_encrypted)",
        encrypted
    );
    let stats: ExplainStats = explain_analyze_avg(&pool, &sql, 5).await?;
    assert!(
        stats.execution_time_ms < 100.0,
        "bloom_filter containment took {:.1}ms, threshold 100ms (expected ~1ms at 10K rows, node_type={})",
        stats.execution_time_ms, stats.node_type
    );
    Ok(())
}

/// ORE range query (< LIMIT 10) must stay under 200ms on 10K rows (expected ~2ms)
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn ore_range_lt_under_threshold(pool: PgPool) -> Result<()> {
    // id=50 is the bench row midpoint; encrypted_int uses a +33 offset so this maps
    // to ore id 83, but the 10K distribution still yields ~4,900 rows below the predicate
    let encrypted = get_bench_encrypted_int(&pool, 50).await?;

    let sql = format!(
        "SELECT * FROM bench WHERE encrypted_int < '{}'::jsonb::eql_v2_encrypted \
         ORDER BY encrypted_int LIMIT 10",
        encrypted
    );
    let stats: ExplainStats = explain_analyze_avg(&pool, &sql, 5).await?;
    assert!(
        stats.execution_time_ms < 200.0,
        "ORE range < LIMIT 10 took {:.1}ms, threshold 200ms (expected ~2ms at 10K rows, node_type={})",
        stats.execution_time_ms, stats.node_type
    );
    Ok(())
}

/// ORE ORDER BY LIMIT 10 must stay under 2000ms on 10K rows
///
/// The design doc's observed baseline for this pattern is ~543ms at 10K rows
/// ("Full-set comparison before sort"). Threshold is set at 2000ms — 4x the
/// observed baseline — to absorb CI variance while catching catastrophic regressions.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn ore_order_by_under_threshold(pool: PgPool) -> Result<()> {
    let stats: ExplainStats = explain_analyze_avg(
        &pool,
        "SELECT * FROM bench ORDER BY encrypted_int LIMIT 10",
        5,
    )
    .await?;
    assert!(
        stats.execution_time_ms < 2000.0,
        "ORE ORDER BY LIMIT 10 took {:.1}ms, threshold 2000ms (observed ~543ms baseline at 10K rows, node_type={})",
        stats.execution_time_ms, stats.node_type
    );
    Ok(())
}

// ============================================================================
// Hash-strategy timing regressions: GROUP BY / JOIN / DISTINCT on encrypted
// columns. The plan shapes already engage the hash operator class (#196), but
// per-row cost is dominated by plpgsql call overhead in the
// `hash_encrypted` → `to_ste_vec_value` → `hmac_256` chain.
//
// All three are #[ignore]'d pending the hash_encrypted fast-path tracked in
// #202. The dominant cost on these queries isn't plpgsql call overhead (a
// naive plpgsql → LANGUAGE sql conversion of the existing body leaves them
// effectively unchanged); it's `to_ste_vec_value`'s per-row JSONB inspection
// and reconstruction. The #202 fix short-circuits via root-level `hm`
// (`coalesce(val.data ->> 'hm', ...)`), falling through to `to_ste_vec_value`
// only for single-element ste_vec-wrapped payloads. Thresholds below reflect
// measured numbers with that fast-path applied in-place. Remove the
// `#[ignore]` markers when #202 merges and confirm green.
// ============================================================================

/// `GROUP BY encrypted_text` should be under 150ms at 10K rows.
/// Measured baseline today: ~309ms (HashAggregate + Seq Scan, dominated by
/// per-row `to_ste_vec_value` cost in the hash_encrypted chain). Measured
/// with the #202 fast-path applied: ~73ms. Threshold of 150ms is ~2x the
/// fast-path number to absorb CI variance.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[ignore = "#202: hash_encrypted chain not yet inlined; remove ignore when #202 merges"]
async fn group_by_encrypted_under_threshold(pool: PgPool) -> Result<()> {
    let stats: ExplainStats = explain_analyze_avg(
        &pool,
        "SELECT count(*) FROM bench GROUP BY encrypted_text",
        5,
    )
    .await?;
    assert!(
        stats.execution_time_ms < 150.0,
        "GROUP BY encrypted_text took {:.1}ms, threshold 150ms (~73ms expected after #202 fast-path, currently ~309ms, node_type={})",
        stats.execution_time_ms, stats.node_type
    );
    Ok(())
}

/// Self-join on `a.encrypted_text = b.encrypted_text` should be under 350ms at
/// 10K rows (which produces ~1M result rows due to ~99 distinct values × ~100
/// matches each — most of the time is intrinsic result cardinality, not the
/// per-probe cost).
/// Measured baseline today: ~308ms. Measured with the #202 fast-path applied:
/// ~185ms. Threshold of 350ms catches a regression to seq scan (>1s) without
/// flapping on cardinality variance.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[ignore = "#202: hash_encrypted chain not yet inlined; remove ignore when #202 merges"]
async fn self_join_encrypted_under_threshold(pool: PgPool) -> Result<()> {
    let stats: ExplainStats = explain_analyze_avg(
        &pool,
        "SELECT count(*) FROM bench a JOIN bench b ON a.encrypted_text = b.encrypted_text",
        3,
    )
    .await?;
    assert!(
        stats.execution_time_ms < 350.0,
        "Self-join on encrypted_text took {:.1}ms, threshold 350ms (~185ms expected after #202 fast-path, currently ~308ms, node_type={})",
        stats.execution_time_ms, stats.node_type
    );
    Ok(())
}

/// Unbounded `SELECT DISTINCT encrypted_text` should be under 200ms at 10K rows.
/// Measured baseline today: ~515ms (HashAggregate over plpgsql hash_encrypted
/// chain). Measured with the #202 fast-path applied (`coalesce(val.data ->>
/// 'hm', ...)`): ~72ms. Threshold of 200ms is ~2.8x the fast-path number to
/// absorb CI variance.
///
/// (The `... LIMIT N` variant biases the planner toward Index Only Scan over
/// the ORE btree opclass — fine on full installs but unavailable on Supabase.
/// This test exercises the unbounded path that engages HashAggregate.)
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[ignore = "#202: hash_encrypted chain not yet inlined; remove ignore when #202 merges"]
async fn distinct_encrypted_under_threshold(pool: PgPool) -> Result<()> {
    let stats: ExplainStats =
        explain_analyze_avg(&pool, "SELECT DISTINCT encrypted_text FROM bench", 5).await?;
    assert!(
        stats.execution_time_ms < 200.0,
        "DISTINCT encrypted_text took {:.1}ms, threshold 200ms (~72ms expected after #202 fast-path, currently ~515ms, node_type={})",
        stats.execution_time_ms, stats.node_type
    );
    Ok(())
}

/// Field-level `GROUP BY eql_v2.jsonb_path_query_first(col, '<selector>')` —
/// the canonical pattern for "count rows per JSON field value" against an
/// encrypted column where the field has a `unique` index configured.
///
/// Closing #202 (hash_encrypted fast-path) helps but doesn't fully solve this:
/// the dominant cost shifts to `jsonb_path_query_first`'s per-row plpgsql
/// overhead. The threshold below reflects what becomes achievable once #204
/// inlines the JSONB field extractors.
///
/// Measured at 10K rows on a synthesized fixture with `hm` overlaid at
/// $.hello: current main ~496ms, with #202 fast-path applied ~234ms, with
/// raw JSONB extraction bypass (proxy-emitted, no eql_v2 plpgsql in the
/// hot path) ~7ms. Threshold of 50ms is set near the bypass number — when
/// #204 inlines the extractors, the EQL form should converge on the same
/// ballpark.
#[sqlx::test(fixtures(
    path = "../fixtures",
    scripts("bench_data", "bench_setup", "bench_json_data")
))]
#[ignore = "#204: JSONB field extractors not yet inlined; remove ignore when #204 merges"]
async fn group_by_jsonb_field_under_threshold(pool: PgPool) -> Result<()> {
    let sql = "SELECT count(*) FROM bench_json \
               GROUP BY eql_v2.jsonb_path_query_first(e, 'a7cea93975ed8c01f861ccb6bd082784')";
    let stats: ExplainStats = explain_analyze_avg(&pool, sql, 5).await?;
    assert!(
        stats.execution_time_ms < 50.0,
        "GROUP BY field-level jsonb_path_query_first took {:.1}ms, threshold 50ms (~7ms achievable with full extractor inlining + #202, currently ~496ms on main, ~234ms with #202 fast-path only, node_type={})",
        stats.execution_time_ms, stats.node_type
    );
    Ok(())
}
