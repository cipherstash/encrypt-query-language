//! Benchmark report writer for Tier 2 scheduled benchmarks.
//!
//! Each `#[ignore]` benchmark in `bench_perf_tests.rs` pushes a `PerfResult`
//! into `append_result`. The `run_all_benchmarks` orchestrator invokes each
//! benchmark in sequence and then calls `write_reports` to flush all
//! accumulated results to JSON + Markdown.
//!
//! Output shape matches the design doc (.work/eql-index-performance/
//! 2026-03-30-benchmarking-design.md §Report Format) with one caveat: the
//! design doc lists `p95_ms` / `p99_ms` fields; Postgres `pg_stat_statements`
//! does not expose percentiles — only mean / stddev / total. v1 omits them
//! and documents the gap. Adding percentiles would require a different timing
//! strategy (e.g. client-side histograms) deferred to a follow-up.

use anyhow::{Context, Result};
use serde::Serialize;
use std::fs;
use std::path::PathBuf;
use std::sync::Mutex;
use time::format_description::well_known::Rfc3339;
use time::OffsetDateTime;

/// One benchmark case result.
#[derive(Debug, Clone, Serialize)]
pub struct PerfResult {
    /// Test name (e.g. "hmac_256_equality")
    pub name: String,
    /// Priority tier (P0, P1, P2)
    pub priority: String,
    /// Number of executions
    pub runs: i64,
    /// Plan node type (e.g. "Index Scan", "Seq Scan")
    pub plan_type: String,
    /// Mean execution time in milliseconds
    pub mean_ms: f64,
    /// Population standard deviation in milliseconds
    pub stddev_ms: f64,
    /// Total execution time across all runs in milliseconds
    pub total_ms: f64,
}

/// Top-level report structure — matches the design doc's JSON shape.
#[derive(Debug, Clone, Serialize)]
pub struct BenchmarkReport {
    /// RFC3339 UTC timestamp at report-write time
    pub timestamp: String,
    /// Postgres major version (e.g. "17")
    pub postgres_version: String,
    /// Dataset size this report was produced against
    pub dataset_rows: i64,
    /// One entry per benchmark case
    pub results: Vec<PerfResult>,
}

static RESULTS: Mutex<Vec<PerfResult>> = Mutex::new(Vec::new());

/// Push a result onto the shared in-memory accumulator.
pub fn append_result(r: PerfResult) {
    RESULTS.lock().expect("results mutex poisoned").push(r);
}

/// Write JSON + Markdown reports for all accumulated results.
///
/// Output paths:
///   `<output_dir>/benchmark-<date>.json`
///   `<output_dir>/benchmark-<date>.md`
///
/// `date` is used only as a filename suffix (any caller-supplied string,
/// typically `YYYY-MM-DD` with an optional run-id suffix for uniqueness).
/// The report's `timestamp` field is captured at write time as RFC3339 UTC
/// and is independent of `date`.
pub fn write_reports(
    output_dir: &str,
    date: &str,
    postgres_version: &str,
    dataset_rows: i64,
) -> Result<(PathBuf, PathBuf)> {
    let results = RESULTS.lock().expect("results mutex poisoned").clone();
    let timestamp = OffsetDateTime::now_utc()
        .format(&Rfc3339)
        .context("formatting RFC3339 write-time timestamp")?;
    let report = BenchmarkReport {
        timestamp,
        postgres_version: postgres_version.to_string(),
        dataset_rows,
        results,
    };

    fs::create_dir_all(output_dir).with_context(|| format!("creating output dir {output_dir}"))?;

    let json_path = PathBuf::from(output_dir).join(format!("benchmark-{date}.json"));
    let md_path = PathBuf::from(output_dir).join(format!("benchmark-{date}.md"));

    let json = serde_json::to_string_pretty(&report).context("serializing report to JSON")?;
    fs::write(&json_path, json).with_context(|| format!("writing {}", json_path.display()))?;

    fs::write(&md_path, render_markdown(&report))
        .with_context(|| format!("writing {}", md_path.display()))?;

    Ok((json_path, md_path))
}

fn render_markdown(report: &BenchmarkReport) -> String {
    let mut out = String::new();
    out.push_str(&format!("# Benchmark Report — {}\n\n", report.timestamp));
    out.push_str(&format!("- Postgres: {}\n", report.postgres_version));
    out.push_str(&format!("- Dataset rows: {}\n\n", report.dataset_rows));
    out.push_str("| Query Pattern | Priority | Plan | Runs | Mean (ms) | Stddev (ms) |\n");
    out.push_str("|---|---|---|---|---|---|\n");
    for r in &report.results {
        out.push_str(&format!(
            "| {} | {} | {} | {} | {:.3} | {:.3} |\n",
            r.name, r.priority, r.plan_type, r.runs, r.mean_ms, r.stddev_ms
        ));
    }
    out
}
