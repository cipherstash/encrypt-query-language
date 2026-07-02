//! The drift gate: every v3 domain's wire contract — pinned through the
//! published JSON Schema — must match `eql-domains::CATALOG`, the same catalog
//! that GENERATES both the SQL surface and these payload structs. schemars
//! output reflects the real serde contract, so per domain this catches a
//! wrong/dropped required key, a struct that lost
//! `#[serde(deny_unknown_fields)]` (`additionalProperties: false`), and a `v`
//! field that is not [`eql_bindings::SchemaVersion`] (the `$ref` and its
//! `const: 2`). The inventory set/order IS policed here by
//! `inventory_exactly_covers_catalog_in_order()`, which asserts `v3::all()`
//! lists exactly the `CATALOG` domains in catalog order (the generated
//! `inventory.rs` byte-parity gate lives in eql-codegen; this covers the
//! compiled `all()`). The emitted `.ts` property order is pinned by
//! `tests/ts_property_order.rs`. Behavioural spot checks live in
//! `tests/v3_conformance.rs`.

use std::collections::BTreeSet;

use eql_bindings::{v3, EQL_SCHEMA_VERSION};
use eql_domains::{Term, CATALOG, ENVELOPE_KEYS};
use serde_json::{json, Value};

/// The *published* JSON Schemas must agree with the catalog: each domain's
/// schema `required` list is exactly envelope + catalog term keys — the
/// artifact schema consumers validate against cannot drift from the SQL
/// surface's CHECK constraints.
#[test]
fn schema_required_keys_match_catalog_terms() {
    let entries = v3::all();
    for spec in CATALOG {
        for domain in spec.domains {
            if !domain.is_scalar() {
                continue; // SteVec required-keys asserted in Task 8/9
            }
            let name = spec.domain_name(domain);
            let entry = entries
                .iter()
                .find(|e| e.domain() == name)
                .unwrap_or_else(|| panic!("no domain inventory entry for {name}"));

            let schema: Value = serde_json::to_value(entry.schema())
                .unwrap_or_else(|e| panic!("{name}: schema does not serialize: {e}"));
            let required: BTreeSet<&str> = schema["required"]
                .as_array()
                .unwrap_or_else(|| panic!("{name}: schema has no required array"))
                .iter()
                .map(|v| v.as_str().expect("required entry is a string"))
                .collect();

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

/// `v3::all()` must list exactly the catalog domains, in catalog order. The
/// generated `inventory.rs` makes this structurally true, but the only cargo-
/// level guard was `schema_required_keys_match_catalog_terms`, which iterates
/// CATALOG and *finds* each entry — it catches a missing entry but neither an
/// extra entry nor a wrong order. (The byte-parity gate in eql-codegen covers
/// the generated `inventory.rs` source; this covers the actually-compiled
/// `all()` at the eql-bindings level.) A direct ordered `assert_eq!` restores
/// both directions, the regression dropped when `inventory_exactly_covers_catalog`
/// was removed (commit 27c200c4).
#[test]
fn inventory_exactly_covers_catalog_in_order() {
    // `domain_name` is correct for every shape (including the jsonb family's
    // one documented exception, the `eql_v3.json` document domain — see
    // `Domain::full_name`), so no per-shape branch is needed here.
    let expected: Vec<String> = CATALOG
        .iter()
        .flat_map(|spec| spec.domains.iter().map(move |d| spec.domain_name(d)))
        .collect();
    let actual: Vec<String> = v3::all().iter().map(|e| e.domain().to_string()).collect();
    assert_eq!(
        actual, expected,
        "v3::all() must list exactly the catalog domains in catalog order \
         (extra/missing entry or reordering) — regenerate with \
         `mise run types:generate` and commit inventory.rs"
    );
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
        let is_scalar = CATALOG
            .iter()
            .flat_map(|s| s.domains.iter().map(move |d| (s, d)))
            .find(|(s, d)| s.domain_name(d) == name)
            .map(|(_, d)| d.is_scalar())
            .unwrap_or(true);
        if !is_scalar {
            continue; // SteVec strictness asserted in Task 9 (Document/Query only)
        }
        let schema: Value = serde_json::to_value(entry.schema())
            .unwrap_or_else(|e| panic!("{name}: schema does not serialize: {e}"));

        assert_eq!(
            schema.pointer("/additionalProperties"),
            Some(&json!(false)),
            "{name}: schema must set additionalProperties: false \
             (struct lost #[serde(deny_unknown_fields)]?)"
        );
        assert_eq!(
            schema.pointer("/$defs/Identifier/additionalProperties"),
            Some(&json!(false)),
            "{name}: Identifier definition must set additionalProperties: false"
        );
        assert_eq!(
            schema.pointer("/properties/v/$ref"),
            Some(&json!("#/$defs/SchemaVersion")),
            "{name}: the v property must $ref the SchemaVersion definition \
             (field declared as a bare integer instead of SchemaVersion?)"
        );
        assert_eq!(
            schema.pointer("/$defs/SchemaVersion/const"),
            Some(&json!(EQL_SCHEMA_VERSION)),
            "{name}: SchemaVersion must pin const: {EQL_SCHEMA_VERSION}"
        );
    }
}
