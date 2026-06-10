//! JSON Schema export — runs during `cargo test` (alongside ts-rs's own
//! export tests, which write `bindings/`). Output is checked in; freshness is
//! enforced by `mise run types:check`. v3 schema files are named after the
//! SQL domain — the protocol identity — not the Rust type.

use eql_types::v2_3::EqlEncrypted;
use eql_types::v3::registry;
use schemars::schema_for;

#[test]
fn dump_v2_3_json_schemas() {
    std::fs::create_dir_all("schema").unwrap();
    std::fs::write(
        "schema/EqlEncrypted.json",
        serde_json::to_string_pretty(&schema_for!(EqlEncrypted)).unwrap(),
    )
    .unwrap();
}

#[test]
fn dump_v3_json_schemas() {
    std::fs::create_dir_all("schema/v3").unwrap();
    for entry in registry::all() {
        let mut schema = serde_json::to_value((entry.schema)()).unwrap();
        // schemars 0.8 emits no $id; inject the canonical one.
        schema.as_object_mut().unwrap().insert(
            "$id".into(),
            format!(
                "https://schemas.cipherstash.com/eql/v3/{}.json",
                entry.domain
            )
            .into(),
        );
        std::fs::write(
            format!("schema/v3/{}.json", entry.domain),
            serde_json::to_string_pretty(&schema).unwrap(),
        )
        .unwrap();
    }
}
