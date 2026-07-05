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

use eql_domains::{Domain, DomainFamily, Term, CATALOG, ENVELOPE_KEYS};

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
        "ord" | "ord_ore" | "ord_ope" => "ordering domain",
        "match" => "match domain",
        "search" => "search domain",
        other => panic!(
            "unmapped bare domain name {other:?} — add it to capability_label \
             in crates/eql-codegen/src/bindings.rs"
        ),
    }
}

/// Render the catalog-derived struct doc lines for a domain: a summary line
/// (`` `public.<name>` — <label>. ``) and a detail line listing the supported
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
    let summary = format!(" `public.{full}` — {}.", capability_label(domain.name));

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
    let sql_domain = format!("public.{full}");
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

    // The domain's required term keys, threaded through the trait so
    // `from_v2::TargetDomain::parse` resolves them from the inventory alone —
    // Some(&[]) for a storage-only scalar (None is reserved for the
    // hand-written SteVec shapes). Parity with the catalog is pinned by
    // eql-bindings `tests/catalog_parity.rs`.
    let term_keys = Term::term_json_keys(domain.terms);

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
            fn term_json_keys_static() -> Option<&'static [&'static str]> {
                Some(&[#(#term_keys),*])
            }
            fn term_json_keys(&self) -> Option<&'static [&'static str]> {
                Self::term_json_keys_static()
            }
            fn parse_value(&self, value: &serde_json::Value) -> Result<(), serde_json::Error> {
                #ident::deserialize(value).map(|_| ())
            }
            fn schema(&self) -> Schema {
                schema_for!(#ident)
            }
        }
    }
}

/// Render a whole family module (`integer.rs`, `text.rs`, …): the import header
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
                    let s = format_ident!("{}", d.rust_struct_name(f.name));
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

/// The stored-payload domains of the catalog, in CATALOG order: every flat
/// scalar domain plus the SteVec document (`public.json`). The SteVec
/// entry/query shapes are inventory members but not stored column payloads,
/// so they are excluded — exactly the set `eql_bindings::from_v2` accepts as
/// conversion targets ([`render_payload_rs`]'s `DomainPayload` variants).
fn stored_payload_domains() -> impl Iterator<Item = (&'static DomainFamily, &'static Domain)> {
    CATALOG
        .iter()
        .flat_map(|f| f.domains.iter().map(move |d| (f, d)))
        .filter(|(f, d)| d.is_scalar() || d.full_name(f.name) == "json")
}

