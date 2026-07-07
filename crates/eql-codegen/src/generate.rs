//! File renderers and orchestrator.

use std::path::{Path, PathBuf};

use eql_domains::{Domain, DomainFamily, Term};

use crate::context::{domain_name, is_ord_capable};
use crate::operator_surface::OPERATORS;

/// REQUIRE edge for the v3 schema file — pulled in by every generated file.
const V3_SCHEMA: &str = "src/v3/schema.sql";
/// REQUIRE edge for the hand-written shared blocker helper.
const V3_SCALARS_BLOCKER: &str = "src/v3/scalars/functions.sql";
/// Root of the generated per-type scalar surface. The single place the tree
/// layout is spelled out — keeps `types_path`/`scalar_path` and the REQUIRE
/// vecs from drifting if the surface ever relocates again.
const V3_SCALARS_DIR: &str = "src/v3/scalars";

/// REQUIRE path for a generated file `file` under a family's scalar dir.
fn scalar_path(family_name: &str, file: &str) -> String {
    format!("{V3_SCALARS_DIR}/{family_name}/{file}")
}

/// The second-parameter name for an operator's generated signature. The `->` and
/// `->>` path operators take a path *selector* as their right operand; every
/// other operator uses the generic `b`. This is a naming convention only — it
/// has no bearing on whether the operator is supported.
fn arg_b_name(symbol: &str) -> &'static str {
    match symbol {
        "->" | "->>" => "selector",
        _ => "b",
    }
}

/// REQUIRE path for a type's _types.sql. Port of `_types_path`.
fn types_path(family_name: &str) -> String {
    scalar_path(family_name, &format!("{family_name}_types.sql"))
}

/// Body for <T>_types.sql: every domain in one idempotent DO block.
/// Port of `render_types_file`.
pub fn render_types_file(spec: &DomainFamily) -> String {
    use crate::context::{domain_block, environment, TypesContext};
    let ctx = TypesContext {
        family_name: spec.name.to_string(),
        domains: spec
            .domains
            .iter()
            .map(|d| domain_block(spec.name, d))
            .collect(),
    };
    environment()
        .get_template("types.sql")
        .unwrap()
        .render(&ctx)
        .expect("render types.sql")
}

/// Body for <T>_query_types.sql: a `public.<name>_query` operand domain per
/// TERM-BEARING domain — the index-terms-only twin (no `c`) whose operators
/// consume a query operand (CIP-3432). Storage-only domains have no operators,
/// so no query twin.
pub fn render_query_types_file(spec: &DomainFamily) -> String {
    use crate::context::{environment, query_domain_block, TypesContext};
    let ctx = TypesContext {
        family_name: spec.name.to_string(),
        domains: spec
            .domains
            .iter()
            .filter(|d| !d.terms.is_empty())
            .map(|d| query_domain_block(spec.name, d))
            .collect(),
    };
    environment()
        .get_template("query_types.sql")
        .unwrap()
        .render(&ctx)
        .expect("render query_types.sql")
}

/// REQUIRE edges for a domain's _functions.sql. Port of `_functions_requires`.
fn functions_requires(family_name: &str, terms: &[Term]) -> Vec<String> {
    let mut reqs = vec![
        V3_SCHEMA.to_string(),
        types_path(family_name),
        V3_SCALARS_BLOCKER.to_string(),
    ];
    for extra in Term::term_requires(terms) {
        if !reqs.iter().any(|r| r == extra) {
            reqs.push(extra.to_string());
        }
    }
    reqs
}

/// Body for a domain's _functions.sql. Port of `render_functions_file`.
pub fn render_functions_file(family_name: &str, domain: &Domain) -> String {
    use crate::consts::sql_str;
    use crate::context::{
        environment, extractor_entry, unsupported_entry, wrapper_entry, FunctionsContext, SqlParam,
    };
    let name = domain.full_name(family_name);
    let dom = domain_name(&name);
    let domain_lit = sql_str(&dom);
    let supported = Term::operators_for_terms(domain.terms);
    let is_supported = |op: &str| supported.contains(&op);

    let mut entries = Vec::new();
    for term in Term::extractor_terms(domain.terms) {
        entries.push(extractor_entry(term));
    }
    for op in OPERATORS {
        let extractor = Term::extractor_for_operator(domain.terms, op.symbol);
        for sig in op.signatures {
            let rendered = sig.render(&dom);
            if is_supported(op.symbol) {
                if let Some(ex) = extractor {
                    entries.push(wrapper_entry(&dom, op, &rendered.left, &rendered.right, ex));
                    continue;
                }
            }
            let args = [
                SqlParam {
                    name: "a",
                    ty: rendered.left,
                },
                SqlParam {
                    name: arg_b_name(op.symbol),
                    ty: rendered.right,
                },
            ];
            entries.push(unsupported_entry(op, args, &rendered.returns));
        }
    }

    let ctx = FunctionsContext {
        requires: functions_requires(family_name, domain.terms),
        family_name: family_name.to_string(),
        name,
        dom,
        domain_lit,
        entries,
    };
    environment()
        .get_template("functions.sql")
        .unwrap()
        .render(&ctx)
        .expect("render functions.sql")
}

