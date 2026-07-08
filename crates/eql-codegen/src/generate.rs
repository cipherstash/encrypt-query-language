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

/// Body for a `<name>_types.sql` given an explicit type name and domain set —
/// the name-parameterized core of `render_types_file`, reused for aliases.
pub fn render_types_file_named(family_name: &str, domains: &[Domain]) -> String {
    use crate::context::{domain_block, environment, TypesContext};
    let ctx = TypesContext {
        family_name: family_name.to_string(),
        domains: domains.iter().map(|d| domain_block(family_name, d)).collect(),
    };
    environment()
        .get_template("types.sql")
        .unwrap()
        .render(&ctx)
        .expect("render types.sql")
}

/// Body for <T>_types.sql: every domain in one idempotent DO block.
/// Port of `render_types_file`.
pub fn render_types_file(spec: &DomainFamily) -> String {
    render_types_file_named(spec.name, spec.domains)
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
    use crate::context::{
        environment, extractor_entry, unsupported_entry, wrapper_entry, FunctionsContext, SqlParam,
    };
    let name = domain.full_name(family_name);
    let dom = domain_name(&name);
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
            entries.push(unsupported_entry(&dom, op, args, &rendered.returns));
        }
    }

    let ctx = FunctionsContext {
        requires: functions_requires(family_name, domain.terms),
        family_name: family_name.to_string(),
        name,
        dom,
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
/// Render every generated file for one type NAME + domain set into memory. The
/// name-parameterized core of `render_type`, reused to emit alias surfaces under
/// their own name.
pub fn render_type_named(name: &str, domains: &[Domain], out_dir: &Path) -> Vec<(PathBuf, String)> {
    let mut rendered = vec![(
        out_dir.join(format!("{name}_types.sql")),
        render_types_file_named(name, domains),
    )];
    for d in domains {
        let full = d.full_name(name);
        rendered.push((
            out_dir.join(format!("{full}_functions.sql")),
            render_functions_file(name, d),
        ));
        rendered.push((
            out_dir.join(format!("{full}_operators.sql")),
            render_operators_file(name, d),
        ));
        if let Some(agg) = render_aggregates_file(name, d) {
            rendered.push((out_dir.join(format!("{full}_aggregates.sql")), agg));
        }
    }
    rendered
}

/// Render every generated file for one type into memory, paired with its output
/// path under `out_dir`. Rendering happens before any filesystem mutation, so a
/// render `.expect` panic aborts the run before a single file is written or
/// deleted. Thin wrapper over [`render_type_named`] for the canonical name.
pub fn render_type(spec: &DomainFamily, out_dir: &Path) -> Vec<(PathBuf, String)> {
    render_type_named(spec.name, spec.domains, out_dir)
}

/// Render the cross-name operator file for one ordered pair of group names
/// (`a`, `b`) sharing `family`'s domain set. For each domain role and each
/// cross-name operator (§ `cross_name_operators`), emit — in BOTH directions —
/// a public wrapper (supported ops) or an internal blocker (unsupported ops),
/// plus the matching CREATE OPERATOR. No casts.
pub fn render_cross_file(family: &DomainFamily, a: &str, b: &str) -> String {
    use crate::context::{
        environment, operator_entry, unsupported_entry, wrapper_entry, CrossContext, SqlParam,
    };
    use crate::operator_surface::{cross_name_operators, TypeSlot};

    let cross_ops = cross_name_operators();
    let mut entries = Vec::new();
    let mut operators = Vec::new();

    // Both ordered directions: (a,b) and (b,a).
    for (left_name, right_name) in [(a, b), (b, a)] {
        for d in family.domains {
            let dom_l = domain_name(&d.full_name(left_name));
            let dom_r = domain_name(&d.full_name(right_name));
            let supported = Term::operators_for_terms(d.terms);
            for op in &cross_ops {
                let is_supported = supported.contains(&op.symbol);
                if is_supported {
                    let ex = Term::extractor_for_operator(d.terms, op.symbol)
                        .expect("supported cross op has an extractor");
                    entries.push(wrapper_entry(&dom_l, op, &dom_l, &dom_r, ex));
                } else {
                    // R3: take the return type from the op's Domain/Domain
                    // signature (Boolean -> "boolean" for the 8 comparisons,
                    // Jsonb -> "jsonb" for `||`), NOT a string match on op.symbol.
                    let dd_sig = op
                        .signatures
                        .iter()
                        .find(|s| s.left == TypeSlot::Domain && s.right == TypeSlot::Domain)
                        .expect("cross-name op has a Domain/Domain signature");
                    let returns = dd_sig.render(&dom_l).returns;
                    entries.push(unsupported_entry(
                        &dom_l,
                        op,
                        [
                            SqlParam {
                                name: "a",
                                ty: dom_l.clone(),
                            },
                            SqlParam {
                                name: "b",
                                ty: dom_r.clone(),
                            },
                        ],
                        &returns,
                    ));
                }
                operators.push(operator_entry(op, &dom_l, &dom_r, is_supported));
            }
        }
    }

    // REQUIRE: both members' types + every per-domain functions file (extractors).
    let mut requires = vec![V3_SCHEMA.to_string()];
    for name in [a, b] {
        requires.push(types_path(name));
        for d in family.domains {
            requires.push(scalar_path(name, &format!("{}_functions.sql", d.full_name(name))));
        }
    }

    let ctx = CrossContext {
        requires,
        a: a.to_string(),
        b: b.to_string(),
        entries,
        operators,
    };
    environment()
        .get_template("cross.sql")
        .unwrap()
        .render(&ctx)
        .expect("render cross.sql")
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
    generate_type_named(spec.name, spec.domains, out_dir, &[])
}

/// Regenerate one type NAME's surface (its domain set) into `out_dir`,
/// crash-safely, PLUS any `extra` (path, body) files that belong in the same
/// dir and must survive the orphan sweep (e.g. cross-name operator files in a
/// canonical dir). The name-parameterized core of `generate_type`.
///
/// The `extra` set is included in BOTH the write set and the keep set, so the
/// orphan sweep never deletes a cross file that this same pass just wrote (R4).
pub fn generate_type_named(
    name: &str,
    domains: &[Domain],
    out_dir: &Path,
    extra: &[(PathBuf, String)],
) -> Result<Vec<PathBuf>, WriteError> {
    let mut rendered = render_type_named(name, domains, out_dir);
    rendered.extend(extra.iter().cloned());
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
        // Cross-name operator files cover EVERY unordered pair of names in the
        // group (canonical + every alias), not just canonical×alias — otherwise
        // two aliases of one family (e.g. `int4` and `int`) would compare via
        // native jsonb, the exact silent-degradation this feature exists to
        // close. Each pair's file lives in the dir of its FIRST member (group
        // order is canonical-first, so a canonical×alias file lands in the
        // canonical dir, unchanged), written together with that dir's surface so
        // the per-dir orphan sweep keeps it (R4). With one alias per family this
        // is exactly the previous canonical×alias behaviour.
        let group = spec.group_names();
        for name in group.iter().copied() {
            // Cross files owned by this dir: (name, b) for every b that follows
            // `name` in the group — deterministic order, no HashMap.
            let extra: Vec<(PathBuf, String)> = group
                .iter()
                .copied()
                .skip_while(|&g| g != name)
                .skip(1)
                .map(|b| {
                    (
                        scalars_root.join(name).join(format!("{name}__{b}_cross.sql")),
                        render_cross_file(spec, name, b),
                    )
                })
                .collect();
            let out_dir = scalars_root.join(name);
            let written = generate_type_named(name, spec.domains, &out_dir, &extra)?;
            for p in &written {
                let rel = p.strip_prefix(out_root).unwrap_or(p);
                println!("generated {}", rel.display());
            }
            println!("generated {} files for {name}", written.len());
            all_written.extend(written.iter().cloned());
        }
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

    let names: Vec<String> = eql_domains::scalar_families()
        .flat_map(|s| s.group_names().into_iter().map(String::from))
        .collect();
    println!(
        "codegen: ok ({} type surfaces: {})",
        names.len(),
        names.join(", ")
    );
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
        assert!(!names.contains(&"integer_aggregates.sql".to_string()));
        assert!(!names.contains(&"integer_eq_aggregates.sql".to_string()));
        assert!(names.contains(&"integer_ord_ore_aggregates.sql".to_string()));
        assert!(names.contains(&"integer_ord_aggregates.sql".to_string()));
        assert!(names.contains(&"integer_ord_ope_aggregates.sql".to_string()));
        // 1 types + 2 per domain (5 domains) + 3 ord-capable aggregates.
        assert_eq!(written.len(), 14);
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
    fn unsupported_entry_carries_escaped_per_entry_domain_lit() {
        use crate::consts::sql_str;
        use crate::context::{unsupported_entry, FnEntry, SqlParam};
        use crate::operator_surface::operator;

        let dom = "public.int4_eq";
        let entry = unsupported_entry(
            dom, // NEW: per-entry left domain
            &operator("<"),
            [
                SqlParam {
                    name: "a",
                    ty: dom.into(),
                },
                SqlParam {
                    name: "b",
                    ty: "public.integer_eq".into(),
                },
            ],
            "boolean",
        );
        match entry {
            FnEntry::Unsupported {
                dom: d,
                domain_lit,
                operator_lit,
                ..
            } => {
                assert_eq!(d, "public.int4_eq");
                assert_eq!(domain_lit, sql_str("public.int4_eq"));
                assert_eq!(operator_lit, "<");
            }
            _ => panic!("expected Unsupported"),
        }

        // The sql_str quote-doubling behaviour is still covered: a quote-bearing
        // left domain doubles the quote in the RAISE literal.
        let quoted = "eql_v3.o'dom";
        let entry = unsupported_entry(
            quoted,
            &operator("<"),
            [
                SqlParam {
                    name: "a",
                    ty: quoted.into(),
                },
                SqlParam {
                    name: "b",
                    ty: quoted.into(),
                },
            ],
            "boolean",
        );
        match entry {
            FnEntry::Unsupported { domain_lit, .. } => {
                assert_eq!(domain_lit, "eql_v3.o''dom"); // quote doubled by sql_str
            }
            _ => panic!("expected Unsupported"),
        }
    }

    #[test]
    fn generate_all_emits_alias_dir_and_cross_file_for_aliased_family() {
        // Requires the catalog to declare integer's int4 alias (Task 2).
        let d = crate::writer::test_support::tempdir();
        let root = d.path();
        generate_all(root).unwrap();

        let scalars = root.join(V3_SCALARS_DIR);
        // canonical dir
        assert!(scalars.join("integer/integer_types.sql").exists());
        // alias dir with its own full surface
        assert!(scalars.join("int4/int4_types.sql").exists());
        assert!(scalars.join("int4/int4_eq_functions.sql").exists());
        assert!(scalars.join("int4/int4_eq_operators.sql").exists());
        assert!(scalars.join("int4/int4_ord_aggregates.sql").exists());
        // cross file in the canonical dir
        assert!(scalars.join("integer/integer__int4_cross.sql").exists());
        // a non-aliased family emits no cross file
        assert!(!scalars.join("date/date__int4_cross.sql").exists());
    }

    // [fix R4] The cross file lives in the CANONICAL dir, whose per-type orphan
    // sweep must NOT delete it. Regenerating twice must leave it intact (idempotent,
    // not delete-then-rewrite).
    #[test]
    fn regenerating_preserves_cross_file_in_canonical_dir() {
        let d = crate::writer::test_support::tempdir();
        let root = d.path();
        generate_all(root).unwrap();
        let cross = root
            .join(V3_SCALARS_DIR)
            .join("integer/integer__int4_cross.sql");
        let first = std::fs::read_to_string(&cross).unwrap();
        generate_all(root).unwrap(); // second pass over the just-written tree
        assert!(
            cross.exists(),
            "cross file was swept by the canonical dir orphan pass"
        );
        assert_eq!(first, std::fs::read_to_string(&cross).unwrap());
    }

    // [fix R9] A stray alias artefact (dir + in-canonical-dir cross file) that is
    // NOT declared by the catalog must be swept, while the real int4 alias dir and
    // its cross file survive — marker-aware orphan removal at both the scalars-root
    // and canonical-dir levels.
    #[test]
    fn dropping_an_alias_sweeps_its_dir_and_cross_file() {
        let d = crate::writer::test_support::tempdir();
        let root = d.path();
        let scalars = root.join(V3_SCALARS_DIR);
        let s = spec("integer");
        generate_all(root).unwrap();
        let cross = scalars.join("integer/integer__int4_cross.sql");
        assert!(cross.exists(), "the real int4 cross file exists after gen");

        // Seed stray alias artefacts as if a now-removed alias "int4_bogus" had
        // been generated: a full alias dir + an in-canonical-dir cross file, both
        // marker-bearing.
        let stray_dir = scalars.join("int4_bogus");
        generate_type_named("int4_bogus", s.domains, &stray_dir, &[]).unwrap();
        let stray_cross = scalars.join("integer/integer__int4_bogus_cross.sql");
        std::fs::write(
            &stray_cross,
            format!("{}\n-- stray\n", crate::consts::AUTO_GENERATED_MARKER),
        )
        .unwrap();

        generate_all(root).unwrap();
        // The sweep is marker-aware and removes generated FILES (matching
        // `generate_all_prunes_orphaned_type_dir`, which leaves the now-empty dir);
        // the stray alias surface's generated files and its in-canonical-dir cross
        // file must both be gone.
        assert!(
            !stray_dir.join("int4_bogus_types.sql").exists(),
            "orphaned alias surface not swept"
        );
        assert!(!stray_cross.exists(), "orphaned cross file not swept");
        assert!(cross.exists(), "the real int4 cross file must survive");
        assert!(
            root.join(V3_SCALARS_DIR).join("int4/int4_types.sql").exists(),
            "the real int4 alias surface must survive"
        );
    }

    #[test]
    fn cross_file_emits_both_directions_supported_wrappers_and_blockers() {
        // integer/int4 group. The _eq role supports = and <> (public cross
        // wrappers); the other 7 cross ops are internal blockers. Both directions
        // (int4->integer AND integer->int4) must appear. No casts.
        let s = spec("integer");
        let sql = render_cross_file(s, "integer", "int4");

        // supported cross wrapper, both directions
        assert!(sql.contains("CREATE FUNCTION eql_v3.eq(a public.int4_eq, b public.integer_eq)"));
        assert!(sql.contains("CREATE FUNCTION eql_v3.eq(a public.integer_eq, b public.int4_eq)"));
        // supported cross OPERATOR, both directions
        assert!(sql.contains("LEFTARG = public.int4_eq, RIGHTARG = public.integer_eq"));
        assert!(sql.contains("LEFTARG = public.integer_eq, RIGHTARG = public.int4_eq"));
        // unsupported cross op on the eq role is a blocker (internal, plpgsql)
        assert!(
            sql.contains("CREATE FUNCTION eql_v3_internal.lt(a public.int4_eq, b public.integer_eq)")
        );
        // ordered role supports < etc. as a public cross wrapper
        assert!(
            sql.contains("CREATE FUNCTION eql_v3.lt(a public.int4_ord, b public.integer_ord)")
        );
        // never a cast, never a path/key operator cross (no Domain/Domain sig)
        assert!(!sql.contains("CREATE CAST"));
        assert!(!sql.contains("eql_v3_internal.\"->\"(a public.int4"));
        // R1 GUARD: every cross blocker names its LEFT domain in the RAISE — never
        // the empty string that a file-level domain_lit would produce.
        assert!(sql.contains("'public.int4_eq'"));
        assert!(!sql.contains("is not supported for %', '<', ''"));
        // blockers must be plpgsql and never STRICT. (Match the `IMMUTABLE STRICT`
        // modifier specifically — a bare "STRICT" also appears as a substring of
        // the `RESTRICT = ...` operator metadata in the trailing CREATE OPERATOR
        // block that the final split-block sweeps up.)
        for block in sql.split("CREATE FUNCTION").skip(1) {
            if block.contains("RAISE EXCEPTION") {
                assert!(block.contains("LANGUAGE plpgsql"));
                assert!(!block.contains("IMMUTABLE STRICT"));
            }
        }
        // R3 GUARD: the `||` cross op is a blocker returning jsonb (not boolean),
        // derived from its signature, not a hardcoded symbol match.
        assert!(sql.contains("eql_v3_internal.") && sql.contains("RETURNS jsonb")); // the || blocker
        // header + REQUIRE edges for both members' types AND their extractor fns
        assert!(sql.starts_with(&format!("{}\n", crate::consts::AUTO_GENERATED_MARKER)));
        assert!(sql.contains("-- REQUIRE: src/v3/scalars/integer/integer_types.sql"));
        assert!(sql.contains("-- REQUIRE: src/v3/scalars/int4/int4_types.sql"));
        assert!(sql.contains("-- REQUIRE: src/v3/scalars/integer/integer_eq_functions.sql"));
        assert!(sql.contains("-- REQUIRE: src/v3/scalars/int4/int4_eq_functions.sql"));
    }

    #[test]
    fn render_cross_file_is_symmetric_for_an_alias_by_alias_pair() {
        // The all-pairs driver (generate_all) emits a cross file for every
        // unordered pair of group names — including alias×alias when a family
        // declares two aliases. `render_cross_file` must produce a correct
        // both-directions surface for ANY pair of names, not just
        // canonical×alias. Here: a hypothetical `int4`×`int` pair over integer's
        // domain set.
        let s = spec("integer");
        let sql = render_cross_file(s, "int4", "int");
        // supported eq wrapper, both directions between the two aliases
        assert!(sql.contains("CREATE FUNCTION eql_v3.eq(a public.int4_eq, b public.int_eq)"));
        assert!(sql.contains("CREATE FUNCTION eql_v3.eq(a public.int_eq, b public.int4_eq)"));
        // supported ordered wrapper, both directions
        assert!(sql.contains("CREATE FUNCTION eql_v3.lt(a public.int4_ord, b public.int_ord)"));
        assert!(sql.contains("CREATE FUNCTION eql_v3.lt(a public.int_ord, b public.int4_ord)"));
        // CREATE OPERATOR both directions
        assert!(sql.contains("LEFTARG = public.int4_eq, RIGHTARG = public.int_eq"));
        assert!(sql.contains("LEFTARG = public.int_eq, RIGHTARG = public.int4_eq"));
        // REQUIRE edges name BOTH members (neither is the canonical `integer`)
        assert!(sql.contains("-- REQUIRE: src/v3/scalars/int4/int4_types.sql"));
        assert!(sql.contains("-- REQUIRE: src/v3/scalars/int/int_types.sql"));
        assert!(!sql.contains("public.integer_eq"));
    }

    #[test]
    fn render_type_named_uses_alias_name_not_family_name() {
        // Render integer's domain set under the alias name "int4": every emitted
        // path and every CREATE DOMAIN must say int4, never integer.
        let s = spec("integer");
        let d = crate::writer::test_support::tempdir();
        let out = d.path().join("int4");
        let rendered = render_type_named("int4", s.domains, &out);
        let types = rendered
            .iter()
            .find(|(p, _)| p.file_name().unwrap() == "int4_types.sql")
            .map(|(_, body)| body.clone())
            .expect("int4_types.sql rendered");
        assert!(types.contains("CREATE DOMAIN public.int4 AS jsonb"));
        assert!(types.contains("CREATE DOMAIN public.int4_eq AS jsonb"));
        assert!(!types.contains("public.integer"));
        assert!(rendered
            .iter()
            .any(|(p, _)| p.file_name().unwrap() == "int4_eq_functions.sql"));
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
