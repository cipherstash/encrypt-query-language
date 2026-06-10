//! The drift gate: the v3 registry must mirror `eql-scalars::CATALOG` — the
//! same catalog that generates the `eql_v3` SQL surface — exactly. Append a
//! scalar to the catalog without adding its types here and the first test
//! fails; let a term field become `Option` (or carry the wrong wire key) and
//! the second fails, because schemars `required` reflects the real serde
//! contract.

use std::collections::BTreeSet;

use eql_scalars::{Term, CATALOG};
use eql_types::v3::registry;

/// Mirrors `ENVELOPE_KEYS` in `eql-codegen/src/consts.rs` (`pub(crate)`
/// there, so restated here): the keys every generated domain CHECK requires
/// before its term keys.
const ENVELOPE_KEYS: &[&str] = &["v", "i", "c"];

#[test]
fn registry_exactly_covers_catalog() {
    let expected: Vec<String> = CATALOG
        .iter()
        .flat_map(|spec| spec.domains.iter().map(|d| spec.domain_name(d)))
        .collect();
    let actual: Vec<&str> = registry::all().iter().map(|e| e.domain).collect();
    assert_eq!(
        actual, expected,
        "v3 registry must list every CATALOG domain, in catalog order"
    );
}

#[test]
fn required_keys_match_catalog_terms() {
    let entries = registry::all();
    for spec in CATALOG {
        for domain in spec.domains {
            let name = spec.domain_name(domain);
            let entry = entries
                .iter()
                .find(|e| e.domain == name)
                .unwrap_or_else(|| panic!("no registry entry for {name}"));

            let schema = (entry.schema)();
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
                "{name} ({}): required wire keys must be envelope + catalog terms",
                entry.type_name
            );
        }
    }
}
