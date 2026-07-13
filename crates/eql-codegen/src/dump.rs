//! `dump_catalog` — serialize the `eql_domains::CATALOG` surface (each type's
//! domains and their supported SQL operators) for downstream verification
//! tooling. The reusable producer behind `eql-codegen -- dump-catalog`.
//!
//! Stage 1 consumes the `(type, domain)` shape; later stages consume the
//! per-domain `supported_ops`. Blocked-operator tagging is added in Stage 4.

use eql_domains::Term;
use serde::Serialize;

/// The catalog surface: every scalar type and its domains, plus the non-scalar
/// SteVec (`jsonb`) family.
#[derive(Serialize)]
pub struct CatalogDump {
    pub types: Vec<TypeEntry>,
    /// The `jsonb` (SteVec) family — `public.eql_v3_json` / `public.eql_v3_jsonb_entry` /
    /// `eql_v3.query_jsonb`. Their SQL is hand-written under `src/v3/jsonb/`; the
    /// catalog owns only their inventory (scalar-only consumers ignore this field).
    pub stevec: Vec<SteVecEntry>,
}

#[derive(Serialize)]
pub struct TypeEntry {
    /// Catalog token, e.g. `integer`.
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
    /// The installed pg_type typname: the version-prefixed unqualified SQL
    /// name (`eql_v3_integer_eq` — CIP-3472), resolved under `public`.
    pub typname: String,
    /// SQL operators the domain's terms support, in catalog order. Empty for
    /// the storage domain (no terms).
    pub supported_ops: Vec<&'static str>,
    /// The index terms this domain carries, with their extractor + SEM ctor.
    pub terms: Vec<TermInfo>,
}

/// A domain's index term: payload key + generated extractor + SEM constructor
/// (from `eql_domains::Term`) — links a domain to its extractor functions.
#[derive(Serialize)]
pub struct TermInfo {
    /// Payload key: `hm` / `ob` / `bf` / `op`.
    pub key: &'static str,
    /// Generated extractor function (unqualified): `eq_term` / `ord_term` /
    /// `match_term` / `ord_term_ore`.
    pub extractor: &'static str,
    /// SEM index-term constructor (unqualified): `hmac_256` / `ore_block_256` /
    /// `bloom_filter` / `ope_cllw`.
    pub ctor: &'static str,
}

/// One `jsonb` (SteVec) domain: catalog inventory only — its SQL surface
/// (CHECK, operators) is hand-written and not derivable from the catalog.
#[derive(Serialize)]
pub struct SteVecEntry {
    /// The bare domain name: `json` / `jsonb_entry` / `query_jsonb`.
    pub full_name: String,
    /// The installed pg_type typname: the version-prefixed name for the
    /// public-schema column domains (`eql_v3_json` / `eql_v3_jsonb_entry` —
    /// CIP-3472); the containment needle stays `query_jsonb` (it lives in the
    /// already-versioned `eql_v3` schema).
    pub typname: String,
    /// The catalog domain name: `json` / `entry` / `query`.
    pub name: &'static str,
    /// Index terms for this SteVec domain. Non-empty only for `jsonb_entry`
    /// (the sv element type); the `json` container and `query_jsonb` domains
    /// carry no term extractors — see `stevec_terms`.
    pub terms: Vec<TermInfo>,
}

fn term_infos(terms: &[Term]) -> Vec<TermInfo> {
    terms
        .iter()
        .map(|t| TermInfo {
            key: t.json_key(),
            extractor: t.extractor(),
            ctor: t.ctor(),
        })
        .collect()
}

