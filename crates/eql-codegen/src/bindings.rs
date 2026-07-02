//! The Rust payload-bindings emitter: renders `eql_domains::CATALOG` to the
//! committed `crates/eql-bindings/src/v3/<family>.rs` structs + `DomainType`
//! impls and the generated `inventory.rs` (`all()`), the same generate-to-
//! committed-source mechanism `generate.rs` uses for SQL. Token stream via
//! `quote!`, formatted by `prettyplease::unparse` then the repo's stable
//! `rustfmt` (prettyplease is rustfmt-clean but not rustfmt-identical), with
//! the `// @generated` ownership marker prepended as line 1.

use std::path::{Path, PathBuf};

use proc_macro2::TokenStream;
use quote::{format_ident, quote};

use eql_domains::{Domain, DomainFamily, Shape, Term, CATALOG, ENVELOPE_KEYS};

use crate::consts::RUST_GENERATED_MARKER;
use crate::writer::{
    ensure_generated_paths_writable, normalized_set, remove_generated_orphans,
    write_generated_file, GeneratedKind, WriteError,
};

/// Format a token stream into committed Rust source. `prettyplease::unparse`
/// gives deterministic, parseable output; the `@generated` marker is prepended
/// as line 1 (syn/prettyplease drop free-standing line comments, so it cannot
/// live inside the token stream); then the whole file is run through `rustfmt`
/// so it is byte-for-byte what `cargo fmt --check` (`mise run test:crates`)
/// expects.
pub fn format_rs(tokens: TokenStream) -> String {
    let file: syn::File = syn::parse2(tokens).expect("emit syntactically valid Rust");
    let body = prettyplease::unparse(&file);
    let with_marker = format!("{RUST_GENERATED_MARKER}\n{body}");
    rustfmt(&with_marker)
}

