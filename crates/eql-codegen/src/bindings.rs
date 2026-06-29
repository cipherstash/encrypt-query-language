//! The Rust payload-bindings emitter: renders `eql_domains::CATALOG` to the
//! committed `crates/eql-bindings/src/v3/<family>.rs` structs + `DomainType`
//! impls and the generated `inventory.rs` (`all()`), the same generate-to-
//! committed-source mechanism `generate.rs` uses for SQL. Token stream via
//! `quote!`, formatted by `prettyplease::unparse` then the repo's stable
//! `rustfmt` (prettyplease is rustfmt-clean but not rustfmt-identical), with
//! the `// @generated` ownership marker prepended as line 1.

use proc_macro2::TokenStream;
use quote::{format_ident, quote};

use eql_domains::{Domain, DomainFamily, Term, CATALOG};

use crate::consts::RUST_GENERATED_MARKER;

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

/// PascalCase a snake_case domain name: "int4_ord_ore" -> "Int4OrdOre".
fn pascal(name: &str) -> String {
    name.split('_')
        .filter(|s| !s.is_empty())
        .map(|s| {
            let mut chars = s.chars();
            match chars.next() {
                Some(first) => first.to_uppercase().collect::<String>() + chars.as_str(),
                None => String::new(),
            }
        })
        .collect()
}

/// Capability label for a domain's single catalog-derived doc line, keyed on
/// the bare domain name. Parallels the SQL emitter's per-domain `--! @brief`.
fn capability_label(domain_name: &str) -> &'static str {
    match domain_name {
        "" => "storage-only domain",
        "eq" => "equality domain",
        "ord" | "ord_ore" => "ordering domain",
        "match" => "match domain",
        "search" => "search domain",
        _ => "encrypted domain",
    }
}

/// One payload struct + its three-method `DomainType` impl. One struct doc
/// line, no field docs. Term fields come from `Term::payload_terms`, matching
/// on the enum for the field key and its newtype. The `schema` method returns
/// `schemars::Schema` (1.x).
fn render_struct(family: &DomainFamily, domain: &Domain) -> TokenStream {
    let full = domain.full_name(family.name);
    let ident = format_ident!("{}", pascal(&full));
    let sql_domain = format!("eql_v3.{full}");
    let sdoc = format!("`eql_v3.{full}` — {}.", capability_label(domain.name));

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
        #[doc = #sdoc]
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
        "The `{}` encrypted-domain family — generated from the eql-domains catalog.",
        family.name
    );

    let file = quote! {
        #![doc = #mod_doc]

        use schemars::{schema_for, Schema};

        use crate::v3::terms::{ #(#used_idents),* };
        use crate::v3::DomainType;
        use crate::{Identifier, SchemaVersion};
        use schemars::JsonSchema;
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
                    let s = format_ident!("{}", pascal(&d.full_name(f.name)));
                    quote! { Box::new(PhantomData::<super::#m::#s>), }
                })
                .collect::<Vec<_>>()
        })
        .collect();

    let mod_doc = "The `all()` inventory — every v3 domain payload type in \
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