/// Index terms for one `jsonb` (SteVec) domain, hardcoded for now.
///
/// The catalog does not model per-SteVec-entry terms — `JSONB_DOMAINS` declare
/// `terms: &[]` and the `shape_and_terms_are_consistent` invariant fails CI if a
/// non-`Scalar` domain ever gains one — so `term_infos(d.terms)` is provably
/// empty here. Until the catalog carries them, source the real hand-written
/// extractors from `src/v3/jsonb/{functions,operators}.sql`.
///
/// Terms live on `jsonb_entry` — the sv *element* type — ONLY: `eql_v3.eq_term`
/// reads `coalesce(hm, op)` for `=`/`<>`, and `eql_v3.ord_term` reads `op` for
/// `<`/`<=`/`>`/`>=`. The `json` container and `query_jsonb` domains carry no
/// term extractors (their surface is containment `@>`/`<@` and path navigation),
/// so they return no terms. Keyed on the catalog domain name (`json`/`entry`/
/// `query`).
fn stevec_terms(name: &str) -> Vec<TermInfo> {
    if name != "entry" {
        return Vec::new();
    }
    vec![
        TermInfo {
            key: "hm",
            extractor: "eq_term",
            ctor: "hmac_256",
        },
        TermInfo {
            key: "op",
            extractor: "ord_term",
            ctor: "ope_cllw",
        },
    ]
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
                    typname: d.sql_typname(spec.name),
                    suffix: if d.name.is_empty() {
                        String::new()
                    } else {
                        format!("_{}", d.name)
                    },
                    supported_ops: Term::operators_for_terms(d.terms),
                    terms: term_infos(d.terms),
                })
                .collect();
            TypeEntry {
                token: spec.name,
                is_eq_only: spec.is_eq_only(),
                domains,
            }
        })
        .collect();

    // The hand-written SteVec (jsonb) family — catalog inventory only. Kept out
    // of `types` so scalar-only consumers (the fixture-coverage task) are
    // unaffected; the docs manifest reads both `types` and `stevec`.
    let stevec = eql_domains::JSONB
        .domains
        .iter()
        .map(|d| SteVecEntry {
            full_name: d.full_name(eql_domains::JSONB.name),
            typname: d.sql_typname(eql_domains::JSONB.name),
            name: d.name,
            // Catalog terms are empty for SteVec; hardcode per-domain — only
            // `jsonb_entry` carries extractors (see stevec_terms).
            terms: stevec_terms(d.name),
        })
        .collect();

    CatalogDump { types, stevec }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn integer_exposes_all_ordered_domains_with_operators() {
        let dump = dump_catalog();
        let integer = dump
            .types
            .iter()
            .find(|t| t.token == "integer")
            .expect("integer present in catalog");
        assert!(!integer.is_eq_only, "integer is an ordered type");

        let segments: Vec<&str> = integer.domains.iter().map(|d| d.segment.as_str()).collect();
        assert_eq!(segments, ["storage", "eq", "ord_ore", "ord", "ord_ope"]);

        let storage = integer
            .domains
            .iter()
            .find(|d| d.segment == "storage")
            .unwrap();
        assert!(storage.supported_ops.is_empty(), "storage has no operators");

        let eq = integer.domains.iter().find(|d| d.segment == "eq").unwrap();
        assert_eq!(eq.supported_ops, ["=", "<>"]);

        let ord = integer.domains.iter().find(|d| d.segment == "ord").unwrap();
        assert_eq!(ord.supported_ops, ["=", "<>", "<", "<=", ">", ">="]);

        // Every ordered domain advertises the same operator set regardless of
        // which SEM backs it — only the term/extractor differ.
        let ord_ope = integer
            .domains
            .iter()
            .find(|d| d.segment == "ord_ope")
            .unwrap();
        assert_eq!(ord_ope.supported_ops, ["=", "<>", "<", "<=", ">", ">="]);
    }

    #[test]
    fn ordered_domain_exposes_its_extractor_and_ctor() {
        let dump = dump_catalog();
        let integer = dump.types.iter().find(|t| t.token == "integer").unwrap();

        // `_ord` is the OPE-backed default, reached by the unqualified extractor.
        let ord = integer.domains.iter().find(|d| d.segment == "ord").unwrap();
        assert_eq!(ord.terms.len(), 1);
        assert_eq!(ord.terms[0].key, "op");
        assert_eq!(ord.terms[0].extractor, "ord_term");
        assert_eq!(ord.terms[0].ctor, "ope_cllw");

        // `_ord_ore` keeps the block-ORE term, behind the qualified extractor.
        let ord_ore = integer
            .domains
            .iter()
            .find(|d| d.segment == "ord_ore")
            .unwrap();
        assert_eq!(ord_ore.terms.len(), 1);
        assert_eq!(ord_ore.terms[0].key, "ob");
        assert_eq!(ord_ore.terms[0].extractor, "ord_term_ore");
        assert_eq!(ord_ore.terms[0].ctor, "ore_block_256");
    }

    #[test]
    fn stevec_jsonb_family_is_dumped() {
        let dump = dump_catalog();
        let names: Vec<&str> = dump.stevec.iter().map(|e| e.full_name.as_str()).collect();
        // The jsonb family: storage-only `json` (Scalar), searchable
        // `json_search` (SteVec document), `jsonb_entry`, `query_jsonb`. The
        // whole family is dumped together so both column domains get documented
        // (CIP-3512).
        assert_eq!(names, ["json", "json_search", "jsonb_entry", "query_jsonb"]);

        let by_name = |n: &str| {
            dump.stevec
                .iter()
                .find(|e| e.full_name == n)
                .unwrap_or_else(|| panic!("{n} present"))
        };

        // Term extractors live on `jsonb_entry` (the sv element type) ONLY:
        // `eq_term` (hm/op equality) + `ord_term` (op ordering).
        let entry_extractors: Vec<&str> = by_name("jsonb_entry")
            .terms
            .iter()
            .map(|t| t.extractor)
            .collect();
        assert_eq!(entry_extractors, ["eq_term", "ord_term"]);

        // The `json` container and `query_jsonb` domains carry no term
        // extractors — their surface is containment (@>, <@) and path nav.
        assert!(by_name("json").terms.is_empty());
        assert!(by_name("query_jsonb").terms.is_empty());
    }

    /// Pins the hand-re-derived `suffix` wire field — the one channel with no
    /// other automated reader — so its underscore-prefixed values stay
    /// byte-stable after the catalog dropped the leading underscore from its
    /// stored (now bare) domain names.
    #[test]
    fn integer_suffix_field_is_underscore_prefixed() {
        let dump = dump_catalog();
        let integer = dump
            .types
            .iter()
            .find(|t| t.token == "integer")
            .expect("integer present in catalog");

        let suffixes: Vec<&str> = integer.domains.iter().map(|d| d.suffix.as_str()).collect();
        assert_eq!(suffixes, ["", "_eq", "_ord_ore", "_ord", "_ord_ope"]);
    }

    #[test]
    fn timestamp_is_ordered() {
        // timestamp was promoted to the ordered shape once
        // `compare_ore_block_256_term` generalized to N blocks (see #284 / the
        // `EQ_ONLY_DOMAINS` note in `eql-domains`). It now mirrors integer's
        // four-domain ordered surface.
        let dump = dump_catalog();
        let ts = dump
            .types
            .iter()
            .find(|t| t.token == "timestamp")
            .expect("timestamp present in catalog");
        assert!(!ts.is_eq_only, "timestamp is an ordered type");

        let segments: Vec<&str> = ts.domains.iter().map(|d| d.segment.as_str()).collect();
        assert_eq!(segments, ["storage", "eq", "ord_ore", "ord", "ord_ope"]);

        let ord = ts.domains.iter().find(|d| d.segment == "ord").unwrap();
        assert_eq!(ord.supported_ops, ["=", "<>", "<", "<=", ">", ">="]);
    }

    #[test]
    fn dump_catalog_excludes_non_scalar_jsonb() {
        // `dump_catalog` (and, via the same `scalar_families()` filter, the CLI
        // `list-types` / `dump-catalog` output the scalar-matrix tooling consumes)
        // must NOT surface the SteVec `jsonb` family: it has no `scalars::jsonb::*`
        // matrix and no generated SQL surface, even though two of its three
        // domain names (`public.eql_v3_jsonb_entry` / `eql_v3.query_jsonb`) now follow
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
        assert!(dump.types.iter().any(|t| t.token == "integer"));
    }
}
