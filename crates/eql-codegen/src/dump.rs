//! `dump_catalog` — serialize the `eql_scalars::CATALOG` surface (each type's
//! domains and their supported SQL operators) for downstream verification
//! tooling. The reusable producer behind `eql-codegen -- dump-catalog`.
//!
//! Stage 1 consumes the `(type, domain)` shape; later stages consume the
//! per-domain `supported_ops`. Blocked-operator tagging is added in Stage 4.

use eql_scalars::{Term, CATALOG};
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
    /// Test-name segment: the base domain (`suffix == ""`) is `storage`;
    /// otherwise the suffix without its leading underscore (`_eq` → `eq`,
    /// `_ord_ore` → `ord_ore`).
    pub segment: String,
    /// Raw catalog suffix (`""`, `_eq`, `_ord`, `_ord_ore`, `_match`).
    pub suffix: &'static str,
    /// SQL operators the domain's terms support, in catalog order. Empty for
    /// the storage domain (no terms).
    pub supported_ops: Vec<&'static str>,
}

/// Build the catalog surface description from `eql_scalars::CATALOG`.
pub fn dump_catalog() -> CatalogDump {
    let types = CATALOG
        .iter()
        .map(|spec| {
            let domains = spec
                .domains
                .iter()
                .map(|d| DomainEntry {
                    segment: if d.suffix.is_empty() {
                        "storage".to_string()
                    } else {
                        d.suffix.trim_start_matches('_').to_string()
                    },
                    suffix: d.suffix,
                    supported_ops: Term::operators_for_terms(d.terms),
                })
                .collect();
            TypeEntry {
                token: spec.token,
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

    #[test]
    fn timestamptz_is_ordered() {
        // timestamptz was promoted to the ordered shape once
        // `compare_ore_block_256_term` generalized to N blocks (see #284 / the
        // `EQ_ONLY_DOMAINS` note in `eql-scalars`). It now mirrors int4's
        // four-domain ordered surface.
        let dump = dump_catalog();
        let ts = dump
            .types
            .iter()
            .find(|t| t.token == "timestamptz")
            .expect("timestamptz present in catalog");
        assert!(!ts.is_eq_only, "timestamptz is an ordered type");

        let segments: Vec<&str> = ts.domains.iter().map(|d| d.segment.as_str()).collect();
        assert_eq!(segments, ["storage", "eq", "ord_ore", "ord"]);

        let ord = ts.domains.iter().find(|d| d.segment == "ord").unwrap();
        assert_eq!(ord.supported_ops, ["=", "<>", "<", "<=", ">", ">="]);
    }
}