/// Body for a domain's _operators.sql. Port of `render_operators_file`.
pub fn render_operators_file(family_name: &str, domain: &Domain) -> String {
    use crate::context::{environment, operator_entry, OperatorsContext};
    let name = domain.full_name(family_name);
    let dom = domain_name(&name);
    let supported = Term::operators_for_terms(domain.terms);
    let is_supported = |op: &str| supported.contains(&op);

    let mut operators = Vec::new();
    for op in OPERATORS {
        for sig in op.signatures {
            // CREATE OPERATOR only needs the operand types; `rendered.returns` is
            // intentionally discarded here (it matters only for the function body).
            let rendered = sig.render(&dom);
            operators.push(operator_entry(
                op,
                &rendered.left,
                &rendered.right,
                is_supported(op.symbol),
            ));
        }
    }

    let ctx = OperatorsContext {
        requires: vec![
            V3_SCHEMA.to_string(),
            types_path(family_name),
            scalar_path(family_name, &format!("{name}_functions.sql")),
        ],
        family_name: family_name.to_string(),
        name,
        dom,
        operators,
    };
    environment()
        .get_template("operators.sql")
        .unwrap()
        .render(&ctx)
        .expect("render operators.sql")
}

/// REQUIRE path for a family's _query_types.sql.
fn query_types_path(family_name: &str) -> String {
    scalar_path(family_name, &format!("{family_name}_query_types.sql"))
}

/// Body for a term-bearing domain's <name>_query_functions.sql (CIP-3432): the
/// query-operand extractor OVERLOADS (the same extractors, on
/// `public.<name>_query`) plus the comparison WRAPPERS binding the storage
/// domain to its query twin — for the domain's SUPPORTED operators only, in
/// both directions. Reuses the same `functions.sql` template as the storage
/// surface; a query operand carries the same terms, so each wrapper compares
/// `extractor(a)` to `extractor(b)` with no ciphertext cast.
pub fn render_query_functions_file(family_name: &str, domain: &Domain) -> String {
    use crate::consts::sql_str;
    use crate::context::{
        domain_name, environment, extractor_entry, wrapper_entry, FunctionsContext,
    };
    let name = domain.full_name(family_name);
    let query_name = format!("{name}_query");
    let storage_dom = domain_name(&name);
    let query_dom = domain_name(&query_name);
    let supported = Term::operators_for_terms(domain.terms);

    let mut entries = Vec::new();
    // Extractor overloads on the query domain (the template renders `a {{ dom }}`
    // with dom = the query domain).
    for term in Term::extractor_terms(domain.terms) {
        entries.push(extractor_entry(term));
    }
    // Comparison wrappers: (storage, query) and its (query, storage) commutator,
    // for supported operators only (a query operand is never sent for a blocked
    // operator). `is_supported(op) ⟹ extractor_for_operator is Some`.
    for op in OPERATORS {
        if !supported.contains(&op.symbol) {
            continue;
        }
        let extractor = Term::extractor_for_operator(domain.terms, op.symbol)
            .expect("a supported operator resolves an extractor");
        entries.push(wrapper_entry(&query_dom, op, &storage_dom, &query_dom, extractor));
        entries.push(wrapper_entry(&query_dom, op, &query_dom, &storage_dom, extractor));
    }

    let ctx = FunctionsContext {
        requires: vec![
            V3_SCHEMA.to_string(),
            query_types_path(family_name),
            scalar_path(family_name, &format!("{name}_functions.sql")),
        ],
        family_name: family_name.to_string(),
        name: query_name,
        domain_lit: sql_str(&query_dom),
        dom: query_dom,
        entries,
    };
    environment()
        .get_template("functions.sql")
        .unwrap()
        .render(&ctx)
        .expect("render query functions.sql")
}

/// Body for a term-bearing domain's <name>_query_operators.sql (CIP-3432): a
/// `CREATE OPERATOR` binding `(storage_domain, <name>_query)` for every
/// supported operator, plus its `(<name>_query, storage_domain)` commutator, so
/// `col <op> $1::public.<name>_query` resolves to the query wrapper.
pub fn render_query_operators_file(family_name: &str, domain: &Domain) -> String {
    use crate::context::{domain_name, environment, operator_entry, OperatorsContext};
    let name = domain.full_name(family_name);
    let query_name = format!("{name}_query");
    let storage_dom = domain_name(&name);
    let query_dom = domain_name(&query_name);
    let supported = Term::operators_for_terms(domain.terms);

    let mut operators = Vec::new();
    for op in OPERATORS {
        if !supported.contains(&op.symbol) {
            continue;
        }
        operators.push(operator_entry(op, &storage_dom, &query_dom, true));
        operators.push(operator_entry(op, &query_dom, &storage_dom, true));
    }

    let ctx = OperatorsContext {
        requires: vec![
            V3_SCHEMA.to_string(),
            query_types_path(family_name),
            scalar_path(family_name, &format!("{query_name}_functions.sql")),
        ],
        family_name: family_name.to_string(),
        name: query_name,
        dom: query_dom,
        operators,
    };
    environment()
        .get_template("operators.sql")
        .unwrap()
        .render(&ctx)
        .expect("render query operators.sql")
}

