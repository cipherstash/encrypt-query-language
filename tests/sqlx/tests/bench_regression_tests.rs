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
// All three are #[ignore]'d pending the chain inlining tracked in #202.
// Thresholds are set to the post-inlining target (measured by patching the
// chain to LANGUAGE sql IMMUTABLE in-place: ~70ms for GROUP BY, ~182ms for
// the self-join, with consistent plan shapes). Remove the #[ignore] when #202
// merges and confirm green.
// ============================================================================

/// `GROUP BY encrypted_text` should be under 150ms at 10K rows.
/// Measured baseline today: ~309ms (HashAggregate + Seq Scan, plpgsql per-row
/// cost in hash_encrypted chain). Measured with chain inlined: ~70ms.
/// Threshold of 150ms is ~2× the inlined baseline to absorb CI variance.
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
        "GROUP BY encrypted_text took {:.1}ms, threshold 150ms (~70ms expected after #202, currently ~309ms, node_type={})",
        stats.execution_time_ms, stats.node_type
    );
    Ok(())
}

/// Self-join on `a.encrypted_text = b.encrypted_text` should be under 350ms at
/// 10K rows (which produces ~1M result rows due to ~99 distinct values × ~100
/// matches each — most of the time is intrinsic result cardinality, not the
/// per-probe cost).
/// Measured baseline today: ~308ms. Measured with chain inlined: ~182ms.
/// Threshold of 350ms catches a regression to seq scan (>1s) without flapping
/// on cardinality variance.
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
        "Self-join on encrypted_text took {:.1}ms, threshold 350ms (~182ms expected after #202, currently ~308ms, node_type={})",
        stats.execution_time_ms, stats.node_type
    );
    Ok(())
}

/// `SELECT DISTINCT encrypted_text` should be under 200ms at 10K rows once
/// HashAggregate becomes the planner choice (currently picks Index Only Scan
/// over the ORE btree opclass at ~132ms — usable but unavailable on Supabase).
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[ignore = "#202: hash_encrypted chain not yet inlined; remove ignore when #202 merges"]
async fn distinct_encrypted_under_threshold(pool: PgPool) -> Result<()> {
    let stats: ExplainStats =
        explain_analyze_avg(&pool, "SELECT DISTINCT encrypted_text FROM bench", 5).await?;
    assert!(
        stats.execution_time_ms < 200.0,
        "DISTINCT encrypted_text took {:.1}ms, threshold 200ms (currently ~132ms via ORE btree on full install; want HashAggregate-driven path post-#202, node_type={})",
        stats.execution_time_ms, stats.node_type
    );
    Ok(())
}
