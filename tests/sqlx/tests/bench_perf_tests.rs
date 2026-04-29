//! Tier 2 scheduled benchmarks.
//!
//! All tests are marked #[ignore] so regular CI doesn't run them. The scheduled
//! workflow in .github/workflows/benchmark.yml invokes the orchestrator:
//! `cargo test --test bench_perf_tests run_all_benchmarks -- --ignored`.
//!
//! Unlike Tier 1 tests, these use #[tokio::test] with a manual pool connected
//! via DATABASE_URL against a pre-loaded 100K-row dataset (set by `mise run bench:full`).
//!
//! Each benchmark:
//!   1. Resets pg_stat_statements
//!   2. Captures the actual query plan via EXPLAIN (FORMAT JSON)
//!   3. Runs its query pattern `RUNS` times (currently 10)
//!   4. Reads pg_stat_statements for the match
//!   5. Appends a PerfResult to the shared accumulator
//!
//! The `run_all_benchmarks` orchestrator invokes each benchmark helper in
//! sequence and then calls `flush_reports` to write JSON + Markdown. Individual
//! `#[tokio::test] #[ignore]` wrappers are retained so developers can run a
//! single benchmark in isolation, but they do NOT write reports (the
//! orchestrator owns report emission).

use anyhow::Result;
use eql_tests::{
    append_result, ensure_pg_stat_statements, fetch_plan_node_type, read_pg_stat_statements,
    reset_pg_stat_statements, write_reports, PerfResult,
};
use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;

const RUNS: i64 = 10;
const DATASET_ROWS: i64 = 100_000;

async fn connect() -> Result<PgPool> {
    let url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set (run `mise run bench:full`)");
    let pool = PgPoolOptions::new()
        .max_connections(4)
        .connect(&url)
        .await?;
    ensure_pg_stat_statements(&pool).await?;
    Ok(pool)
}

// ============================================================================
// Benchmark bodies — each is an async fn that takes a &PgPool. Thin test
// wrappers below allow running one benchmark in isolation; the orchestrator
// invokes the bodies directly.
// ============================================================================

/// P0 baseline: hmac_256 equality should stay ~0.5ms at 100K rows.
async fn bench_hmac_256_equality(pool: &PgPool) -> Result<()> {
    let encrypted: String =
        sqlx::query_scalar("SELECT (encrypted_text).data::text FROM bench WHERE id = 1")
            .fetch_one(pool)
            .await?;

    let query = "SELECT * FROM bench WHERE eql_v2.hmac_256(encrypted_text) = eql_v2.hmac_256($1::jsonb::eql_v2_encrypted)";
    let plan_type = fetch_plan_node_type(pool, query, &[&encrypted]).await?;

    reset_pg_stat_statements(pool).await?;

    for _ in 0..RUNS {
        sqlx::query(query).bind(&encrypted).fetch_all(pool).await?;
    }

    let stats = read_pg_stat_statements(
        pool,
        "%FROM bench WHERE eql_v2.hmac_256(encrypted_text) = eql_v2.hmac_256($%",
    )
    .await?;

    append_result(PerfResult {
        name: "hmac_256_equality".into(),
        priority: "P0".into(),
        runs: stats.calls,
        plan_type,
        mean_ms: stats.mean_exec_time,
        stddev_ms: stats.stddev_exec_time,
        total_ms: stats.total_exec_time,
    });

    assert_eq!(stats.calls, RUNS, "expected {RUNS} recorded calls");
    Ok(())
}

/// P2: bloom_filter containment — expected ~3.35ms at 100K rows.
async fn bench_bloom_filter_containment(pool: &PgPool) -> Result<()> {
    let encrypted: String =
        sqlx::query_scalar("SELECT (encrypted_text).data::text FROM bench WHERE id = 1")
            .fetch_one(pool)
            .await?;

    let query = "SELECT * FROM bench WHERE eql_v2.bloom_filter(encrypted_text) @> eql_v2.bloom_filter($1::jsonb::eql_v2_encrypted)";
    let plan_type = fetch_plan_node_type(pool, query, &[&encrypted]).await?;

    reset_pg_stat_statements(pool).await?;
    for _ in 0..RUNS {
        sqlx::query(query).bind(&encrypted).fetch_all(pool).await?;
    }
    let stats = read_pg_stat_statements(
        pool,
        "%eql_v2.bloom_filter(encrypted_text) @> eql_v2.bloom_filter($%",
    )
    .await?;

    append_result(PerfResult {
        name: "bloom_filter_containment".into(),
        priority: "P2".into(),
        runs: stats.calls,
        plan_type,
        mean_ms: stats.mean_exec_time,
        stddev_ms: stats.stddev_exec_time,
        total_ms: stats.total_exec_time,
    });
    assert_eq!(stats.calls, RUNS, "expected {RUNS} recorded calls");
    Ok(())
}

