//! The drift gate: the v3 registry must mirror `eql-scalars::CATALOG` — the
//! same catalog that generates the `eql_v3` SQL surface — exactly. Append a
//! scalar to the catalog without adding its types here and the first test
//! fails; let a term field become `Option` (or carry the wrong wire key) and
//! the second fails, because it exercises the real serde contract: a payload
//! carrying exactly the catalog's keys must round-trip identically, and
//! removing any one of them must be a deserialization error.

use eql_scalars::{Term, CATALOG};
use eql_types::v3::registry;
use serde_json::{json, Value};

/// Mirrors `ENVELOPE_KEYS` in `eql-codegen/src/consts.rs` (`pub(crate)`
/// there, so restated here): the keys every generated domain CHECK requires
/// before its term keys.
const ENVELOPE_KEYS: &[&str] = &["v", "i", "c"];

/// A synthetic wire value for a required key, by key name.
fn synthesize(key: &str) -> Value {
    match key {
        "v" => json!(2),
        "i" => json!({ "t": "users", "c": "field" }),
        "c" => json!("mp_base85_ciphertext"),
        "hm" => json!("deadbeef"),
        "ob" => json!(["ore_block_0", "ore_block_1"]),
        "bf" => json!([-1, 0, 32767]),
        other => panic!("no synthetic value for unexpected catalog key {other:?}"),
    }
}

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

/// Every domain's wire keys are exactly envelope + catalog terms, proven
/// behaviourally through serde:
///
/// - a payload carrying exactly those keys round-trips **identically**, so
///   the type requires nothing more and emits nothing less;
/// - removing any one key fails deserialization, so every key is required
///   (no `Option` has crept in).
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

            let keys: Vec<&str> = ENVELOPE_KEYS
                .iter()
                .copied()
                .chain(Term::term_json_keys(domain.terms))
                .collect();

            let full: Value = keys
                .iter()
                .map(|k| (k.to_string(), synthesize(k)))
                .collect::<serde_json::Map<_, _>>()
                .into();
            let round_tripped = (entry.roundtrip)(full.clone()).unwrap_or_else(|e| {
                panic!(
                    "{name} ({}): catalog payload rejected: {e}",
                    entry.type_name
                )
            });
            assert_eq!(
                round_tripped, full,
                "{name} ({}): round-trip must be identity over the catalog keys",
                entry.type_name
            );

            for key in &keys {
                let mut partial = full.clone();
                partial.as_object_mut().unwrap().remove(*key);
                assert!(
                    (entry.roundtrip)(partial).is_err(),
                    "{name} ({}): must reject payload missing required key {key:?}",
                    entry.type_name
                );
            }
        }
    }
}