/// Render the generated `crates/eql-bindings/src/v3/payload.rs`: the
/// `DomainPayload` enum spanning every stored-payload domain — one variant
/// per catalog (family, domain) pair mapping to its binding struct, plus the
/// SteVec document for the `jsonb` family — with its
/// construct-from-known-domain `parse` constructor.
///
/// Serialize-only by design: the enum is `#[serde(untagged)]` so its wire
/// form is exactly the inner struct's, and it deliberately derives NO
/// `Deserialize` — cross-token payloads (`integer_eq` vs `bigint_eq`) are
/// byte-identical on the wire, so a variant can never be inferred from bytes
/// (the "Why there is no discriminated enum" rule in the v3 module docs);
/// it can only be constructed from a known target domain. Likewise no ts-rs
/// or schemars derives: this is a Rust-side ergonomics type, not a new wire
/// shape, so it must not churn the exported TS/JSON-Schema surface.
pub fn render_payload_rs() -> String {
    let mut variants = TokenStream::new();
    let mut parse_arms = TokenStream::new();
    let mut inner_arms = TokenStream::new();
    for (f, d) in stored_payload_domains() {
        let module = format_ident!("{}", f.name);
        let strukt = format_ident!("{}", d.rust_struct_name(f.name));
        let full = d.full_name(f.name);
        let doc = format!(" The `public.{full}` payload.");
        variants.extend(quote! {
            #[doc = #doc]
            #strukt(super::#module::#strukt),
        });
        parse_arms.extend(quote! {
            #full => Some(super::#module::#strukt::deserialize(value).map(Self::#strukt)),
        });
        inner_arms.extend(quote! {
            Self::#strukt(payload) => payload,
        });
    }

    let mod_doc = " The generated `DomainPayload` enum — every stored-payload v3 \
                   domain in one Rust type. Generated from the catalog; the \
                   DomainType trait, the shared newtypes, and the architectural \
                   module doc stay hand-written (domain_type.rs / terms.rs / mod.rs).";

    let file = quote! {
        #![doc = #mod_doc]

        use serde::{Deserialize, Serialize};

        use super::domain_type::DomainType;

        /// Every stored-payload v3 domain in one type: one variant per flat
        /// scalar domain in `eql-domains::CATALOG` plus the SteVec document
        /// (`public.json`). Generated from the catalog, so it cannot drift
        /// when the catalog grows.
        ///
        /// Serialization is exactly the inner struct's (`#[serde(untagged)]`
        /// adds no tagging), so typing a payload never changes the wire.
        /// Deliberately NO `Deserialize`: cross-token payloads are
        /// byte-identical on the wire (see "Why there is no discriminated
        /// enum" in the v3 module docs), so a variant is only constructible
        /// from a KNOWN domain — [`DomainPayload::parse`] or
        /// [`crate::from_v2::from_v2_typed`] — never inferred from bytes.
        #[derive(Clone, Debug, PartialEq, Serialize)]
        #[serde(untagged)]
        pub enum DomainPayload {
            #variants
        }

        impl DomainPayload {
            /// Strictly parse `value` as `domain`'s payload, KEEPING the
            /// parsed value — the constructor counterpart of
            /// [`DomainType::parse_value`] (which validates and discards).
            /// `domain` is the unqualified name (`"integer_eq"`, `"json"`,
            /// …). `None` when `domain` is not a stored-payload domain (the
            /// SteVec entry/query shapes included); `Some(Err)` when the
            /// strict parse fails (`deny_unknown_fields`, the
            /// `SchemaVersion`/`SteVecForm` pins).
            pub fn parse(
                domain: &str,
                value: &serde_json::Value,
            ) -> Option<Result<Self, serde_json::Error>> {
                match domain {
                    #parse_arms
                    _ => None,
                }
            }

            /// The inner payload as a [`DomainType`] trait object.
            pub fn as_domain_type(&self) -> &dyn DomainType {
                match self {
                    #inner_arms
                }
            }

            /// Fully-qualified SQL domain name, e.g. `"public.integer_eq"`.
            pub fn sql_domain(&self) -> &'static str {
                self.as_domain_type().sql_domain()
            }

            /// Unqualified SQL domain name, e.g. `"integer_eq"` — the name
            /// [`DomainPayload::parse`] accepts.
            pub fn domain(&self) -> &'static str {
                self.as_domain_type().domain()
            }
        }
    };

    format_rs(file)
}

/// Relative path (from repo root) of the generated v3 bindings directory.
const V3_BINDINGS_DIR: &str = "crates/eql-bindings/src/v3";

