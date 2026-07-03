//! Smoke test for the `eql-codegen` binary's subcommand dispatch (`main.rs`).
//! No `assert_cmd` in this repo, so we drive the compiled binary directly via
//! the `CARGO_BIN_EXE_eql-codegen` path Cargo injects for integration tests.

use std::path::PathBuf;
use std::process::Command;

/// Path to the compiled `eql-codegen` binary, injected by Cargo.
fn bin() -> &'static str {
    env!("CARGO_BIN_EXE_eql-codegen")
}

/// A throwaway directory under the system temp root, removed on drop. Lets the
/// smoke test redirect `bindings` output via `EQL_CODEGEN_OUT_ROOT` instead of
/// writing into the committed source tree.
struct TempDir(PathBuf);
impl Drop for TempDir {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.0);
    }
}
fn tempdir() -> TempDir {
    let nanos = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_nanos();
    let mut p = std::env::temp_dir();
    p.push(format!("eql-codegen-cli-{}-{nanos}", std::process::id()));
    std::fs::create_dir_all(&p).unwrap();
    TempDir(p)
}

/// `bindings` exits 0 and reports the written-file count. Run against a throwaway
/// `EQL_CODEGEN_OUT_ROOT` tree so the smoke test proves the subcommand honours
/// the output-root override (test isolation) and never touches the committed
/// `crates/eql-bindings/src/v3/*.rs`. The count is one file per catalog family
/// plus `inventory.rs`.
#[test]
fn bindings_subcommand_succeeds_and_reports_count() {
    let out_root = tempdir();
    let out = Command::new(bin())
        .arg("bindings")
        .env("EQL_CODEGEN_OUT_ROOT", out_root.0.as_os_str())
        .output()
        .expect("run eql-codegen bindings");
    assert!(
        out.status.success(),
        "bindings should exit 0; stderr: {}",
        String::from_utf8_lossy(&out.stderr)
    );
    let stdout = String::from_utf8_lossy(&out.stdout);
    let expected = eql_domains::scalar_families().count() + 1;
    assert!(
        stdout.contains(&format!("bindings: ok ({expected} files)")),
        "expected 'bindings: ok ({expected} files)' in stdout, got:\n{stdout}"
    );
    // The override must have routed output into the temp tree, leaving the
    // committed bindings tree untouched.
    let generated = out_root.0.join("crates/eql-bindings/src/v3/inventory.rs");
    assert!(
        generated.is_file(),
        "expected generated inventory.rs under the override root at {}",
        generated.display()
    );
}

/// `list-schemas` exits 0 and prints the owned schemas, public first, one per
/// line. This is the Rust side of the schema-split parity gate
/// (`mise run test:schemas:parity`), so the exact stdout is pinned here.
#[test]
fn list_schemas_subcommand_prints_owned_schemas() {
    let out = Command::new(bin())
        .arg("list-schemas")
        .output()
        .expect("run eql-codegen list-schemas");
    assert!(
        out.status.success(),
        "list-schemas should exit 0; stderr: {}",
        String::from_utf8_lossy(&out.stderr)
    );
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert_eq!(
        stdout, "eql_v3\neql_v3_internal\n",
        "list-schemas must print the public schema first, then the internal schema"
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
