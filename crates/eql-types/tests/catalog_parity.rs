//! The drift gate: the v3 domain inventory must mirror `eql-domains::CATALOG`
//! — the same catalog that generates the `eql_v3` SQL surface — exactly:
//! every domain, in catalog order, and every domain's wire contract, pinned
//! through the published JSON Schema. schemars output reflects the real
//! serde contract, so per domain this catches an `Option` term field or a
//! wrong wire key (`required`), a struct that lost
//! `#[serde(deny_unknown_fields)]` (`additionalProperties: false`), and a
//! `v` field that is not [`eql_types::SchemaVersion`] (the `$ref` and its
//! `const: 2`). Behavioural spot checks of the same properties live in
//! `tests/v3_conformance.rs`.

use std::collections::BTreeSet;

use eql_domains::{Term, CATALOG, ENVELOPE_KEYS};
use eql_types::{v3, EQL_SCHEMA_VERSION};
use serde_json::{json, Value};

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

/// The published `$id` is the schema's identity URL — `tests/export.rs`
/// injects [`v3::DomainType::schema_id`] into every written file. Pin its
/// shape with independent literals (NOT the helper, which would only test
/// itself): a regressed host, a dropped `v3/`, or a wrong domain segment must
/// turn a test red, not merely shift the freshness diff.
#[test]
fn schema_id_is_canonical() {
    let entries = v3::all();
    let id_of = |domain: &str| {
        entries
            .iter()
            .find(|e| e.domain() == domain)
            .unwrap_or_else(|| panic!("no domain inventory entry for {domain}"))
            .schema_id()
    };

    // Fully-literal anchors — no interpolation, so a typo in the helper's base
    // URL or path cannot match.
    assert_eq!(
        id_of("int4_eq"),
        "https://schemas.cipherstash.com/eql/v3/int4_eq.json"
    );
    assert_eq!(
        id_of("text_search"),
        "https://schemas.cipherstash.com/eql/v3/text_search.json"
    );

    // Every domain follows the same canonical pattern.
    for entry in &entries {
        let id = entry.schema_id();
        let name = entry.domain();
        assert_eq!(
            id,
            format!("https://schemas.cipherstash.com/eql/v3/{name}.json"),
            "{name}: $id must be the canonical eql/v3 URL"
        );
    }
}

/// Every published schema must be *strict*, not just complete: unknown keys
/// rejected at the root and inside the nested `Identifier`, and the `v`
/// property pinned to the `SchemaVersion` definition whose `const` is the
/// wire version. `required` alone (the test above) would stay green if a
/// struct lost `#[serde(deny_unknown_fields)]` or swapped `SchemaVersion`
/// for a bare integer — both regenerate a permissive schema that
/// `types:check` would happily commit as the new baseline.
#[test]
fn schemas_are_strict() {
    for entry in v3::all() {
        let name = entry.domain();
        let schema: Value = serde_json::to_value(entry.schema())
            .unwrap_or_else(|e| panic!("{name}: schema does not serialize: {e}"));

        assert_eq!(
            schema.pointer("/additionalProperties"),
            Some(&json!(false)),
            "{name}: schema must set additionalProperties: false \
             (struct lost #[serde(deny_unknown_fields)]?)"
        );
        assert_eq!(
            schema.pointer("/definitions/Identifier/additionalProperties"),
            Some(&json!(false)),
            "{name}: Identifier definition must set additionalProperties: false"
        );
        assert_eq!(
            schema.pointer("/properties/v/allOf/0/$ref"),
            Some(&json!("#/definitions/SchemaVersion")),
            "{name}: the v property must $ref the SchemaVersion definition \
             (field declared as a bare integer instead of SchemaVersion?)"
        );
        assert_eq!(
            schema.pointer("/definitions/SchemaVersion/const"),
            Some(&json!(EQL_SCHEMA_VERSION)),
            "{name}: SchemaVersion must pin const: {EQL_SCHEMA_VERSION}"
        );
    }
}