/// Body for a domain's _aggregates.sql, or None if not ord-capable.
/// Port of `render_aggregates_file`.
pub fn render_aggregates_file(family_name: &str, domain: &Domain) -> Option<String> {
    use crate::context::{environment, AggregatesContext, AGGREGATE_OPS};
    if !is_ord_capable(domain.terms) {
        return None;
    }
    let name = domain.full_name(family_name);
    let dom = domain_name(&name);
    let ctx = AggregatesContext {
        requires: vec![
            V3_SCHEMA.to_string(),
            types_path(family_name),
            scalar_path(family_name, &format!("{name}_functions.sql")),
            scalar_path(family_name, &format!("{name}_operators.sql")),
        ],
        family_name: family_name.to_string(),
        name,
        dom,                       // hoisted: one copy, template reads {{ dom }}
        aggregates: AGGREGATE_OPS, // iterate the const directly (no per-entry wrapper)
    };
    Some(
        environment()
            .get_template("aggregates.sql")
            .unwrap()
            .render(&ctx)
            .expect("render aggregates.sql"),
    )
}

use std::fs;

use crate::writer::{
    ensure_generated_paths_writable, normalized_set, remove_generated_orphans,
    write_generated_file, GeneratedKind, WriteError,
};

/// Render every generated file for one type into memory, paired with its output
/// path under `out_dir`. Mirrors `bindings::render_bindings`: rendering happens
/// before any filesystem mutation, so a render `.expect` panic aborts the run
/// before a single file is written or deleted. Order matches `generate_type`'s
/// write order (types file, then per-domain functions/operators/aggregates).
pub fn render_type(spec: &DomainFamily, out_dir: &Path) -> Vec<(PathBuf, String)> {
    let family_name = spec.name;
    let mut rendered = vec![(
        out_dir.join(format!("{family_name}_types.sql")),
        render_types_file(spec),
    )];
    // Query-operand twin domains (term-only, no `c`) — only for families with at
    // least one term-bearing domain (storage-only families have no query surface).
    if spec.domains.iter().any(|d| !d.terms.is_empty()) {
        rendered.push((
            out_dir.join(format!("{family_name}_query_types.sql")),
            render_query_types_file(spec),
        ));
    }
    for d in spec.domains {
        let name = d.full_name(family_name);
        rendered.push((
            out_dir.join(format!("{name}_functions.sql")),
            render_functions_file(family_name, d),
        ));
        rendered.push((
            out_dir.join(format!("{name}_operators.sql")),
            render_operators_file(family_name, d),
        ));
        // Query-operand surface (CIP-3432): extractor overloads + wrappers +
        // operators binding the storage domain to its `<name>_query` twin. Only
        // term-bearing domains have a query twin (storage-only = no operators).
        if !d.terms.is_empty() {
            rendered.push((
                out_dir.join(format!("{name}_query_functions.sql")),
                render_query_functions_file(family_name, d),
            ));
            rendered.push((
                out_dir.join(format!("{name}_query_operators.sql")),
                render_query_operators_file(family_name, d),
            ));
        }
        if let Some(agg) = render_aggregates_file(family_name, d) {
            rendered.push((out_dir.join(format!("{name}_aggregates.sql")), agg));
        }
    }
    rendered
}

/// Regenerate every generated file for one type into `out_dir`, crash-safely.
/// Port of `generate_type`. Returns the written paths.
///
/// Ordering is render-all → preflight → write-all (atomic) → delete-orphans:
/// every current file is rendered to memory and written (each via an atomic
/// same-dir temp+rename) before any stale generated file is deleted. A render
/// panic or write error therefore can never leave the directory with files
/// deleted-but-not-rewritten. The trailing orphan sweep prunes generated SQL for
/// domains dropped from the catalog, marker-aware (hand-written files survive).
pub fn generate_type(spec: &DomainFamily, out_dir: &Path) -> Result<Vec<PathBuf>, WriteError> {
    let rendered = render_type(spec, out_dir);
    let targets: Vec<PathBuf> = rendered.iter().map(|(p, _)| p.clone()).collect();
    ensure_generated_paths_writable(&targets, GeneratedKind::Sql)?;

    let mut written: Vec<PathBuf> = Vec::with_capacity(rendered.len());
    for (path, body) in &rendered {
        write_generated_file(path, body, GeneratedKind::Sql)?;
        written.push(path.clone());
    }
    remove_generated_orphans(out_dir, GeneratedKind::Sql, &normalized_set(&written))?;
    Ok(written)
}

