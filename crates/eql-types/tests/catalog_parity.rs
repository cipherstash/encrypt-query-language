//! The drift gate: the v3 domain inventory must mirror `eql-scalars::CATALOG`
//! — the same catalog that generates the `eql_v3` SQL surface — exactly:
//! every domain, in catalog order, and every domain's wire keys, pinned
//! through the published JSON Schema (schemars `required` reflects the real
//! serde contract, so an `Option` term field or a wrong wire key fails
//! here). Per-type strictness (unknown-key rejection, envelope version) is
//! covered behaviourally in `tests/v3_conformance.rs`.

use std::collections::BTreeSet;

use eql_scalars::{Term, CATALOG, ENVELOPE_KEYS};
use eql_types::v3;

#[test]
fn inventory_exactly_covers_catalog() {
    let expected: Vec<String> = CATALOG
        .iter()
        .flat_map(|spec| spec.domains.iter().map(|d| spec.domain_name(d)))
        .collect();
    let actual: Vec<&str> = v3::all().iter().map(|e| e.domain()).collect();
    assert_eq!(
        actual, expected,
        "v3::all() must list every CATALOG domain, in catalog order"
    );
}

/// The *published* JSON Schemas must agree with the catalog: each domain's
/// schema `required` list is exactly envelope + catalog term keys — the
/// artifact schema consumers validate against cannot drift from the SQL
/// surface's CHECK constraints.
#[test]
fn schema_required_keys_match_catalog_terms() {
    let entries = v3::all();
    for spec in CATALOG {
        for domain in spec.domains {
            let name = spec.domain_name(domain);
            let entry = entries
                .iter()
                .find(|e| e.domain() == name)
                .unwrap_or_else(|| panic!("no domain inventory entry for {name}"));

            let schema = entry.schema();
            let object = schema
                .schema
                .object
                .as_ref()
                .unwrap_or_else(|| panic!("{name}: schema is not an object"));
            let required: BTreeSet<&str> = object.required.iter().map(String::as_str).collect();

            let expected: BTreeSet<&str> = ENVELOPE_KEYS
                .iter()
                .copied()
                .chain(Term::term_json_keys(domain.terms))
                .collect();

            assert_eq!(
                required, expected,
                "{name}: schema required keys must be envelope + catalog terms"
            );
        }
    }
}