/// Pipe Rust source through the repo's `rustfmt` (stdin → stdout). Fails loudly:
/// codegen is a dev-time tool and `rustfmt` is always present where `cargo fmt`
/// runs. `rustfmt` preserves the leading `// @generated` line comment, so the
/// marker stays exactly line 1.
fn rustfmt(src: &str) -> String {
    use std::io::Write;
    use std::process::{Command, Stdio};

    let mut child = Command::new("rustfmt")
        .args(["--edition", "2021"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .expect("spawn rustfmt (is the Rust toolchain on PATH?)");
    child
        .stdin
        .take()
        .expect("rustfmt stdin")
        .write_all(src.as_bytes())
        .expect("write to rustfmt");
    let out = child.wait_with_output().expect("wait for rustfmt");
    assert!(
        out.status.success(),
        "rustfmt failed: {}",
        String::from_utf8_lossy(&out.stderr)
    );
    String::from_utf8(out.stdout).expect("rustfmt output is UTF-8")
}

/// Capability label for a domain's single catalog-derived doc line, keyed on
/// the bare domain name. The match is keyed on the `&str` bare name (finer than
/// the typed [`eql_domains::Role`], which collapses `match`/`search` into
/// `Ord`), so it cannot be made exhaustive at the type level. Instead the
/// catch-all `panic!`s: an unmapped bare-domain name aborts codegen loudly,
/// forcing a deliberate label choice rather than silently emitting generic-but-
/// wrong doc text — preserving the "compile-checked catalog" guarantee.
fn capability_label(domain_name: &str) -> &'static str {
    match domain_name {
        "" => "storage-only domain",
        "eq" => "equality domain",
        "ord" | "ord_ore" => "ordering domain",
        "match" => "match domain",
        "search" => "search domain",
        other => panic!(
            "unmapped bare domain name {other:?} — add it to capability_label \
             in crates/eql-codegen/src/bindings.rs"
        ),
    }
}

/// Render the catalog-derived struct doc lines for a domain: a summary line
/// (`` `eql_v3.<name>` — <label>. ``) and a detail line listing the supported
/// SQL operators and the required payload keys. Every part is derived from data
/// the catalog already carries — the capability label, the operator union
/// (`Term::operators_for_terms`), and the key list (`ENVELOPE_KEYS` ++
/// `Term::term_json_keys`) — so it stays deterministic and cannot drift from the
/// payload shape. No free-form prose and no field docs: per-field semantics live
/// on the shared term newtypes (`terms.rs`) and per-family caveats in `mod.rs`.
fn struct_doc_lines(full: &str, domain: &Domain) -> [String; 3] {
    // Leading space matches the `///` doc-comment convention (`#[doc = " …"]`):
    // rustfmt renders it as `/// …` and ts-rs as ` * …`. Without it the emitted
    // JSDoc/`///` lose the space after the prefix (`*`text`). schemars strips the
    // single leading space, so JSON Schema `description` is unaffected.
    let summary = format!(" `eql_v3.{full}` — {}.", capability_label(domain.name));

    let ops = Term::operators_for_terms(domain.terms);
    let ops_str = if ops.is_empty() {
        "none".to_string()
    } else {
        ops.iter()
            .map(|o| format!("`{o}`"))
            .collect::<Vec<_>>()
            .join(" ")
    };

    let keys_str = ENVELOPE_KEYS
        .iter()
        .copied()
        .chain(Term::term_json_keys(domain.terms))
        .map(|k| format!("`{k}`"))
        .collect::<Vec<_>>()
        .join(" ");

    let detail = format!(" Operators: {ops_str}. Required keys: {keys_str}.");
    // Blank middle line so rustdoc/schemars/ts-rs treat the summary as the short
    // description and the operators/keys line as the body.
    [summary, String::new(), detail]
}

/// One payload struct + its three-method `DomainType` impl. A catalog-derived
/// struct doc (summary + operators + required keys — see [`struct_doc_lines`]),
/// no field docs. Term fields come from `Term::payload_terms`, matching on the
/// enum for the field key and its newtype. The `schema` method returns
/// `schemars::Schema` (1.x).
fn render_struct(family: &DomainFamily, domain: &Domain) -> TokenStream {
    let full = domain.full_name(family.name);
    let ident = format_ident!("{}", domain.struct_ident(family.name));
    let sql_domain = format!("eql_v3.{full}");
    let [doc_summary, doc_blank, doc_detail] = struct_doc_lines(&full, domain);

    // The envelope triple is hardcoded (not looped over `ENVELOPE_KEYS`) because
    // each key maps to a distinct Rust type: `v: SchemaVersion`, `i: Identifier`,
    // `c: Ciphertext`. The order and membership must stay in lockstep with
    // `eql_domains::ENVELOPE_KEYS` — `envelope_fields_match_catalog_keys` (below)
    // fails if that ever diverges.
    let mut fields = TokenStream::new();
    fields.extend(quote! { pub v: SchemaVersion, });
    fields.extend(quote! { pub i: Identifier, });
    fields.extend(quote! { pub c: Ciphertext, });
    for term in Term::payload_terms(domain.terms) {
        let fid = format_ident!("{}", term.json_key());
        let tid = format_ident!("{}", term.binding_newtype());
        fields.extend(quote! { pub #fid: #tid, });
    }

    quote! {
        #[doc = #doc_summary]
        #[doc = #doc_blank]
        #[doc = #doc_detail]
        #[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
        #[ts(export, export_to = "v3/")]
        #[serde(deny_unknown_fields)]
        pub struct #ident {
            #fields
        }

        impl DomainType for #ident {
            fn sql_domain_static() -> &'static str {
                #sql_domain
            }
            fn sql_domain(&self) -> &'static str {
                Self::sql_domain_static()
            }
            fn schema(&self) -> Schema {
                schema_for!(#ident)
            }
        }
    }
}