/// Render every binding file to memory (NO filesystem writes): one
/// `(<dir>/<family>.rs, body)` per catalog family in CATALOG order, then
/// `payload.rs` (the `DomainPayload` enum) and `inventory.rs`. Kept separate
/// from the write orchestration so a render panic
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
    rendered.push((dir.join("payload.rs"), render_payload_rs()));
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
    fn integer_family_structs_have_pinned_shape() {
        let out = render_family_bindings(family("integer"));
        assert!(out.starts_with(crate::consts::RUST_GENERATED_MARKER));
        for s in [
            "struct Integer ",
            "struct IntegerEq ",
            "struct IntegerOrdOre ",
            "struct IntegerOrd ",
            "struct IntegerOrdOpe ",
        ] {
            assert!(out.contains(s), "missing {s}");
        }
        assert_eq!(
            out.matches(
                "#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]"
            )
            .count(),
            5
        );
        assert_eq!(out.matches("#[ts(export, export_to = \"v3/\")]").count(), 5);
        assert_eq!(out.matches("#[serde(deny_unknown_fields)]").count(), 5);
        assert!(out.contains("`public.integer_eq` — equality domain."));
        assert!(out.contains("`public.integer` — storage-only domain."));
        assert!(out.contains("`public.integer_ord` — ordering domain."));
        assert!(out.contains("`public.integer_ord_ope` — ordering domain."));
        assert!(!out.contains("Envelope version"));
        assert!(!out.contains("HMAC-SHA-256 equality term"));
        assert_eq!(field_idents(&out, "Integer"), ["v", "i", "c"]);
        assert_eq!(field_idents(&out, "IntegerEq"), ["v", "i", "c", "hm"]);
        assert_eq!(field_idents(&out, "IntegerOrdOre"), ["v", "i", "c", "ob"]);
        assert_eq!(field_idents(&out, "IntegerOrd"), ["v", "i", "c", "ob"]);
        assert_eq!(field_idents(&out, "IntegerOrdOpe"), ["v", "i", "c", "op"]);
        assert!(out.contains("impl DomainType for IntegerEq"));
        assert!(out.contains("fn sql_domain_static()"));
        assert!(out.contains("\"public.integer_eq\""));
        assert!(out.contains("fn sql_domain(&self)"));
        assert!(out.contains("fn schema(&self) -> Schema"));
        assert!(out.contains("schema_for!(IntegerEq)"));
        assert!(out.contains("use crate::v3::terms::"));
        assert!(!out.contains("BloomFilter"));
    }

    #[test]
    fn struct_doc_carries_derivable_operators_and_required_keys() {
        // The struct doc is derived entirely from catalog data already present:
        // the capability label + the operator union (`Term::operators_for_terms`)
        // + the required-key list (`ENVELOPE_KEYS` ++ `Term::term_json_keys`).
        // No field docs, no new free-form catalog prose.
        let integer = render_family_bindings(family("integer"));

        // Storage-only: no operators.
        assert!(integer.contains("`public.integer` — storage-only domain."));
        assert!(integer.contains("Operators: none."));
        assert!(integer.contains("Required keys: `v` `i` `c`."));

        // Equality: `=`/`<>` and the `hm` key.
        assert!(integer.contains("`public.integer_eq` — equality domain."));
        assert!(integer.contains("Operators: `=` `<>`."));
        assert!(integer.contains("Required keys: `v` `i` `c` `hm`."));

        // Ordering: full comparison operators and the `ob` key.
        assert!(integer.contains("Operators: `=` `<>` `<` `<=` `>` `>=`."));
        assert!(integer.contains("Required keys: `v` `i` `c` `ob`."));

        // OPE ordering: same operator set, `op` key instead of `ob`.
        assert!(integer.contains("`public.integer_ord_ope` — ordering domain."));
        assert!(integer.contains("Required keys: `v` `i` `c` `op`."));

        // text_ord carries BOTH `hm` and `ob` — the dual-term distinction that
        // previously lived only in hand-written prose is now derivable in the doc.
        let text = render_family_bindings(family("text"));
        assert!(text.contains("Required keys: `v` `i` `c` `hm` `ob`."));
        assert!(text.contains("`public.text_match` — match domain."));
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
            "struct TextOrdOpe ",
            "struct TextSearch ",
        ] {
            assert!(out.contains(s), "missing {s}");
        }
        assert!(out.contains("`public.text_match` — match domain."));
        assert!(out.contains("`public.text_search` — search domain."));
        assert!(out.contains("bf: BloomFilter"));
        assert_eq!(field_idents(&out, "TextOrd"), ["v", "i", "c", "hm", "ob"]);
        // text_ord_ope is dual-term like text_ord: equality stays exact via hm.
        assert_eq!(
            field_idents(&out, "TextOrdOpe"),
            ["v", "i", "c", "hm", "op"]
        );
        assert_eq!(field_idents(&out, "TextMatch"), ["v", "i", "c", "bf"]);
        assert_eq!(
            field_idents(&out, "TextSearch"),
            ["v", "i", "c", "hm", "ob", "bf"]
        );
    }

    #[test]
    fn bool_storage_only_family_has_one_struct_no_terms() {
        let out = render_family_bindings(family("boolean"));
        assert_eq!(out.matches("pub struct ").count(), 1);
        assert!(out.contains("`public.boolean` — storage-only domain."));
        assert_eq!(field_idents(&out, "Boolean"), ["v", "i", "c"]);
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
        assert_eq!(written.len(), eql_domains::scalar_families().count() + 2);
        assert!(dir.join("integer.rs").is_file());
        assert!(dir.join("text.rs").is_file());
        assert!(dir.join("payload.rs").is_file());
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
        // returns one entry per family plus payload and inventory (last).
        let tmp = crate::writer::test_support::tempdir();
        let dir = tmp.path().join(V3_BINDINGS_DIR);
        std::fs::create_dir_all(&dir).unwrap();
        let sentinel = dir.join("integer.rs");
        std::fs::write(&sentinel, "SENTINEL").unwrap();

        let rendered = render_bindings(&dir);

        assert_eq!(rendered.len(), eql_domains::scalar_families().count() + 2);
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

    /// Declared variant idents of `enum_name` in generated source, in order.
    fn variant_idents(src: &str, enum_name: &str) -> Vec<String> {
        let file = syn::parse_file(src).expect("generated source parses");
        for item in &file.items {
            if let syn::Item::Enum(e) = item {
                if e.ident == enum_name {
                    return e.variants.iter().map(|v| v.ident.to_string()).collect();
                }
            }
        }
        panic!("enum {enum_name} not found in generated source");
    }

    #[test]
    fn payload_enum_spans_every_stored_domain_in_catalog_order() {
        let out = render_payload_rs();
        assert!(out.starts_with(crate::consts::RUST_GENERATED_MARKER));

        // One variant per catalog (family, domain) pair that is a stored
        // payload: every scalar domain plus the SteVec document. The SteVec
        // entry/query shapes are inventory members but not stored payloads.
        let expected: Vec<String> = CATALOG
            .iter()
            .flat_map(|f| {
                f.domains
                    .iter()
                    .filter(|d| d.is_scalar() || d.full_name(f.name) == "json")
                    .map(|d| d.rust_struct_name(f.name))
            })
            .collect();
        assert_eq!(variant_idents(&out, "DomainPayload"), expected);
        assert!(out.contains("SteVecDocument(super::jsonb::SteVecDocument)"));
        assert!(!expected.contains(&"SteVecEntry".to_string()));
        assert!(!expected.contains(&"SteVecQuery".to_string()));

        // parse: one arm per stored domain, keyed on the unqualified name,
        // falling through to None for everything else.
        assert!(out.contains(
            "pub fn parse(\n        domain: &str,\n        value: &serde_json::Value,\n    ) -> Option<Result<Self, serde_json::Error>>"
        ));
        assert!(out.contains(r#""integer_eq" =>"#));
        assert!(out.contains("IntegerEq::deserialize(value).map(Self::IntegerEq)"));
        assert!(out.contains(r#""json" =>"#));
        assert!(out.contains("SteVecDocument::deserialize(value).map(Self::SteVecDocument)"));
        assert!(out.contains("_ => None,"));
        assert!(out.contains("pub fn as_domain_type(&self) -> &dyn DomainType"));
        assert!(out.contains("pub fn sql_domain(&self) -> &'static str"));
        assert!(out.contains("pub fn domain(&self) -> &'static str"));
    }

    #[test]
    fn payload_enum_is_untagged_serialize_only_with_no_export_derives() {
        // The wire form must be exactly the inner struct's, and DomainPayload
        // is a Rust-side ergonomics type: no Deserialize (inference from
        // bytes is unsound — cross-token payloads are byte-identical), and no
        // ts-rs/schemars derives (it must not churn the exported TS/JSON
        // surface).
        let out = render_payload_rs();
        assert!(out.contains("#[derive(Clone, Debug, PartialEq, Serialize)]"));
        assert!(out.contains("#[serde(untagged)]"));
        assert!(
            !out.contains("#[derive(Clone, Debug, PartialEq, Serialize, Deserialize"),
            "DomainPayload must not derive Deserialize"
        );
        assert!(!out.contains("ts_rs"), "no ts-rs on DomainPayload");
        assert!(!out.contains("#[ts("), "no ts-rs export attributes");
        assert!(!out.contains("JsonSchema"), "no schemars on DomainPayload");
        assert!(!out.contains("schema_for!"), "no schema emission");
    }

    #[test]
    fn inventory_enumerates_all_in_catalog_order() {
        let out = render_inventory_rs();
        assert!(out.starts_with(crate::consts::RUST_GENERATED_MARKER));
        assert!(out.contains("pub fn all() -> Vec<Box<dyn DomainType>>"));
        assert!(!out.contains("pub mod "));
        let first = out.find("PhantomData::<super::integer::Integer>").unwrap();
        let last = out
            .find("PhantomData::<super::double::DoubleOrdOpe>")
            .unwrap();
        assert!(first < last);
        for ty in [
            "super::text::Text",
            "super::text::TextEq",
            "super::text::TextMatch",
            "super::text::TextOrdOre",
            "super::text::TextOrd",
            "super::text::TextOrdOpe",
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
    fn generated_impls_thread_term_keys_and_parse_value() {
        // `from_v2` resolves a target domain's required term keys through the
        // trait object (`DomainType::term_json_keys`) and validates converted
        // payloads through `DomainType::parse_value` — both must be emitted on
        // every generated scalar impl, derived from `Term::term_json_keys`.
        let integer = render_family_bindings(family("integer"));
        assert!(integer.contains("fn term_json_keys_static() -> Option<&'static [&'static str]>"));
        assert!(integer.contains("fn term_json_keys(&self) -> Option<&'static [&'static str]>"));
        assert!(
            integer.contains("fn parse_value("),
            "generated impls must emit parse_value"
        );
        // Storage-only domain: an EMPTY key list (Some, not None — None is the
        // non-scalar SteVec marker).
        assert!(integer.contains("Some(&[])"));
        // Single-term equality domain.
        assert!(integer.contains(r#"&["hm"]"#));
        // OPE ordering domain.
        assert!(integer.contains(r#"&["op"]"#));

        // Multi-term domains list keys in catalog (wire) order.
        let text = render_family_bindings(family("text"));
        assert!(text.contains(r#"&["hm", "ob", "bf"]"#), "text_search keys");
        assert!(text.contains(r#"&["hm", "op"]"#), "text_ord_ope keys");
        assert!(text.contains(r#"&["bf"]"#), "text_match keys");
    }

    #[test]
    fn envelope_fields_match_catalog_keys() {
        // `render_struct` hardcodes the `v`/`i`/`c` envelope triple (each maps to
        // a distinct Rust type) rather than looping `ENVELOPE_KEYS`. Tie the two
        // together: the leading fields of a generated struct must equal
        // `ENVELOPE_KEYS`, in order, so a change to the catalog's envelope keys
        // can't silently diverge from the emitter.
        let out = render_family_bindings(family("integer"));
        let leading: Vec<String> = field_idents(&out, "Integer");
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
        // One file per scalar family + payload + inventory.
        assert_eq!(rendered.len(), eql_domains::scalar_families().count() + 2);
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