/// Generate every catalog type's gitignored SQL surface under `out_root`. The
/// single entry point: replaces Python's per-type and --all forms. The
/// plaintext fixture lists are not generated — they live in the catalog
/// (`eql_domains::INT4_VALUES` / `INT2_VALUES`), read directly by the SQLx tests.
pub fn generate_all(out_root: &Path) -> Result<i32, WriteError> {
    let scalars_root = out_root.join(V3_SCALARS_DIR);
    let mut all_written: Vec<PathBuf> = Vec::new();
    for spec in eql_domains::scalar_families() {
        let family_name = spec.name;
        let out_dir = scalars_root.join(family_name);
        let written = generate_type(spec, &out_dir)?;

        for p in &written {
            let rel = p.strip_prefix(out_root).unwrap_or(p);
            println!("generated {}", rel.display());
        }
        println!("generated {} files for {family_name}", written.len());
        all_written.extend(written.iter().cloned());
    }

    // Orphan sweep across every scalar type dir. `generate_type` already prunes
    // stale files *within* a regenerated dir, but a type dropped from the catalog
    // entirely leaves a dir the generator never revisits — its generated SQL must
    // still go (this is the responsibility build.sh's filename-pattern `find
    // -delete` used to own, now marker-aware and inside codegen). Runs only after
    // every current type wrote successfully, so it never deletes-before-write.
    let keep = normalized_set(&all_written);
    if scalars_root.is_dir() {
        // `file_type()` does NOT follow symlinks (unlike `Path::is_dir`), so a
        // symlinked entry under scalars_root is skipped rather than traversed —
        // the orphan sweep can never delete files outside `out_root` through a
        // symlink.
        let mut subdirs: Vec<PathBuf> = Vec::new();
        for entry in fs::read_dir(&scalars_root)? {
            let entry = entry?;
            if entry.file_type()?.is_dir() {
                subdirs.push(entry.path());
            }
        }
        subdirs.sort();
        for dir in subdirs {
            for removed in remove_generated_orphans(&dir, GeneratedKind::Sql, &keep)? {
                let rel = removed.strip_prefix(out_root).unwrap_or(&removed);
                println!("removed orphan {}", rel.display());
            }
        }
    }

    let names: Vec<&str> = eql_domains::scalar_families().map(|s| s.name).collect();
    println!("codegen: ok ({} types: {})", names.len(), names.join(", "));
    Ok(0)
}

/// Remove every generated SQL file under `out_root`'s `src/v3/scalars/*` type
/// dirs, marker-aware. Replaces build.sh's filename-pattern `find -delete`: it
/// deletes only files carrying the AUTO-GENERATED marker, so a hand-written
/// `<T>_extensions.sql` (no marker) and the committed depth-1
/// `src/v3/scalars/functions.sql` (not in a type subdir) are preserved. Returns
/// the removed paths.
pub fn clean_all(out_root: &Path) -> Result<Vec<PathBuf>, WriteError> {
    use crate::writer::clean_generated_files;
    let scalars_root = out_root.join(V3_SCALARS_DIR);
    if !scalars_root.is_dir() {
        return Ok(Vec::new());
    }
    // `file_type()` does NOT follow symlinks (unlike `Path::is_dir`), so a
    // symlinked entry under scalars_root is skipped, never descended into for
    // marker-aware deletion.
    let mut subdirs: Vec<PathBuf> = Vec::new();
    for entry in fs::read_dir(&scalars_root)? {
        let entry = entry?;
        if entry.file_type()?.is_dir() {
            subdirs.push(entry.path());
        }
    }
    subdirs.sort();
    let mut removed = Vec::new();
    for dir in subdirs {
        removed.extend(clean_generated_files(&dir, GeneratedKind::Sql)?);
    }
    Ok(removed)
}

#[cfg(test)]
mod tests {
    use super::*;
    use eql_domains::CATALOG;