/// P0: eql_cast equality — currently seq scans (CIP-2831). Report records the
/// actual plan + timing so the number is visible week-over-week until the fix ships.
async fn bench_eql_cast_equality(pool: &PgPool) -> Result<()> {
    let encrypted: String =
        sqlx::query_scalar("SELECT (encrypted_text).data::text FROM bench WHERE id = 1")
            .fetch_one(pool)
            .await?;

    let query = "SELECT * FROM bench WHERE encrypted_text = $1::jsonb::eql_v2_encrypted";
    let plan_type = fetch_plan_node_type(pool, query, &[&encrypted]).await?;

    reset_pg_stat_statements(pool).await?;
    for _ in 0..RUNS {
        sqlx::query(query).bind(&encrypted).fetch_all(pool).await?;
    }
    let stats = read_pg_stat_statements(
        pool,
        "%FROM bench WHERE encrypted_text = $%::jsonb::eql_v2_encrypted%",
    )
    .await?;

    append_result(PerfResult {
        name: "eql_cast_equality".into(),
        priority: "P0".into(),
        runs: stats.calls,
        plan_type,
        mean_ms: stats.mean_exec_time,
        stddev_ms: stats.stddev_exec_time,
        total_ms: stats.total_exec_time,
    });
    assert_eq!(stats.calls, RUNS, "expected {RUNS} recorded calls");
    Ok(())
}

/// P0: ORE equality via operator class — currently seq scans (CIP-2831).
async fn bench_ore_equality_opclass(pool: &PgPool) -> Result<()> {
    let encrypted: String =
        sqlx::query_scalar("SELECT (encrypted_int).data::text FROM bench WHERE id = 1")
            .fetch_one(pool)
            .await?;

    let query = "SELECT * FROM bench WHERE encrypted_int = $1::jsonb::eql_v2_encrypted";
    let plan_type = fetch_plan_node_type(pool, query, &[&encrypted]).await?;

    reset_pg_stat_statements(pool).await?;
    for _ in 0..RUNS {
        sqlx::query(query).bind(&encrypted).fetch_all(pool).await?;
    }
    let stats = read_pg_stat_statements(
        pool,
        "%FROM bench WHERE encrypted_int = $%::jsonb::eql_v2_encrypted%",
    )
    .await?;

    append_result(PerfResult {
        name: "ore_equality_opclass".into(),
        priority: "P0".into(),
        runs: stats.calls,
        plan_type,
        mean_ms: stats.mean_exec_time,
        stddev_ms: stats.stddev_exec_time,
        total_ms: stats.total_exec_time,
    });
    assert_eq!(stats.calls, RUNS, "expected {RUNS} recorded calls");
    Ok(())
}

/// P1: ORE range < with LIMIT — expected ~1.93ms at 100K rows.
async fn bench_ore_range_lt_limit(pool: &PgPool) -> Result<()> {
    let encrypted: String =
        sqlx::query_scalar("SELECT (encrypted_int).data::text FROM bench WHERE id = 50000")
            .fetch_one(pool)
            .await?;

    let query = "SELECT * FROM bench WHERE encrypted_int < $1::jsonb::eql_v2_encrypted ORDER BY encrypted_int LIMIT 10";
    let plan_type = fetch_plan_node_type(pool, query, &[&encrypted]).await?;

    reset_pg_stat_statements(pool).await?;
    for _ in 0..RUNS {
        sqlx::query(query).bind(&encrypted).fetch_all(pool).await?;
    }
    let stats = read_pg_stat_statements(
        pool,
        "%FROM bench WHERE encrypted_int < $%ORDER BY encrypted_int LIMIT %",
    )
    .await?;

    append_result(PerfResult {
        name: "ore_range_lt_limit".into(),
        priority: "P1".into(),
        runs: stats.calls,
        plan_type,
        mean_ms: stats.mean_exec_time,
        stddev_ms: stats.stddev_exec_time,
        total_ms: stats.total_exec_time,
    });
    assert_eq!(stats.calls, RUNS, "expected {RUNS} recorded calls");
    Ok(())
}

