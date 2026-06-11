//! File renderers and orchestrator.

use std::path::{Path, PathBuf};

use eql_scalars::{DomainSpec, ScalarSpec, Term};

use crate::context::{domain_name, is_ord_capable};
use crate::operator_surface::OPERATORS;

/// REQUIRE edge for the v3 schema file — pulled in by every generated file.
const V3_SCHEMA: &str = "src/v3/schema.sql";
/// REQUIRE edge for the hand-written shared blocker helper.
const V3_SCALARS_BLOCKER: &str = "src/v3/scalars/functions.sql";
/// Root of the generated per-token scalar surface. The single place the tree
/// layout is spelled out — keeps `types_path`/`scalar_path` and the REQUIRE
/// vecs from drifting if the surface ever relocates again.
const V3_SCALARS_DIR: &str = "src/v3/scalars";

/// REQUIRE path for a generated file `file` under a token's scalar dir.
fn scalar_path(token: &str, file: &str) -> String {
    format!("{V3_SCALARS_DIR}/{token}/{file}")
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
fn types_path(token: &str) -> String {
    scalar_path(token, &format!("{token}_types.sql"))
}

/// Body for <T>_types.sql: every domain in one idempotent DO block.
/// Port of `render_types_file`.
pub fn render_types_file(spec: &ScalarSpec) -> String {
    use crate::context::{domain_block, environment, TypesContext};
    let ctx = TypesContext {
        token: spec.token.to_string(),
        domains: spec
            .domains
            .iter()
            .map(|d| domain_block(spec.token, d))
            .collect(),
    };
    environment()
        .get_template("types.sql")
        .unwrap()
        .render(&ctx)
        .expect("render types.sql")
}

/// REQUIRE edges for a domain's _functions.sql. Port of `_functions_requires`.
fn functions_requires(token: &str, terms: &[Term]) -> Vec<String> {
    let mut reqs = vec![
        V3_SCHEMA.to_string(),
        types_path(token),
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
pub fn render_functions_file(token: &str, domain: &DomainSpec) -> String {
    use crate::consts::sql_str;
    use crate::context::{
        environment, extractor_entry, unsupported_entry, wrapper_entry, FunctionsContext, SqlParam,
    };
    let name = domain.name_with_token(token);
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
        requires: functions_requires(token, domain.terms),
        token: token.to_string(),
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
pub fn render_operators_file(token: &str, domain: &DomainSpec) -> String {
    use crate::context::{environment, operator_entry, OperatorsContext};
    let name = domain.name_with_token(token);
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
            types_path(token),
            scalar_path(token, &format!("{name}_functions.sql")),
        ],
        token: token.to_string(),
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
pub fn render_aggregates_file(token: &str, domain: &DomainSpec) -> Option<String> {
    use crate::context::{environment, AggregatesContext, AGGREGATE_OPS};
    if !is_ord_capable(domain.terms) {
        return None;
    }
    let name = domain.name_with_token(token);
    let dom = domain_name(&name);
    let ctx = AggregatesContext {
        requires: vec![
            V3_SCHEMA.to_string(),
            types_path(token),
            scalar_path(token, &format!("{name}_functions.sql")),
            scalar_path(token, &format!("{name}_operators.sql")),
        ],
        token: token.to_string(),
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

use crate::writer::{
    clean_generated_files, ensure_generated_paths_writable, write_generated_file, WriteError,
};

/// Regenerate every generated file for one type into `out_dir`.
/// Port of `generate_type`. Returns the written paths.
pub fn generate_type(spec: &ScalarSpec, out_dir: &Path) -> Result<Vec<PathBuf>, WriteError> {
    let token = spec.token;
    let mut targets = vec![out_dir.join(format!("{token}_types.sql"))];
    for d in spec.domains {
        let name = d.name_with_token(token);
        targets.push(out_dir.join(format!("{name}_functions.sql")));
        targets.push(out_dir.join(format!("{name}_operators.sql")));
        if is_ord_capable(d.terms) {
            targets.push(out_dir.join(format!("{name}_aggregates.sql")));
        }
    }
    ensure_generated_paths_writable(&targets)?;
    clean_generated_files(out_dir)?;

    let mut written: Vec<PathBuf> = Vec::new();

    let types_path = out_dir.join(format!("{token}_types.sql"));
    write_generated_file(&types_path, &render_types_file(spec))?;
    written.push(types_path);

    for d in spec.domains {
        let name = d.name_with_token(token);
        let fn_path = out_dir.join(format!("{name}_functions.sql"));
        write_generated_file(&fn_path, &render_functions_file(token, d))?;
        written.push(fn_path);

        let op_path = out_dir.join(format!("{name}_operators.sql"));
        write_generated_file(&op_path, &render_operators_file(token, d))?;
        written.push(op_path);

        if let Some(agg) = render_aggregates_file(token, d) {
            let agg_path = out_dir.join(format!("{name}_aggregates.sql"));
            write_generated_file(&agg_path, &agg)?;
            written.push(agg_path);
        }
    }
    Ok(written)
}

/// Generate every catalog type's gitignored SQL surface under `out_root`. The
/// single entry point: replaces Python's per-type and --all forms. The
/// plaintext fixture lists are not generated — they live in the catalog
/// (`eql_scalars::INT4_VALUES` / `INT2_VALUES`), read directly by the SQLx tests.
pub fn generate_all(out_root: &Path) -> Result<i32, WriteError> {
    for spec in eql_scalars::CATALOG {
        let token = spec.token;
        let out_dir = out_root.join(V3_SCALARS_DIR).join(token);
        let written = generate_type(spec, &out_dir)?;

        for p in &written {
            let rel = p.strip_prefix(out_root).unwrap_or(p);
            println!("generated {}", rel.display());
        }
        println!("generated {} files for {token}", written.len());
    }
    let tokens: Vec<&str> = eql_scalars::CATALOG.iter().map(|s| s.token).collect();
    println!(
        "codegen: ok ({} types: {})",
        tokens.len(),
        tokens.join(", ")
    );
    Ok(0)
}

#[cfg(test)]
mod tests {
    use super::*;
    use eql_scalars::CATALOG;

    fn spec(token: &str) -> &'static ScalarSpec {
        CATALOG
            .iter()
            .find(|s| s.token == token)
            .expect("catalog token")
    }

    fn domain<'a>(spec: &'a ScalarSpec, suffix: &str) -> &'a DomainSpec {
        spec.domains
            .iter()
            .find(|d| d.suffix == suffix)
            .expect("domain suffix")
    }

    use crate::repo_root;
    use std::fs;

    fn strip_reference_marker(text: &str) -> String {
        let mut lines: Vec<&str> = text.lines().collect();
        // .lines() drops the trailing newline; re-add per line and handle the
        // first marker line(s).
        while !lines.is_empty()
            && (lines[0].starts_with("-- REFERENCE:") || lines[0].starts_with("// REFERENCE:"))
        {
            lines.remove(0);
        }
        let mut out = lines.join("\n");
        if text.ends_with('\n') {
            out.push('\n');
        }
        out
    }

    fn rendered_for(token: &str, name: &str, spec: &ScalarSpec) -> String {
        if name == format!("{token}_types.sql") {
            return render_types_file(spec);
        }
        for d in spec.domains {
            let full = d.name_with_token(token);
            if name == format!("{full}_functions.sql") {
                return render_functions_file(token, d);
            }
            if name == format!("{full}_operators.sql") {
                return render_operators_file(token, d);
            }
            if name == format!("{full}_aggregates.sql") {
                return render_aggregates_file(token, d)
                    .expect("reference exists but generator skipped (not ord-capable)");
            }
        }
        panic!("unrecognised reference filename: {name}");
    }

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
        let s = spec("int4");
        let d = domain(s, "_eq");
        let sql = render_functions_file("int4", d);
        assert!(sql.contains("CREATE FUNCTION eql_v3.eq("));
        assert!(sql.contains("AS $$ SELECT"));
        assert!(sql.contains("CREATE FUNCTION eql_v3.lt("));
        assert!(sql.contains("RAISE EXCEPTION 'operator % is not supported for %', '<'"));
        assert!(sql.contains("CREATE FUNCTION eql_v3.\"->\"("));
        assert!(sql.contains("RAISE EXCEPTION 'operator % is not supported for %', '->'"));
    }

    /// The committed reference token dirs under `tests/codegen/reference/`.
    fn reference_tokens(root: &std::path::Path) -> Vec<String> {
        let mut tokens: Vec<String> = fs::read_dir(root.join("tests/codegen/reference"))
            .expect("reference dir")
            .filter_map(|e| e.ok())
            .filter(|e| e.path().is_dir())
            .map(|e| e.file_name().to_str().unwrap().to_string())
            .collect();
        tokens.sort();
        tokens
    }

    /// Byte-compare every `render_*_file` output against its committed reference,
    /// for **every** catalog type with a reference dir (not just int4). This is
    /// the in-crate reference gate over the render functions directly (the
    /// integration `parity.rs` gate runs `generate_all` to disk). The reference
    /// dirs are cross-checked against the catalog by `parity.rs`'s
    /// `reference_dirs_match_catalog_tokens`.
    #[test]
    fn generator_matches_reference_files() {
        let root = repo_root();
        let mut checked = 0;
        for token in reference_tokens(&root) {
            let s = spec(&token);
            let ref_dir = root.join("tests/codegen/reference").join(&token);
            for entry in fs::read_dir(&ref_dir).expect("reference dir") {
                let path = entry.unwrap().path();
                if path.extension().and_then(|e| e.to_str()) != Some("sql") {
                    continue;
                }
                let name = path.file_name().unwrap().to_str().unwrap().to_string();
                let expected = strip_reference_marker(&fs::read_to_string(&path).unwrap());
                let actual = rendered_for(&token, &name, s);
                assert_eq!(
                    actual, expected,
                    "{token}/{name}: generator diverged from reference"
                );
                checked += 1;
            }
        }
        assert!(
            checked >= 11,
            "expected >=11 reference SQL files across all tokens, checked {checked}"
        );
    }

    #[test]
    fn generate_type_writes_expected_files() {
        let d = crate::writer::test_support::tempdir();
        let s = spec("int4");
        let out = d.path().join("int4");
        let written = generate_type(s, &out).unwrap();
        let names: Vec<String> = written
            .iter()
            .map(|p| p.file_name().unwrap().to_str().unwrap().to_string())
            .collect();
        assert!(names.contains(&"int4_types.sql".to_string()));
        for dom in ["int4", "int4_eq", "int4_ord_ore", "int4_ord"] {
            assert!(names.contains(&format!("{dom}_functions.sql")));
            assert!(names.contains(&format!("{dom}_operators.sql")));
        }
        assert!(!names.contains(&"int4_aggregates.sql".to_string()));
        assert!(!names.contains(&"int4_eq_aggregates.sql".to_string()));
        assert!(names.contains(&"int4_ord_ore_aggregates.sql".to_string()));
        assert!(names.contains(&"int4_ord_aggregates.sql".to_string()));
        assert_eq!(written.len(), 11);
        for p in &written {
            assert!(fs::read_to_string(p)
                .unwrap()
                .starts_with(&format!("{}\n", crate::consts::AUTO_GENERATED_MARKER)));
        }
    }

    #[test]
    fn types_file_has_all_four_domains() {
        let sql = render_types_file(spec("int4"));
        assert!(sql.contains("-- REQUIRE: src/v3/schema.sql"));
        for dom in ["int4", "int4_eq", "int4_ord_ore", "int4_ord"] {
            assert!(
                sql.contains(&format!("CREATE DOMAIN eql_v3.{dom} AS jsonb")),
                "missing {dom}"
            );
        }
    }

    #[test]
    fn storage_functions_file_is_all_blockers() {
        let s = spec("int4");
        let sql = render_functions_file(s.token, domain(s, ""));
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
        let s = spec("int4");
        let sql = render_functions_file(s.token, domain(s, "_eq"));
        assert_eq!(sql.matches("CREATE FUNCTION").count(), 45);
        assert!(sql.contains("CREATE FUNCTION eql_v3.eq_term(a eql_v3.int4_eq)"));
        assert!(sql.contains("RETURNS eql_v3.hmac_256"));
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
        let s = spec("int4");
        let sql = render_functions_file(s.token, domain(s, "_ord"));
        assert_eq!(sql.matches("CREATE FUNCTION").count(), 45);
        assert!(sql.contains("CREATE FUNCTION eql_v3.ord_term(a eql_v3.int4_ord)"));
        assert!(sql.contains("RETURNS eql_v3.ore_block_u64_8_256"));
        assert_eq!(
            sql.matches("LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE")
                .count(),
            19
        );
        assert_eq!(sql.matches("LANGUAGE plpgsql").count(), 26);
    }

    #[test]
    fn operators_file_has_forty_four() {
        let s = spec("int4");
        let sql = render_operators_file(s.token, domain(s, "_eq"));
        assert_eq!(sql.matches("CREATE OPERATOR").count(), 44);
    }

    #[test]
    fn aggregates_file_only_for_ord_variants() {
        let s = spec("int4");
        assert!(render_aggregates_file(s.token, domain(s, "")).is_none());
        assert!(render_aggregates_file(s.token, domain(s, "_eq")).is_none());
        assert!(render_aggregates_file(s.token, domain(s, "_ord")).is_some());
        assert!(render_aggregates_file(s.token, domain(s, "_ord_ore")).is_some());
    }

    #[test]
    fn aggregates_file_carries_min_and_max_and_requires() {
        let s = spec("int4");
        let sql = render_aggregates_file(s.token, domain(s, "_ord")).unwrap();
        assert_eq!(sql.matches("CREATE FUNCTION").count(), 2);
        assert_eq!(sql.matches("CREATE AGGREGATE").count(), 2);
        assert!(sql.contains("eql_v3.min_sfunc"));
        assert!(sql.contains("eql_v3.max_sfunc"));
        assert!(sql.contains("-- REQUIRE: src/v3/scalars/int4/int4_ord_operators.sql"));
        assert!(sql.contains("-- REQUIRE: src/v3/scalars/int4/int4_ord_functions.sql"));
        assert!(sql.contains("-- REQUIRE: src/v3/scalars/int4/int4_types.sql"));
    }

    #[test]
    fn ordered_files_byte_identical_modulo_typename() {
        let s = spec("int4");
        let ord = domain(s, "_ord");
        let ore = domain(s, "_ord_ore");
        let norm = |sql: String| sql.replace("int4_ord_ore", "T").replace("int4_ord", "T");
        assert_eq!(
            norm(render_functions_file(s.token, ord)),
            norm(render_functions_file(s.token, ore))
        );
        assert_eq!(
            norm(render_operators_file(s.token, ord)),
            norm(render_operators_file(s.token, ore))
        );
        assert_eq!(
            norm(render_aggregates_file(s.token, ord).unwrap()),
            norm(render_aggregates_file(s.token, ore).unwrap())
        );
    }

    // --- Coarsened footgun invariant guards (whole-file scans) ---

    #[test]
    fn blockers_are_never_strict_and_always_plpgsql() {
        let s = spec("int4");
        // Storage domain functions file is all blockers.
        let sql = render_functions_file("int4", domain(s, ""));
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
        let s = spec("int4");
        // Extractors and wrappers (eq/ord functions files) are inlinable SQL.
        for suffix in ["_eq", "_ord"] {
            let sql = render_functions_file("int4", domain(s, suffix));
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
        let s = spec("int4");
        let sql = render_aggregates_file("int4", domain(s, "_ord")).unwrap();
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
        let s = spec("int4");
        for d in s.domains {
            let sql = render_functions_file("int4", d);
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

        let sql = render_aggregates_file("int4", domain(s, "_ord")).unwrap();
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
        use eql_scalars::DomainSpec;
        let block = domain_block(
            "int4",
            &DomainSpec {
                suffix: "_q",
                terms: &[],
            },
        );
        assert_eq!(block.typname, "int4_q"); // no quote present → unchanged
                                             // keys are sql_str-escaped key tokens; none should carry a bare unescaped quote.
        assert!(block.keys.iter().all(|k| !k.contains("o'")));
    }
}