/// Render a whole family module (`int4.rs`, `text.rs`, …): the import header
/// (exactly the term newtypes the family uses) followed by every domain's
/// struct + impl.
pub fn render_family_bindings(family: &DomainFamily) -> String {
    let mut used: Vec<&'static str> = vec!["Ciphertext"];
    for d in family.domains {
        for term in Term::payload_terms(d.terms) {
            let t = term.binding_newtype();
            if !used.contains(&t) {
                used.push(t);
            }
        }
    }
    let used_idents: Vec<_> = used.iter().map(|t| format_ident!("{t}")).collect();

    let structs: TokenStream = family
        .domains
        .iter()
        .map(|d| render_struct(family, d))
        .collect();

    let mod_doc = format!(
        " The `{}` encrypted-domain family — generated from the eql-domains catalog.",
        family.name
    );

    let file = quote! {
        #![doc = #mod_doc]

        use schemars::{schema_for, JsonSchema, Schema};

        use crate::v3::terms::{ #(#used_idents),* };
        use crate::v3::DomainType;
        use crate::{Identifier, SchemaVersion};
        use serde::{Deserialize, Serialize};
        use ts_rs::TS;

        #structs
    };

    format_rs(file)
}

/// Render the generated `crates/eql-bindings/src/v3/inventory.rs`: just `all()`
/// in CATALOG order, referencing the family structs through `super::`. The
/// `pub mod` declarations, the trait re-export, the trait/newtypes, and the
/// architectural module doc all stay hand-written (mod.rs / domain_type.rs /
/// terms.rs).
pub fn render_inventory_rs() -> String {
    let all_entries: TokenStream = CATALOG
        .iter()
        .flat_map(|f| {
            let m = format_ident!("{}", f.name);
            f.domains
                .iter()
                .map(move |d| {
                    let ident = match d.shape {
                        Shape::Scalar => d.struct_ident(f.name),
                        Shape::SteVecDocument => "SteVecDocument".to_string(),
                        Shape::SteVecEntry => "SteVecEntry".to_string(),
                        Shape::SteVecQuery => "SteVecQuery".to_string(),
                    };
                    let s = format_ident!("{}", ident);
                    quote! { Box::new(PhantomData::<super::#m::#s>), }
                })
                .collect::<Vec<_>>()
        })
        .collect();

    let mod_doc = " The `all()` inventory — every v3 domain payload type in \
                   eql-domains::CATALOG order. Generated from the catalog; the \
                   DomainType trait, the shared newtypes, and the architectural \
                   module doc stay hand-written (domain_type.rs / terms.rs / mod.rs).";

    let file = quote! {
        #![doc = #mod_doc]

        use std::marker::PhantomData;

        use super::domain_type::DomainType;

        /// Every v3 domain type, in `eql-domains::CATALOG` order — generated.
        pub fn all() -> Vec<Box<dyn DomainType>> {
            vec![
                #all_entries
            ]
        }
    };

    format_rs(file)
}

/// Relative path (from repo root) of the generated v3 bindings directory.
const V3_BINDINGS_DIR: &str = "crates/eql-bindings/src/v3";

/// Render every binding file to memory (NO filesystem writes): one
/// `(<dir>/<family>.rs, body)` per catalog family in CATALOG order, then
/// `inventory.rs`. Kept separate from the write orchestration so a render panic
/// — an unmapped bare-domain name in [`capability_label`], or a missing/failing
/// `rustfmt` in [`format_rs`] — aborts BEFORE [`generate_bindings`] deletes any
/// committed source.
fn render_bindings(dir: &Path) -> Vec<(PathBuf, String)> {
    let mut rendered: Vec<(PathBuf, String)> = eql_domains::scalar_families()
        .map(|f| {
            (
                dir.join(format!("{}.rs", f.name)),
                render_family_bindings(f),
            )
        })
        .collect();
    rendered.push((dir.join("inventory.rs"), render_inventory_rs()));
    rendered
}

/// Regenerate every committed Rust binding file under `out_root`: one
/// `<family>.rs` per catalog family plus the `inventory.rs` `all()` list.
/// Hand-written `terms.rs` / `domain_type.rs` / `mod.rs` carry no marker, so
/// they are never cleaned or clobbered. Returns the written paths.
///
/// Ordering is render-all → preflight → write-all (atomic) → delete-orphans:
/// everything is rendered to memory first, then every current file is written
/// (each via an atomic same-dir temp+rename) BEFORE any stale generated file is
/// deleted. A render panic aborts before the filesystem is touched, and because
/// deletion happens only after all writes succeed, a write error mid-run can
/// never leave committed source deleted-but-not-rewritten. The orphan sweep
/// prunes `<family>.rs` for a type dropped from the catalog, marker-aware so the
/// hand-written `terms.rs` / `domain_type.rs` / `mod.rs` are always preserved.
pub fn generate_bindings(out_root: &Path) -> Result<Vec<PathBuf>, WriteError> {
    let dir = out_root.join(V3_BINDINGS_DIR);

    let rendered = render_bindings(&dir);
    let targets: Vec<PathBuf> = rendered.iter().map(|(p, _)| p.clone()).collect();

    ensure_generated_paths_writable(&targets, GeneratedKind::Rust)?;

    let mut written = Vec::with_capacity(rendered.len());
    for (p, body) in &rendered {
        write_generated_file(p, body, GeneratedKind::Rust)?;
        written.push(p.clone());
    }
    remove_generated_orphans(&dir, GeneratedKind::Rust, &normalized_set(&written))?;

    Ok(written)
}

#[cfg(test)]
mod tests {
    use super::*;
    use eql_domains::CATALOG;
    use quote::quote;

    fn family(name: &str) -> &'static eql_domains::DomainFamily {
        CATALOG.iter().find(|f| f.name == name).expect("family")
    }

    /// Declared field idents of `struct_name` in generated source, in order.
    fn field_idents(src: &str, struct_name: &str) -> Vec<String> {
        let file = syn::parse_file(src).expect("generated source parses");
        for item in &file.items {
            if let syn::Item::Struct(s) = item {
                if s.ident == struct_name {
                    return s
                        .fields
                        .iter()
                        .map(|f| f.ident.as_ref().expect("named field").to_string())
                        .collect();
                }
            }
        }
        panic!("struct {struct_name} not found in generated source");
    }

    #[test]
    fn int4_family_structs_have_pinned_shape() {
        let out = render_family_bindings(family("int4"));
        assert!(out.starts_with(crate::consts::RUST_GENERATED_MARKER));
        for s in [
            "struct Int4 ",
            "struct Int4Eq ",
            "struct Int4OrdOre ",
            "struct Int4Ord ",
        ] {
            assert!(out.contains(s), "missing {s}");
        }
        assert_eq!(
            out.matches(
                "#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]"
            )
            .count(),
            4
        );
        assert_eq!(out.matches("#[ts(export, export_to = \"v3/\")]").count(), 4);
        assert_eq!(out.matches("#[serde(deny_unknown_fields)]").count(), 4);
        assert!(out.contains("`eql_v3.int4_eq` — equality domain."));
        assert!(out.contains("`eql_v3.int4` — storage-only domain."));
        assert!(out.contains("`eql_v3.int4_ord` — ordering domain."));
        assert!(!out.contains("Envelope version"));
        assert!(!out.contains("HMAC-SHA-256 equality term"));
        assert_eq!(field_idents(&out, "Int4"), ["v", "i", "c"]);
        assert_eq!(field_idents(&out, "Int4Eq"), ["v", "i", "c", "hm"]);
        assert_eq!(field_idents(&out, "Int4OrdOre"), ["v", "i", "c", "ob"]);
        assert_eq!(field_idents(&out, "Int4Ord"), ["v", "i", "c", "ob"]);
        assert!(out.contains("impl DomainType for Int4Eq"));
        assert!(out.contains("fn sql_domain_static()"));
        assert!(out.contains("\"eql_v3.int4_eq\""));
        assert!(out.contains("fn sql_domain(&self)"));
        assert!(out.contains("fn schema(&self) -> Schema"));
        assert!(out.contains("schema_for!(Int4Eq)"));
        assert!(out.contains("use crate::v3::terms::"));
        assert!(!out.contains("BloomFilter"));
    }

    #[test]
    fn struct_doc_carries_derivable_operators_and_required_keys() {
        // The struct doc is derived entirely from catalog data already present:
        // the capability label + the operator union (`Term::operators_for_terms`)
        // + the required-key list (`ENVELOPE_KEYS` ++ `Term::term_json_keys`).
        // No field docs, no new free-form catalog prose.
        let int4 = render_family_bindings(family("int4"));

        // Storage-only: no operators.
        assert!(int4.contains("`eql_v3.int4` — storage-only domain."));
        assert!(int4.contains("Operators: none."));
        assert!(int4.contains("Required keys: `v` `i` `c`."));

        // Equality: `=`/`<>` and the `hm` key.
        assert!(int4.contains("`eql_v3.int4_eq` — equality domain."));
        assert!(int4.contains("Operators: `=` `<>`."));
        assert!(int4.contains("Required keys: `v` `i` `c` `hm`."));

        // Ordering: full comparison operators and the `ob` key.
        assert!(int4.contains("Operators: `=` `<>` `<` `<=` `>` `>=`."));
        assert!(int4.contains("Required keys: `v` `i` `c` `ob`."));

        // text_ord carries BOTH `hm` and `ob` — the dual-term distinction that
        // previously lived only in hand-written prose is now derivable in the doc.
        let text = render_family_bindings(family("text"));
        assert!(text.contains("Required keys: `v` `i` `c` `hm` `ob`."));
        assert!(text.contains("`eql_v3.text_match` — match domain."));
        assert!(text.contains("Operators: `@>` `<@`."));
        assert!(text.contains("Required keys: `v` `i` `c` `bf`."));
    }

    #[test]
    fn text_family_includes_bloom_and_dual_term_ord() {
        let out = render_family_bindings(family("text"));
        for s in [
            "struct Text ",
            "struct TextEq ",
            "struct TextMatch ",
            "struct TextOrdOre ",
            "struct TextOrd ",
            "struct TextSearch ",
        ] {
            assert!(out.contains(s), "missing {s}");
        }
        assert!(out.contains("`eql_v3.text_match` — match domain."));
        assert!(out.contains("`eql_v3.text_search` — search domain."));
        assert!(out.contains("bf: BloomFilter"));
        assert_eq!(field_idents(&out, "TextOrd"), ["v", "i", "c", "hm", "ob"]);
        assert_eq!(field_idents(&out, "TextMatch"), ["v", "i", "c", "bf"]);
        assert_eq!(
            field_idents(&out, "TextSearch"),
            ["v", "i", "c", "hm", "ob", "bf"]
        );
    }

    #[test]
    fn bool_storage_only_family_has_one_struct_no_terms() {
        let out = render_family_bindings(family("bool"));
        assert_eq!(out.matches("pub struct ").count(), 1);
        assert!(out.contains("`eql_v3.bool` — storage-only domain."));
        assert_eq!(field_idents(&out, "Bool"), ["v", "i", "c"]);
        assert!(out.contains("use crate::v3::terms::"));
        assert!(!out.contains("Hmac256"));
        assert!(!out.contains("OreBlock256"));
        assert!(!out.contains("BloomFilter"));
    }

    #[test]
    fn generate_bindings_writes_family_files_and_inventory_with_markers() {
        let tmp = crate::writer::test_support::tempdir();
        let written = generate_bindings(tmp.path()).unwrap();
        let dir = tmp.path().join("crates/eql-bindings/src/v3");
        assert_eq!(written.len(), eql_domains::scalar_families().count() + 1);
        assert!(dir.join("int4.rs").is_file());
        assert!(dir.join("text.rs").is_file());
        assert!(dir.join("inventory.rs").is_file());
        assert!(
            !dir.join("mod.rs").exists(),
            "mod.rs stays hand-written; not generated"
        );
        for p in &written {
            let body = std::fs::read_to_string(p).unwrap();
            assert!(
                body.starts_with(crate::consts::RUST_GENERATED_MARKER),
                "{p:?}"
            );
        }
    }

    #[test]
    fn render_bindings_is_side_effect_free_and_complete() {
        // generate_bindings renders to memory BEFORE deleting any committed
        // source, so a render panic aborts before deletion. Lock in the
        // load-bearing property: render writes NOTHING to disk. A pre-existing
        // file in the target dir survives the render call untouched, and render
        // returns one entry per family plus inventory (last).
        let tmp = crate::writer::test_support::tempdir();
        let dir = tmp.path().join(V3_BINDINGS_DIR);
        std::fs::create_dir_all(&dir).unwrap();
        let sentinel = dir.join("int4.rs");
        std::fs::write(&sentinel, "SENTINEL").unwrap();

        let rendered = render_bindings(&dir);

        assert_eq!(rendered.len(), eql_domains::scalar_families().count() + 1);
        assert_eq!(
            std::fs::read_to_string(&sentinel).unwrap(),
            "SENTINEL",
            "render_bindings must not write to disk"
        );
        assert!(rendered.last().unwrap().0.ends_with("inventory.rs"));
        for (p, body) in &rendered {
            assert!(
                body.starts_with(crate::consts::RUST_GENERATED_MARKER),
                "{p:?} body lacks the marker"
            );
        }
    }

    #[test]
    fn inventory_enumerates_all_in_catalog_order() {
        let out = render_inventory_rs();
        assert!(out.starts_with(crate::consts::RUST_GENERATED_MARKER));
        assert!(out.contains("pub fn all() -> Vec<Box<dyn DomainType>>"));
        assert!(!out.contains("pub mod "));
        let first = out.find("PhantomData::<super::int4::Int4>").unwrap();
        let last = out.find("PhantomData::<super::float8::Float8Ord>").unwrap();
        assert!(first < last);
        for ty in [
            "super::text::Text",
            "super::text::TextEq",
            "super::text::TextMatch",
            "super::text::TextOrdOre",
            "super::text::TextOrd",
            "super::text::TextSearch",
        ] {
            assert!(
                out.contains(&format!("PhantomData::<{ty}>")),
                "missing {ty}"
            );
        }
        let entries = out.matches("Box::new(PhantomData::<").count();
        let domains: usize = eql_domains::CATALOG.iter().map(|f| f.domains.len()).sum();
        assert_eq!(entries, domains);
    }

    #[test]
    fn envelope_fields_match_catalog_keys() {
        // `render_struct` hardcodes the `v`/`i`/`c` envelope triple (each maps to
        // a distinct Rust type) rather than looping `ENVELOPE_KEYS`. Tie the two
        // together: the leading fields of a generated struct must equal
        // `ENVELOPE_KEYS`, in order, so a change to the catalog's envelope keys
        // can't silently diverge from the emitter.
        let out = render_family_bindings(family("int4"));
        let leading: Vec<String> = field_idents(&out, "Int4");
        let expected: Vec<String> = eql_domains::ENVELOPE_KEYS
            .iter()
            .map(|k| k.to_string())
            .collect();
        assert_eq!(
            leading, expected,
            "the hardcoded envelope triple in render_struct must match \
             eql_domains::ENVELOPE_KEYS (update both together)"
        );
    }

    #[test]
    fn every_catalog_bare_domain_name_has_an_explicit_label() {
        // The "compile-checked catalog" intent: a new bare-domain name must force
        // a capability_label decision, not silently inherit a generic fallback.
        // Every name the catalog actually uses must resolve to one of the known,
        // explicitly-mapped labels.
        let known = [
            "storage-only domain",
            "equality domain",
            "ordering domain",
            "match domain",
            "search domain",
        ];
        for f in eql_domains::scalar_families() {
            for d in f.domains {
                let label = capability_label(d.name);
                assert!(
                    known.contains(&label),
                    "{}.{:?} maps to unexpected label {label:?}",
                    f.name,
                    d.name
                );
            }
        }
    }

    #[test]
    fn render_bindings_skips_non_scalar_families() {
        let tmp = crate::writer::test_support::tempdir();
        let dir = tmp.path().join(V3_BINDINGS_DIR);
        let rendered = render_bindings(&dir);
        assert!(
            !rendered.iter().any(|(p, _)| p.ends_with("jsonb.rs")),
            "jsonb.rs is hand-written; the generator must not emit it"
        );
        // One file per scalar family + inventory.
        assert_eq!(rendered.len(), eql_domains::scalar_families().count() + 1);
    }

    #[test]
    fn capability_label_panics_loudly_on_unmapped_name() {
        // An unmapped bare-domain name must abort codegen, not emit generic-but-
        // wrong doc text. Guards against the old silent `_ => "encrypted domain"`
        // fallback creeping back in.
        let err = std::panic::catch_unwind(|| capability_label("totally_new_capability"));
        assert!(
            err.is_err(),
            "capability_label must panic on an unmapped bare domain name"
        );
    }

    #[test]
    fn format_rs_prepends_marker_and_is_rustfmt_clean() {
        // Deliberately mis-spaced input: rustfmt must normalize it, proving the
        // rustfmt pass runs (prettyplease alone would not re-sort imports).
        let out = format_rs(quote! { use b::B; use a::A; pub struct Foo { pub v: u16 } });
        assert_eq!(out.lines().next().unwrap(), RUST_GENERATED_MARKER);
        assert!(out.contains("pub struct Foo"));
        assert!(out.contains("pub v: u16"));
        // rustfmt sorts `use a::A;` before `use b::B;`
        assert!(out.find("use a::A;").unwrap() < out.find("use b::B;").unwrap());
        // Idempotent: re-running rustfmt over the output changes nothing.
        assert_eq!(rustfmt(&out), out);
    }
}