/// P1: ORE ORDER BY encrypted_int LIMIT 10 — design doc observes ~543ms at 10K,
/// so expect several seconds at 100K. Report captures actual number.
async fn bench_ore_order_by_limit(pool: &PgPool) -> Result<()> {
    let query = "SELECT * FROM bench ORDER BY encrypted_int LIMIT 10";
    let plan_type = fetch_plan_node_type(pool, query, &[]).await?;

    reset_pg_stat_statements(pool).await?;
    for _ in 0..RUNS {
        sqlx::query(query).fetch_all(pool).await?;
    }
    let stats = read_pg_stat_statements(pool, "%FROM bench ORDER BY encrypted_int LIMIT %").await?;

    append_result(PerfResult {
        name: "ore_order_by_limit".into(),
        priority: "P1".into(),
        runs: stats.calls,
        plan_type,
        mean_ms: stats.mean_exec_time,
        stddev_ms: stats.stddev_exec_time,
        total_ms: stats.total_exec_time,
    });
    assert_eq!(stats.calls, RUNS, "expected {RUNS} recorded calls");
    Ok(())
}

async fn flush_reports(pool: &PgPool) -> Result<()> {
    let pg_version: String = sqlx::query_scalar("SHOW server_version_num")
        .fetch_one(pool)
        .await?;
    // server_version_num is "170004" etc — take the major version digits
    let pg_major = pg_version
        .get(..pg_version.len().saturating_sub(4))
        .unwrap_or(&pg_version)
        .to_string();

    let date = std::env::var("BENCH_REPORT_DATE").unwrap_or_else(|_| today_utc());
    let output_dir = std::env::var("BENCH_REPORT_DIR")
        .unwrap_or_else(|_| "../../tests/benchmarks/reports".into());
    let (json, md) = write_reports(&output_dir, &date, &pg_major, DATASET_ROWS)?;
    eprintln!("wrote {} and {}", json.display(), md.display());
    Ok(())
}

fn today_utc() -> String {
    // Avoid adding the `chrono` dep; shell out to `date -u` for UTC.
    let out = std::process::Command::new("date")
        .args(["-u", "+%Y-%m-%d"])
        .output()
        .expect("invoking date");
    String::from_utf8(out.stdout).unwrap().trim().to_string()
}

// ============================================================================
// Orchestrator — scheduled CI entry point. Runs every benchmark in sequence
// and emits the report.
// ============================================================================

#[tokio::test]
#[ignore = "Tier 2: run all benchmarks + write reports (invoked by `mise run bench:full`)"]
async fn run_all_benchmarks() -> Result<()> {
    let pool = connect().await?;
    bench_hmac_256_equality(&pool).await?;
    bench_bloom_filter_containment(&pool).await?;
    bench_eql_cast_equality(&pool).await?;
    bench_ore_equality_opclass(&pool).await?;
    bench_ore_range_lt_limit(&pool).await?;
    bench_ore_order_by_limit(&pool).await?;
    flush_reports(&pool).await
}

// ============================================================================
// Individual test wrappers — allow running one benchmark in isolation via
// `cargo test --test bench_perf_tests <name> -- --ignored`. These do NOT
// flush reports; only `run_all_benchmarks` does that.
// ============================================================================

#[tokio::test]
#[ignore = "Tier 2: run via `mise run bench:full` (requires pre-loaded bench data)"]
async fn hmac_256_equality() -> Result<()> {
    bench_hmac_256_equality(&connect().await?).await
}

#[tokio::test]
#[ignore = "Tier 2: run via `mise run bench:full` (requires pre-loaded bench data)"]
async fn bloom_filter_containment() -> Result<()> {
    bench_bloom_filter_containment(&connect().await?).await
}

#[tokio::test]
#[ignore = "Tier 2: run via `mise run bench:full` (requires pre-loaded bench data)"]
async fn eql_cast_equality() -> Result<()> {
    bench_eql_cast_equality(&connect().await?).await
}

#[tokio::test]
#[ignore = "Tier 2: run via `mise run bench:full` (requires pre-loaded bench data)"]
async fn ore_equality_opclass() -> Result<()> {
    bench_ore_equality_opclass(&connect().await?).await
}

#[tokio::test]
#[ignore = "Tier 2: run via `mise run bench:full` (requires pre-loaded bench data)"]
async fn ore_range_lt_limit() -> Result<()> {
    bench_ore_range_lt_limit(&connect().await?).await
}

#[tokio::test]
#[ignore = "Tier 2: run via `mise run bench:full` (requires pre-loaded bench data)"]
async fn ore_order_by_limit() -> Result<()> {
    bench_ore_order_by_limit(&connect().await?).await
}