    fn spec(family_name: &str) -> &'static DomainFamily {
        CATALOG
            .iter()
            .find(|s| s.name == family_name)
            .expect("catalog family")
    }

    fn domain<'a>(spec: &'a DomainFamily, name: &str) -> &'a Domain {
        spec.domains
            .iter()
            .find(|d| d.name == name)
            .expect("domain name")
    }

    use std::fs;

    #[test]
    fn arg_b_name_is_selector_only_for_path_operators() {
        assert_eq!(arg_b_name("->"), "selector");
        assert_eq!(arg_b_name("->>"), "selector");
        assert_eq!(arg_b_name("="), "b");
        assert_eq!(arg_b_name("||"), "b");
        assert_eq!(arg_b_name("@>"), "b");
    }

    #[test]
    fn functions_render_supported_wrappers_and_unsupported_entries_from_catalog() {
        let s = spec("integer");
        let d = domain(s, "eq");
        let sql = render_functions_file("integer", d);
        // Supported wrapper (`=`) is PUBLIC; unsupported ops (`<`, `->` on an
        // equality-only domain) stay as internal blockers.
        assert!(sql.contains("CREATE FUNCTION eql_v3.eq("));
        assert!(sql.contains("AS $$ SELECT"));
        assert!(sql.contains("CREATE FUNCTION eql_v3_internal.lt("));
        assert!(sql.contains("RAISE EXCEPTION 'operator % is not supported for %', '<'"));
        assert!(sql.contains("CREATE FUNCTION eql_v3_internal.\"->\"("));
        assert!(sql.contains("RAISE EXCEPTION 'operator % is not supported for %', '->'"));
    }

    #[test]
    fn generate_type_writes_expected_files() {
        let d = crate::writer::test_support::tempdir();
        let s = spec("integer");
        let out = d.path().join("integer");
        let written = generate_type(s, &out).unwrap();
        let names: Vec<String> = written
            .iter()
            .map(|p| p.file_name().unwrap().to_str().unwrap().to_string())
            .collect();
        assert!(names.contains(&"integer_types.sql".to_string()));
        // Query-operand twin domains (term-only, no `c`) for the family.
        assert!(names.contains(&"integer_query_types.sql".to_string()));
        for dom in [
            "integer",
            "integer_eq",
            "integer_ord_ore",
            "integer_ord",
            "integer_ord_ope",
        ] {
            assert!(names.contains(&format!("{dom}_functions.sql")));
            assert!(names.contains(&format!("{dom}_operators.sql")));
        }
        // Query-operand functions/operators for the term-bearing domains only
        // (not the storage-only bare `integer`).
        for dom in ["integer_eq", "integer_ord_ore", "integer_ord", "integer_ord_ope"] {
            assert!(names.contains(&format!("{dom}_query_functions.sql")));
            assert!(names.contains(&format!("{dom}_query_operators.sql")));
        }
        assert!(!names.contains(&"integer_query_functions.sql".to_string()));
        assert!(!names.contains(&"integer_aggregates.sql".to_string()));
        assert!(!names.contains(&"integer_eq_aggregates.sql".to_string()));
        assert!(names.contains(&"integer_ord_ore_aggregates.sql".to_string()));
        assert!(names.contains(&"integer_ord_aggregates.sql".to_string()));
        assert!(names.contains(&"integer_ord_ope_aggregates.sql".to_string()));
        // 1 types + 1 query_types + 2 per domain (5) + 2 query per term-bearing
        // domain (4) + 3 ord-capable aggregates = 1+1+10+8+3.
        assert_eq!(written.len(), 23);
        for p in &written {
            assert!(fs::read_to_string(p)
                .unwrap()
                .starts_with(&format!("{}\n", crate::consts::AUTO_GENERATED_MARKER)));
        }
    }

    #[test]
    fn generate_type_prunes_orphaned_generated_files() {
        // A generated file for a domain no longer produced (here: a stale
        // `integer_gone_functions.sql`) is pruned by the trailing orphan sweep, while
        // a hand-written file with no marker survives.
        let d = crate::writer::test_support::tempdir();
        let out = d.path().join("integer");
        fs::create_dir_all(&out).unwrap();
        let orphan = out.join("integer_gone_functions.sql");
        let hand = out.join("integer_extensions.sql");
        fs::write(
            &orphan,
            format!("{}\nSELECT 1;\n", crate::consts::AUTO_GENERATED_MARKER),
        )
        .unwrap();
        fs::write(&hand, "-- REQUIRE: src/v3/schema.sql\n-- hand-written\n").unwrap();

        generate_type(spec("integer"), &out).unwrap();

        assert!(!orphan.exists(), "stale generated file must be pruned");
        assert!(hand.exists(), "hand-written file must survive the sweep");
        assert!(
            out.join("integer_types.sql").exists(),
            "current files written"
        );
    }

    #[cfg(unix)]
    #[test]
    fn generate_type_failure_does_not_delete_before_writing() {
        // The write-then-delete discipline: if a write fails, nothing has been
        // deleted yet. Seed an existing generated target (old content) plus an
        // orphan, make the dir read-only so the first write fails, and assert both
        // survive untouched — the destructive orphan sweep never ran.
        use std::os::unix::fs::PermissionsExt;
        let d = crate::writer::test_support::tempdir();
        let out = d.path().join("integer");
        fs::create_dir_all(&out).unwrap();
        let marker = crate::consts::AUTO_GENERATED_MARKER;
        let types = out.join("integer_types.sql");
        let orphan = out.join("integer_gone_functions.sql");
        let old = format!("{marker}\n-- OLD\n");
        fs::write(&types, &old).unwrap();
        fs::write(&orphan, format!("{marker}\nSELECT 1;\n")).unwrap();

        let mut perms = fs::metadata(&out).unwrap().permissions();
        perms.set_mode(0o555);
        fs::set_permissions(&out, perms).unwrap();

        let err = generate_type(spec("integer"), &out).unwrap_err();

        let mut perms = fs::metadata(&out).unwrap().permissions();
        perms.set_mode(0o755);
        fs::set_permissions(&out, perms).unwrap();

        assert!(matches!(err, WriteError::Io(_)), "expected Io, got {err:?}");
        assert_eq!(
            fs::read_to_string(&types).unwrap(),
            old,
            "existing target keeps old content — never deleted/truncated"
        );
        assert!(
            orphan.exists(),
            "orphan must survive: the delete step runs only after writes succeed"
        );
    }

    #[test]
    fn generate_all_prunes_orphaned_type_dir() {
        // A whole type dir for a token absent from the catalog (here: `bogus`) is
        // swept by generate_all's cross-dir orphan pass — the case build.sh's
        // `find -delete` used to own, now marker-aware inside codegen.
        let d = crate::writer::test_support::tempdir();
        let root = d.path();
        let bogus_dir = root.join(V3_SCALARS_DIR).join("bogus");
        fs::create_dir_all(&bogus_dir).unwrap();
        let bogus = bogus_dir.join("bogus_types.sql");
        let bogus_hand = bogus_dir.join("bogus_extensions.sql");
        fs::write(
            &bogus,
            format!("{}\nSELECT 1;\n", crate::consts::AUTO_GENERATED_MARKER),
        )
        .unwrap();
        fs::write(&bogus_hand, "-- hand-written, no marker\n").unwrap();

        generate_all(root).unwrap();

        assert!(
            !bogus.exists(),
            "generated file in a dropped type dir is pruned"
        );
        assert!(
            bogus_hand.exists(),
            "hand-written file in that dir survives"
        );
        assert!(
            root.join(V3_SCALARS_DIR)
                .join("integer/integer_types.sql")
                .exists(),
            "catalog types are generated"
        );
    }

    #[cfg(unix)]
    #[test]
    fn generate_all_does_not_follow_symlinked_subdir_for_orphan_sweep() {
        // A symlinked entry under src/v3/scalars must NOT be descended into by the
        // cross-dir orphan sweep: `file_type()` reports the entry as a symlink (not
        // a dir), so files in the link target — which live OUTSIDE out_root — are
        // never marker-deleted. With the old `Path::is_dir()` (symlink-following)
        // scan, the generated file under the target would be swept.
        let d = crate::writer::test_support::tempdir();
        let root = d.path();
        let scalars = root.join(V3_SCALARS_DIR);
        fs::create_dir_all(&scalars).unwrap();

        // An outside-the-tree dir holding a marker-bearing generated file that is
        // NOT part of any catalog write, i.e. an "orphan" the sweep would target if
        // it could reach it.
        let outside = d.path().join("outside-target");
        fs::create_dir_all(&outside).unwrap();
        let victim = outside.join("integer_types.sql");
        fs::write(
            &victim,
            format!("{}\nSELECT 1;\n", crate::consts::AUTO_GENERATED_MARKER),
        )
        .unwrap();

        // Plant the symlink as a scalars subdir entry pointing at the outside dir.
        std::os::unix::fs::symlink(&outside, scalars.join("evil")).unwrap();

        generate_all(root).unwrap();

        assert!(
            victim.exists(),
            "file behind a symlinked subdir must not be swept (no symlink traversal)"
        );
    }

    #[test]
    fn types_file_has_all_five_domains() {
        let sql = render_types_file(spec("integer"));
        assert!(sql.contains("-- REQUIRE: src/v3/schema.sql"));
        for dom in [
            "integer",
            "integer_eq",
            "integer_ord_ore",
            "integer_ord",
            "integer_ord_ope",
        ] {
            assert!(
                sql.contains(&format!("CREATE DOMAIN public.{dom} AS jsonb")),
                "missing {dom}"
            );
        }
    }

    #[test]
    fn generated_scalar_domains_are_created_only_in_public() {
        let sql = render_types_file(spec("integer"));
        assert!(sql.contains("CREATE DOMAIN public.integer AS jsonb"));
        assert!(sql.contains("CREATE DOMAIN public.integer_eq AS jsonb"));
        assert!(!sql.contains("CREATE DOMAIN eql_v3."));
        assert!(!sql.contains("CREATE DOMAIN eql_v3_internal."));
    }

    /// The non-empty-`ob` CHECK (issue #262) is emitted only on ORE-bearing
    /// domains. An empty ORE term (`ob: []`) is what encrypting the empty string
    /// into an ordered column produces; the constraint rejects it at the domain
    /// boundary. Storage-only (`integer`) and equality-only (`integer_eq`) domains carry
    /// no `ob`, so they must NOT gain the clause.
    #[test]
    fn ore_bearing_domains_reject_empty_ob() {
        // Per-domain assertion: a domain's CREATE block carries the clause iff it
        // is ORE-bearing. Slice each domain's CHECK out of the rendered file so a
        // clause on the wrong domain cannot pass via whole-file `contains`.
        let sql = render_types_file(spec("integer"));
        let clause = "jsonb_array_length(VALUE -> 'ob') > 0";
        for (dom, expected) in [
            ("integer", false),
            ("integer_eq", false),
            ("integer_ord", true),
            ("integer_ord_ore", true),
            // The OPE term (`op`) is a single hex string, not an array — no
            // non-empty-array CHECK on the OPE-bearing domain.
            ("integer_ord_ope", false),
        ] {
            let head = format!("CREATE DOMAIN public.{dom} AS jsonb");
            let start = sql.find(&head).unwrap_or_else(|| panic!("missing {dom}"));
            // The CHECK ends at the closing `);` of this CREATE DOMAIN block.
            let end = start + sql[start..].find(");").expect("unterminated CHECK");
            let block = &sql[start..end];
            assert_eq!(
                block.contains(clause),
                expected,
                "domain {dom}: expected non-empty-ob CHECK present={expected}",
            );
        }
    }

    #[test]
    fn storage_functions_file_is_all_blockers() {
        let s = spec("integer");
        let sql = render_functions_file(s.name, domain(s, ""));
        assert_eq!(sql.matches("CREATE FUNCTION").count(), 44);
        assert!(!sql.contains("SET search_path"));
        assert_eq!(sql.matches("LANGUAGE plpgsql").count(), 44);
        assert_eq!(
            sql.matches("LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE")
                .count(),
            0
        );
    }

    #[test]
    fn eq_functions_file_counts() {
        let s = spec("integer");
        let sql = render_functions_file(s.name, domain(s, "eq"));
        assert_eq!(sql.matches("CREATE FUNCTION").count(), 45);
        assert!(sql.contains("CREATE FUNCTION eql_v3.eq_term(a public.integer_eq)"));
        assert!(sql.contains("RETURNS eql_v3_internal.hmac_256"));
        assert_eq!(
            sql.matches("LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE")
                .count(),
            7
        );
        assert_eq!(sql.matches("LANGUAGE plpgsql").count(), 38);
        assert!(!sql.contains("SET search_path"));
    }

    #[test]
    fn ore_functions_file_counts() {
        let s = spec("integer");
        let sql = render_functions_file(s.name, domain(s, "ord"));
        assert_eq!(sql.matches("CREATE FUNCTION").count(), 45);
        assert!(sql.contains("CREATE FUNCTION eql_v3.ord_term(a public.integer_ord)"));
        assert!(sql.contains("RETURNS eql_v3_internal.ore_block_256"));
        assert_eq!(
            sql.matches("LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE")
                .count(),
            19
        );
        assert_eq!(sql.matches("LANGUAGE plpgsql").count(), 26);
    }

    #[test]
    fn ope_functions_file_counts() {
        // The OPE ordered domain mirrors the ORE one — same operator surface
        // (18 wrappers), one extractor — but the extractor is `ord_ope_term`
        // returning the SEM `eql_v3_internal.ope_cllw` domain (over bytea), and the
        // sole SEM REQUIRE edge is the extractor file: the bytea-backed
        // domain inherits native comparison operators, so there is no
        // hand-written operators.sql to depend on (unlike Ore).
        let s = spec("integer");
        let sql = render_functions_file(s.name, domain(s, "ord_ope"));
        assert_eq!(sql.matches("CREATE FUNCTION").count(), 45);
        assert!(sql.contains("CREATE FUNCTION eql_v3.ord_ope_term(a public.integer_ord_ope)"));
        assert!(sql.contains("RETURNS eql_v3_internal.ope_cllw"));
        assert!(sql.contains("-- REQUIRE: src/v3/sem/ope_cllw/functions.sql"));
        assert!(!sql.contains("-- REQUIRE: src/v3/sem/ope_cllw/operators.sql"));
        assert_eq!(
            sql.matches("LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE")
                .count(),
            19
        );
        assert_eq!(sql.matches("LANGUAGE plpgsql").count(), 26);
    }

    #[test]
    fn operators_file_has_forty_four() {
        let s = spec("integer");
        let sql = render_operators_file(s.name, domain(s, "eq"));
        assert_eq!(sql.matches("CREATE OPERATOR").count(), 44);
    }

    #[test]
    fn generated_functions_reference_public_domain_arguments() {
        let s = spec("integer");
        let sql = render_functions_file(s.name, domain(s, "eq"));
        assert!(sql.contains("CREATE FUNCTION eql_v3.eq_term(a public.integer_eq)"));
        assert!(sql.contains("CREATE FUNCTION eql_v3.eq(a public.integer_eq, b public.integer_eq)"));
        assert!(sql.contains("CREATE FUNCTION eql_v3.eq(a public.integer_eq, b jsonb)"));
        assert!(sql.contains("CREATE FUNCTION eql_v3.eq(a jsonb, b public.integer_eq)"));
        assert!(!sql.contains("a eql_v3.integer_eq"));
    }

    #[test]
    fn supported_operators_bind_public_wrapper_blocked_bind_internal() {
        // The operator-equivalent invariant for operator-free platforms: a
        // SUPPORTED operator's backing function is PUBLIC (`eql_v3.<wrapper>`)
        // so it is callable by name without the operator; a BLOCKED operator's
        // backing function stays internal (`eql_v3_internal.<blocker>`).
        let s = spec("integer");
        let eq_sql = render_operators_file(s.name, domain(s, "eq"));
        // `=` is supported on integer_eq → public wrapper.
        assert!(eq_sql.contains("FUNCTION = eql_v3.eq,"));
        // `<` is unsupported on the equality-only domain → internal blocker.
        assert!(eq_sql.contains("FUNCTION = eql_v3_internal.lt,"));
        // native-jsonb blocker stays internal too.
        assert!(eq_sql.contains("FUNCTION = eql_v3_internal.\"||\","));

        // Ordered domain: comparison + range wrappers all public.
        let ord_sql = render_operators_file(s.name, domain(s, "ord"));
        for f in ["eq", "neq", "lt", "lte", "gt", "gte"] {
            assert!(
                ord_sql.contains(&format!("FUNCTION = eql_v3.{f},")),
                "ordered operator {f} must bind the public wrapper"
            );
        }

        // Bloom text_match: containment wrappers are supported → public.
        let tm = spec("text");
        let tm_sql = render_operators_file(tm.name, domain(tm, "match"));
        assert!(tm_sql.contains("FUNCTION = eql_v3.contains,"));
        assert!(tm_sql.contains("FUNCTION = eql_v3.contained_by,"));
    }

    #[test]
    fn aggregates_file_only_for_ord_variants() {
        let s = spec("integer");
        assert!(render_aggregates_file(s.name, domain(s, "")).is_none());
        assert!(render_aggregates_file(s.name, domain(s, "eq")).is_none());
        assert!(render_aggregates_file(s.name, domain(s, "ord")).is_some());
        assert!(render_aggregates_file(s.name, domain(s, "ord_ore")).is_some());
        assert!(render_aggregates_file(s.name, domain(s, "ord_ope")).is_some());
    }

    #[test]
    fn aggregates_file_carries_min_and_max_and_requires() {
        let s = spec("integer");
        let sql = render_aggregates_file(s.name, domain(s, "ord")).unwrap();
        assert_eq!(sql.matches("CREATE FUNCTION").count(), 2);
        assert_eq!(sql.matches("CREATE AGGREGATE").count(), 2);
        assert!(sql.contains("eql_v3_internal.min_sfunc"));
        assert!(sql.contains("eql_v3_internal.max_sfunc"));
        assert!(sql.contains("-- REQUIRE: src/v3/scalars/integer/integer_ord_operators.sql"));
        assert!(sql.contains("-- REQUIRE: src/v3/scalars/integer/integer_ord_functions.sql"));
        assert!(sql.contains("-- REQUIRE: src/v3/scalars/integer/integer_types.sql"));
    }

    #[test]
    fn ordered_files_byte_identical_modulo_typename() {
        let s = spec("integer");
        let ord = domain(s, "ord");
        let ore = domain(s, "ord_ore");
        let norm = |sql: String| {
            sql.replace("integer_ord_ore", "T")
                .replace("integer_ord", "T")
        };
        assert_eq!(
            norm(render_functions_file(s.name, ord)),
            norm(render_functions_file(s.name, ore))
        );
        assert_eq!(
            norm(render_operators_file(s.name, ord)),
            norm(render_operators_file(s.name, ore))
        );
        assert_eq!(
            norm(render_aggregates_file(s.name, ord).unwrap()),
            norm(render_aggregates_file(s.name, ore).unwrap())
        );
    }

    // --- Coarsened footgun invariant guards (whole-file scans) ---

    #[test]
    fn blockers_are_never_strict_and_always_plpgsql() {
        let s = spec("integer");
        // Storage domain functions file is all blockers.
        let sql = render_functions_file("integer", domain(s, ""));
        // Every CREATE FUNCTION here is a blocker: none may be STRICT, all plpgsql.
        assert!(!sql.contains("STRICT"), "blocker marked STRICT");
        assert_eq!(
            sql.matches("CREATE FUNCTION").count(),
            sql.matches("LANGUAGE plpgsql").count(),
            "every blocker must be LANGUAGE plpgsql"
        );
    }

    #[test]
    fn inlinable_functions_have_no_set_search_path() {
        let s = spec("integer");
        // Extractors and wrappers (eq/ord functions files) are inlinable SQL.
        for name in ["eq", "ord"] {
            let sql = render_functions_file("integer", domain(s, name));
            // Inlinable rows are the LANGUAGE sql ones; none may pin search_path.
            for block in sql.split("CREATE FUNCTION").skip(1) {
                if block.contains("LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE") {
                    assert!(
                        !block.contains("SET search_path"),
                        "inlinable SQL function pins search_path"
                    );
                }
            }
        }
    }

    #[test]
    fn aggregate_state_functions_are_plpgsql_not_inlinable() {
        let s = spec("integer");
        let sql = render_aggregates_file("integer", domain(s, "ord")).unwrap();
        assert_eq!(sql.matches("CREATE FUNCTION").count(), 2);
        assert_eq!(
            sql.matches("LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE")
                .count(),
            2
        );
        assert_eq!(
            sql.matches("LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE")
                .count(),
            0
        );
    }

    #[test]
    fn generated_function_like_docs_keep_required_tags() {
        let s = spec("integer");
        for d in s.domains {
            let sql = render_functions_file("integer", d);
            let functions = sql.matches("CREATE FUNCTION").count();
            assert_eq!(sql.matches("--! @return").count(), functions);
            assert!(
                sql.matches("--! @param").count() >= functions,
                "each generated function must keep at least one @param tag"
            );
            assert!(
                sql.matches("--! @brief").count() >= functions,
                "each generated function must keep @brief"
            );
        }

        let sql = render_aggregates_file("integer", domain(s, "ord")).unwrap();
        let function_like =
            sql.matches("CREATE FUNCTION").count() + sql.matches("CREATE AGGREGATE").count();
        assert_eq!(sql.matches("--! @return").count(), function_like);
        assert!(sql.matches("--! @param").count() >= function_like);
        assert!(sql.matches("--! @brief").count() >= function_like);
    }

    // --- Escaping guards over the context builders (synthetic inputs) ---

    #[test]
    fn unsupported_entry_preserves_operator_literal_and_domain_lit_is_escaped() {
        use crate::consts::sql_str;
        use crate::context::{unsupported_entry, FnEntry, SqlParam};
        use crate::operator_surface::operator;
        let dom = "eql_v3.o'dom";
        let domain_lit = sql_str(dom);
        let entry = unsupported_entry(
            &operator("<"),
            [
                SqlParam {
                    name: "a",
                    ty: dom.into(),
                },
                SqlParam {
                    name: "b",
                    ty: dom.into(),
                },
            ],
            "boolean",
        );
        match entry {
            FnEntry::Unsupported { operator_lit, .. } => {
                assert_eq!(domain_lit, "eql_v3.o''dom"); // quote doubled by sql_str
                assert_eq!(operator_lit, "<");
            }
            _ => panic!("expected unsupported-operator entry"),
        }
    }

    #[test]
    fn domain_block_escapes_quote_bearing_name() {
        use crate::context::domain_block;
        use eql_domains::{Domain, Shape};
        let block = domain_block(
            "integer",
            &Domain {
                name: "q",
                terms: &[],
                shape: Shape::Scalar,
            },
        );
        assert_eq!(block.typname, "integer_q"); // no quote present → unchanged
                                                // keys are sql_str-escaped key tokens; none should carry a bare unescaped quote.
        assert!(block.keys.iter().all(|k| !k.contains("o'")));
    }
}
