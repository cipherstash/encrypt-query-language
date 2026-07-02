//! `dump_catalog` — serialize the `eql_domains::CATALOG` surface (each type's
//! domains and their supported SQL operators) for downstream verification
//! tooling. The reusable producer behind `eql-codegen -- dump-catalog`.
//!
//! Stage 1 consumes the `(type, domain)` shape; later stages consume the
//! per-domain `supported_ops`. Blocked-operator tagging is added in Stage 4.

use eql_domains::Term;
use serde::Serialize;

/// The catalog surface: every scalar type and its domains.
#[derive(Serialize)]
pub struct CatalogDump {
    pub types: Vec<TypeEntry>,
}

#[derive(Serialize)]
pub struct TypeEntry {
    /// Catalog token, e.g. `int4`.
    pub token: &'static str,
    /// True when the type has no `_ord` domain (storage + `_eq` only).
    pub is_eq_only: bool,
    pub domains: Vec<DomainEntry>,
}

#[derive(Serialize)]
pub struct DomainEntry {
    /// Test-name segment: the base domain (`name == ""`) is `storage`;
    /// otherwise the bare domain name (`eq`, `ord`, …).
    pub segment: String,
    /// The `suffix` wire field (`""`, `_eq`, `_ord`, `_ord_ore`, `_match`),
    /// reconstructed by re-prefixing the bare domain name with `_` so the
    /// emitted JSON stays byte-stable after the catalog dropped the leading
    /// underscore from its stored domain names.
    pub suffix: String,
    /// SQL operators the domain's terms support, in catalog order. Empty for
    /// the storage domain (no terms).
    pub supported_ops: Vec<&'static str>,
}

/// Build the catalog surface description from `eql_domains::CATALOG`.
pub fn dump_catalog() -> CatalogDump {
    let types = eql_domains::scalar_families()
        .map(|spec| {
            let domains = spec
                .domains
                .iter()
                .map(|d| DomainEntry {
                    segment: if d.name.is_empty() {
                        "storage".to_string()
                    } else {
                        d.name.to_string()
                    },
                    suffix: if d.name.is_empty() {
                        String::new()
                    } else {
                        format!("_{}", d.name)
                    },
                    supported_ops: Term::operators_for_terms(d.terms),
                })
                .collect();
            TypeEntry {
                token: spec.name,
                is_eq_only: spec.is_eq_only(),
                domains,
            }
        })
        .collect();
    CatalogDump { types }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn int4_exposes_all_ordered_domains_with_operators() {
        let dump = dump_catalog();
        let int4 = dump
            .types
            .iter()
            .find(|t| t.token == "int4")
            .expect("int4 present in catalog");
        assert!(!int4.is_eq_only, "int4 is an ordered type");

        let segments: Vec<&str> = int4.domains.iter().map(|d| d.segment.as_str()).collect();
        assert_eq!(segments, ["storage", "eq", "ord_ore", "ord"]);

        let storage = int4
            .domains
            .iter()
            .find(|d| d.segment == "storage")
            .unwrap();
        assert!(storage.supported_ops.is_empty(), "storage has no operators");

        let eq = int4.domains.iter().find(|d| d.segment == "eq").unwrap();
        assert_eq!(eq.supported_ops, ["=", "<>"]);

        let ord = int4.domains.iter().find(|d| d.segment == "ord").unwrap();
        assert_eq!(ord.supported_ops, ["=", "<>", "<", "<=", ">", ">="]);
    }

    /// Pins the hand-re-derived `suffix` wire field — the one channel with no
    /// other automated reader — so its underscore-prefixed values stay
    /// byte-stable after the catalog dropped the leading underscore from its
    /// stored (now bare) domain names.
    #[test]
    fn int4_suffix_field_is_underscore_prefixed() {
        let dump = dump_catalog();
        let int4 = dump
            .types
            .iter()
            .find(|t| t.token == "int4")
            .expect("int4 present in catalog");

        let suffixes: Vec<&str> = int4.domains.iter().map(|d| d.suffix.as_str()).collect();
        assert_eq!(suffixes, ["", "_eq", "_ord_ore", "_ord"]);
    }

    #[test]
    fn timestamp_is_ordered() {
        // timestamp was promoted to the ordered shape once
        // `compare_ore_block_256_term` generalized to N blocks (see #284 / the
        // `EQ_ONLY_DOMAINS` note in `eql-domains`). It now mirrors int4's
        // four-domain ordered surface.
        let dump = dump_catalog();
        let ts = dump
            .types
            .iter()
            .find(|t| t.token == "timestamp")
            .expect("timestamp present in catalog");
        assert!(!ts.is_eq_only, "timestamp is an ordered type");

        let segments: Vec<&str> = ts.domains.iter().map(|d| d.segment.as_str()).collect();
        assert_eq!(segments, ["storage", "eq", "ord_ore", "ord"]);

        let ord = ts.domains.iter().find(|d| d.segment == "ord").unwrap();
        assert_eq!(ord.supported_ops, ["=", "<>", "<", "<=", ">", ">="]);
    }

    #[test]
    fn dump_catalog_excludes_non_scalar_jsonb() {
        // `dump_catalog` (and, via the same `scalar_families()` filter, the CLI
        // `list-types` / `dump-catalog` output the scalar-matrix tooling consumes)
        // must NOT surface the SteVec `jsonb` family: it has no `scalars::jsonb::*`
        // matrix and no generated SQL surface, even though two of its three
        // domain names (`eql_v3.jsonb_entry` / `eql_v3.jsonb_query`) now follow
        // the family+suffix string convention — the payload shape is still not
        // flat. This pins the exclusion directly at the codegen surface rather
        // than relying only on the transitive `scalar_families()` guard in
        // `eql-domains`.
        let dump = dump_catalog();
        assert!(
            !dump.types.iter().any(|t| t.token == "jsonb"),
            "dump_catalog must exclude the non-scalar jsonb family, got tokens: {:?}",
            dump.types.iter().map(|t| t.token).collect::<Vec<_>>()
        );
        // Sanity: the scalar families are still present (the filter isn't empty).
        assert!(dump.types.iter().any(|t| t.token == "int4"));
    }
}
