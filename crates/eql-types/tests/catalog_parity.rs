//! The drift gate: the v3 domain inventory must mirror `eql-scalars::CATALOG` — the
//! same catalog that generates the `eql_v3` SQL surface — exactly. Append a
//! scalar to the catalog without adding its types here and the first test
//! fails; let a term field become `Option` (or carry the wrong wire key) and
//! the second fails, because it exercises the real serde contract: a payload
//! carrying exactly the catalog's keys must round-trip identically, and
//! removing any one of them must be a deserialization error.

use eql_scalars::{Term, CATALOG, ENVELOPE_KEYS};
use eql_types::v3;
use serde_json::{json, Value};

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

/// Every domain's wire keys are exactly envelope + catalog terms, proven
/// behaviourally through serde:
///
/// - a payload carrying exactly those keys round-trips **identically**, so
///   the type requires nothing more and emits nothing less;
/// - removing any one key fails deserialization, so every key is required
///   (no `Option` has crept in);
/// - adding a key outside the set fails deserialization
///   (`deny_unknown_fields` — no silent stripping on re-serialize);
/// - a wrong envelope version fails deserialization (`SchemaVersion`
///   mirrors the domain CHECK's `VALUE->>'v' = '2'`).
#[test]
fn required_keys_match_catalog_terms() {
    let entries = v3::all();
    for spec in CATALOG {
        for domain in spec.domains {
            let name = spec.domain_name(domain);
            let entry = entries
                .iter()
                .find(|e| e.domain() == name)
                .unwrap_or_else(|| panic!("no domain inventory entry for {name}"));

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
            let round_tripped = entry.roundtrip(full.clone()).unwrap_or_else(|e| {
                panic!(
                    "{name} ({}): catalog payload rejected: {e}",
                    entry.type_name()
                )
            });
            assert_eq!(
                round_tripped,
                full,
                "{name} ({}): round-trip must be identity over the catalog keys",
                entry.type_name()
            );

            for key in &keys {
                let mut partial = full.clone();
                partial.as_object_mut().unwrap().remove(*key);
                assert!(
                    entry.roundtrip(partial).is_err(),
                    "{name} ({}): must reject payload missing required key {key:?}",
                    entry.type_name()
                );
            }

            let mut extra = full.clone();
            extra
                .as_object_mut()
                .unwrap()
                .insert("zz".into(), json!(true));
            assert!(
                entry.roundtrip(extra).is_err(),
                "{name} ({}): must reject payload carrying an unknown key",
                entry.type_name()
            );

            let mut wrong_version = full.clone();
            wrong_version
                .as_object_mut()
                .unwrap()
                .insert("v".into(), json!(3));
            assert!(
                entry.roundtrip(wrong_version).is_err(),
                "{name} ({}): must reject envelope version other than 2",
                entry.type_name()
            );
        }
    }
}
