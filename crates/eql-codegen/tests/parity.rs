//! THE PARITY GATE. Runs the Rust generator (into a temp dir) and asserts the
//! generated SQL surface is byte-for-byte equal to the committed reference SQL
//! files under `tests/codegen/reference/<token>/` (modulo the one leading
//! `-- REFERENCE:` provenance line). Every catalog type has a committed
//! reference, generated once; the reference — not the retired Python generator
//! — is the sole oracle. The reference dirs are *discovered* dynamically and
//! cross-checked against `eql_domains::CATALOG`, so a new catalog type with no
//! reference (or a stale reference with no catalog row) fails here. The
//! plaintext fixture lists are not
//! generated; they live in the catalog (`eql_domains::INT4_VALUES` /
//! `INT2_VALUES`) and are pinned by `eql-domains`'s own `values_tests`.

use std::collections::BTreeSet;
use std::fs;
use std::path::{Path, PathBuf};

use eql_codegen::repo_root;

/// A temp dir removed on drop, so parity runs don't leak `/tmp` trees.
struct TempDir(PathBuf);
impl TempDir {
    fn path(&self) -> &Path {
        &self.0
    }
}
impl Drop for TempDir {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.0);
    }
}

fn tempdir(tag: &str) -> TempDir {
    let mut p = std::env::temp_dir();
    let nanos = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_nanos();
    p.push(format!("eql-parity-{tag}-{nanos}"));
    fs::create_dir_all(&p).unwrap();
    TempDir(p)
}

/// The committed reference token dirs under `tests/codegen/reference/` (every
/// entry that is a directory; `README.md` and any stray file are skipped).
fn reference_tokens(root: &Path) -> BTreeSet<String> {
    fs::read_dir(root.join("tests/codegen/reference"))
        .expect("reference dir")
        .filter_map(|e| e.ok())
        .filter(|e| e.path().is_dir())
        .map(|e| e.file_name().to_str().unwrap().to_string())
        .collect()
}

/// The sorted `*.sql` file names directly under `dir`.
fn sql_names(dir: &Path) -> Vec<String> {
    let mut names: Vec<String> = fs::read_dir(dir)
        .unwrap()
        .filter_map(|e| e.ok().map(|e| e.path()))
        .filter(|p| p.extension().and_then(|x| x.to_str()) == Some("sql"))
        .map(|p| p.file_name().unwrap().to_str().unwrap().to_string())
        .collect();
    names.sort();
    names
}

/// Strip the leading `-- REFERENCE:` provenance line(s), preserving the
/// remaining bytes verbatim (`split_inclusive` keeps the `\n` terminators).
/// What remains is the generated body, which already starts with the
/// template-owned `-- AUTOMATICALLY GENERATED FILE.` marker — the same first
/// line the materialised file carries — so the comparison is byte-for-byte.
fn reference_body(reference: &str) -> String {
    reference
        .split_inclusive('\n')
        .skip_while(|l| l.starts_with("-- REFERENCE:") || l.starts_with("// REFERENCE:"))
        .collect()
}

#[test]
fn reference_dirs_match_catalog_tokens() {
    let root = repo_root();
    let refs = reference_tokens(&root);
    let catalog: BTreeSet<String> = eql_domains::CATALOG
        .iter()
        .map(|s| s.token.to_string())
        .collect();
    assert_eq!(
        refs, catalog,
        "committed reference dirs must equal the catalog token set: a new \
         catalog type needs a committed `tests/codegen/reference/<token>/` reference \
         (generate it with `cargo run -p eql-codegen` and prepend a `-- REFERENCE:` \
         line), and a stale reference with no catalog row must be removed"
    );
}

#[test]
fn rust_generator_matches_reference_files() {
    let root = repo_root();
    let out = tempdir("rust-reference");
    eql_codegen::generate::generate_all(out.path()).expect("rust generate_all");

    for token in reference_tokens(&root) {
        let ref_dir = root.join("tests/codegen/reference").join(&token);
        let gen_dir = out.path().join("src/v3/scalars").join(&token);

        // Assert the generated .sql file SET matches the reference set first. The
        // per-file byte comparison below only iterates reference files, so a
        // missing generated file would surface only as an opaque `unwrap` panic on
        // the `read_to_string` below, and an EXTRA generated file (one the
        // reference never pins) would pass silently — it is never iterated. This
        // set check turns both into a clear file-set diff.
        let ref_names = sql_names(&ref_dir);
        let gen_names = sql_names(&gen_dir);
        assert_eq!(
            gen_names, ref_names,
            "{token}: generated .sql file set differs from reference set \
             (reference: {ref_names:?}, generated: {gen_names:?})"
        );

        for name in &ref_names {
            let reference = fs::read_to_string(ref_dir.join(name)).unwrap();
            let expected = reference_body(&reference);
            let actual = fs::read_to_string(gen_dir.join(name)).unwrap();
            assert_eq!(
                actual, expected,
                "{token}/{name}: materialised output differs from reference"
            );
        }
    }
}

/// Run the generator twice into separate temp dirs and assert every emitted file
/// is byte-identical between the runs. Guards the documented determinism promise
/// (identical `CATALOG` => byte-identical SQL) against a future `HashMap`/`HashSet`
/// iteration leaking into a renderer.
#[test]
fn generate_all_is_deterministic_across_runs() {
    let a = tempdir("determinism-a");
    let b = tempdir("determinism-b");
    eql_codegen::generate::generate_all(a.path()).expect("generate_all a");
    eql_codegen::generate::generate_all(b.path()).expect("generate_all b");

    let collect = |root: &Path| -> Vec<(String, String)> {
        let base = root.join("src/v3/scalars");
        let mut files: Vec<(String, String)> = Vec::new();
        let mut stack = vec![base.clone()];
        while let Some(dir) = stack.pop() {
            for entry in fs::read_dir(&dir).unwrap() {
                let path = entry.unwrap().path();
                if path.is_dir() {
                    stack.push(path);
                } else if path.extension().and_then(|x| x.to_str()) == Some("sql") {
                    let rel = path
                        .strip_prefix(&base)
                        .unwrap()
                        .to_str()
                        .unwrap()
                        .to_string();
                    files.push((rel, fs::read_to_string(&path).unwrap()));
                }
            }
        }
        files.sort();
        files
    };

    let fa = collect(a.path());
    let fb = collect(b.path());
    assert_eq!(
        fa.iter().map(|(n, _)| n).collect::<Vec<_>>(),
        fb.iter().map(|(n, _)| n).collect::<Vec<_>>(),
        "two generator runs emitted different file sets"
    );
    for ((na, ca), (_nb, cb)) in fa.iter().zip(fb.iter()) {
        assert_eq!(ca, cb, "{na}: two generator runs produced different bytes");
    }
}

/// Both Rust strippers (the in-crate `strip_reference_marker` and this file's
/// reference test) skip a variable number of leading `-- REFERENCE:` lines, while
/// the shell gate skips exactly one with `tail -n +2`. They agree only while
/// every reference file carries exactly one marker line — make that explicit
/// across every committed reference dir.
#[test]
fn every_reference_file_has_exactly_one_marker_line() {
    let root = repo_root();
    for token in reference_tokens(&root) {
        let dir = root.join("tests/codegen/reference").join(&token);
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
}
