//! THE PARITY GATE. Runs the Rust generator (into a temp dir) and asserts the
//! int4 SQL surface is line-normalized-equal to the `tests/codegen/reference/int4`
//! golden, and that committed `<T>_values.rs` are byte-identical to the
//! generator output. The golden reference — not the retired Python generator —
//! is the sole oracle.

use std::fs;
use std::path::PathBuf;

fn repo_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .unwrap()
        .parent()
        .unwrap()
        .to_path_buf()
}

fn tempdir(tag: &str) -> PathBuf {
    let mut p = std::env::temp_dir();
    let nanos = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_nanos();
    p.push(format!("eql-parity-{tag}-{nanos}"));
    fs::create_dir_all(&p).unwrap();
    p
}

#[test]
fn rust_generator_matches_committed_values_rs() {
    let root = repo_root();
    let out = tempdir("rust-values");
    eql_codegen::generate::generate_all(&out).expect("rust generate_all");

    for spec in eql_scalars::CATALOG {
        let token = spec.token;
        let generated = out.join(format!("tests/sqlx/src/fixtures/{token}_values.rs"));
        let committed = root.join(format!("tests/sqlx/src/fixtures/{token}_values.rs"));
        let g = fs::read(&generated).expect("generated values.rs");
        let c = fs::read(&committed).expect("committed values.rs");
        assert_eq!(
            g, c,
            "{token}_values.rs: Rust generator output differs from the committed file"
        );
    }
}

#[test]
fn rust_generator_matches_int4_golden_files() {
    let root = repo_root();
    let out = tempdir("rust-golden");
    eql_codegen::generate::generate_all(&out).expect("rust generate_all");

    let ref_dir = root.join("tests/codegen/reference/int4");
    let gen_dir = out.join("src/encrypted_domain/int4");
    for entry in fs::read_dir(&ref_dir).unwrap() {
        let path = entry.unwrap().path();
        if path.extension().and_then(|e| e.to_str()) != Some("sql") {
            continue;
        }
        let name = path.file_name().unwrap().to_str().unwrap();
        let reference = fs::read_to_string(&path).unwrap();
        // Strip the leading `-- REFERENCE:` provenance line. What remains is the
        // generated body, which already starts with the template-owned
        // `-- AUTOMATICALLY GENERATED FILE.` marker — the same first line the
        // materialised file carries, so no header is re-added here.
        let expected: String = reference
            .lines()
            .skip_while(|l| l.starts_with("-- REFERENCE:") || l.starts_with("// REFERENCE:"))
            .map(|l| format!("{l}\n"))
            .collect();
        let actual = fs::read_to_string(gen_dir.join(name)).unwrap();
        assert_eq!(
            eql_codegen::context::normalize_sql(&actual),
            eql_codegen::context::normalize_sql(&expected),
            "{name}: materialised output differs from golden (normalized)"
        );
    }
}

/// Both Rust strippers (the in-crate `strip_reference_marker` and this file's
/// golden test) skip a variable number of leading `-- REFERENCE:` lines, while
/// the shell gate skips exactly one with `tail -n +2`. They agree only while
/// every reference file carries exactly one marker line — make that explicit.
#[test]
fn every_reference_file_has_exactly_one_marker_line() {
    let root = repo_root();
    let dir = root.join("tests/codegen/reference/int4");
    for entry in fs::read_dir(&dir).unwrap() {
        let path = entry.unwrap().path();
        let ext = path.extension().and_then(|e| e.to_str());
        if ext != Some("sql") && ext != Some("rs") {
            continue;
        }
        let text = fs::read_to_string(&path).unwrap();
        let markers = text
            .lines()
            .take_while(|l| l.starts_with("-- REFERENCE:") || l.starts_with("// REFERENCE:"))
            .count();
        assert_eq!(
            markers, 1,
            "{}: expected exactly 1 leading REFERENCE marker line (shell `tail -n +2` assumes one); found {markers}",
            path.display()
        );
    }
}
