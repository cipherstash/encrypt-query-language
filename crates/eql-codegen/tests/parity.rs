//! THE PARITY GATE. Runs the Rust generator (into a temp dir) and asserts the
//! int4 SQL surface is byte-for-byte equal to the `tests/codegen/reference/int4`
//! golden (modulo the one leading `-- REFERENCE:` provenance line). The golden
//! reference — not the retired Python generator — is the sole oracle. The
//! plaintext fixture lists are not generated; they live in the catalog
//! (`eql_scalars::INT4_VALUES` / `INT2_VALUES`) and are pinned by
//! `eql-scalars`'s own `values_tests`.

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
fn rust_generator_matches_int4_golden_files() {
    let root = repo_root();
    let out = tempdir("rust-golden");
    eql_codegen::generate::generate_all(&out).expect("rust generate_all");

    let ref_dir = root.join("tests/codegen/reference/int4");
    let gen_dir = out.join("src/v3/scalars/int4");
    for entry in fs::read_dir(&ref_dir).unwrap() {
        let path = entry.unwrap().path();
        if path.extension().and_then(|e| e.to_str()) != Some("sql") {
            continue;
        }
        let name = path.file_name().unwrap().to_str().unwrap();
        let reference = fs::read_to_string(&path).unwrap();
        // Strip the leading `-- REFERENCE:` provenance line(s), preserving the
        // remaining bytes verbatim (`split_inclusive` keeps the `\n`
        // terminators). What remains is the generated body, which already starts
        // with the template-owned `-- AUTOMATICALLY GENERATED FILE.` marker — the
        // same first line the materialised file carries — so the comparison is
        // byte-for-byte with no header re-added.
        let expected: String = reference
            .split_inclusive('\n')
            .skip_while(|l| l.starts_with("-- REFERENCE:") || l.starts_with("// REFERENCE:"))
            .collect();
        let actual = fs::read_to_string(gen_dir.join(name)).unwrap();
        assert_eq!(
            actual, expected,
            "{name}: materialised output differs from golden"
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
