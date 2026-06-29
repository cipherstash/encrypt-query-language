//! Smoke test for the `eql-codegen` binary's subcommand dispatch (`main.rs`).
//! No `assert_cmd` in this repo, so we drive the compiled binary directly via
//! the `CARGO_BIN_EXE_eql-codegen` path Cargo injects for integration tests.

use std::process::Command;

/// Path to the compiled `eql-codegen` binary, injected by Cargo.
fn bin() -> &'static str {
    env!("CARGO_BIN_EXE_eql-codegen")
}

/// `bindings` exits 0 and reports the written-file count. The success path
/// regenerates the committed `crates/eql-bindings/src/v3/*.rs` in place, but
/// generation is deterministic and those files are committed-fresh, so the run
/// is idempotent (no working-tree change). The count is one file per catalog
/// family plus `inventory.rs`.
#[test]
fn bindings_subcommand_succeeds_and_reports_count() {
    let out = Command::new(bin())
        .arg("bindings")
        .output()
        .expect("run eql-codegen bindings");
    assert!(
        out.status.success(),
        "bindings should exit 0; stderr: {}",
        String::from_utf8_lossy(&out.stderr)
    );
    let stdout = String::from_utf8_lossy(&out.stdout);
    let expected = eql_domains::CATALOG.len() + 1;
    assert!(
        stdout.contains(&format!("bindings: ok ({expected} files)")),
        "expected 'bindings: ok ({expected} files)' in stdout, got:\n{stdout}"
    );
}

/// An unrecognised argument prints usage and exits 2 (the `ExitCode::from(2)`
/// fall-through in `main.rs`).
#[test]
fn unknown_arg_exits_two() {
    let out = Command::new(bin())
        .arg("frobnicate")
        .output()
        .expect("run eql-codegen frobnicate");
    assert_eq!(
        out.status.code(),
        Some(2),
        "unknown arg must exit 2; stderr: {}",
        String::from_utf8_lossy(&out.stderr)
    );
}
