//! JSON Schema export — runs during `cargo test` (alongside ts-rs's own
//! export tests, which write `bindings/`). Output is checked in; freshness
//! is enforced by `mise run types:check`. Schema files are named after the
//! SQL domain — the protocol identity — not the Rust type.
//!
//! Output base defaults to `schema/` (relative to the crate dir, where
//! `cargo test` runs), so a plain `cargo test` regenerates the checked-in
//! tree. `EQL_TYPES_SCHEMA_DIR` overrides it — mirroring ts-rs's
//! `TS_RS_EXPORT_DIR` — so `mise run types:generate` can redirect output to a
//! throwaway temp dir and only swap it into place after a successful build.

use eql_types::v3;

#[test]
fn dump_v3_json_schemas() {
    let base = std::env::var("EQL_TYPES_SCHEMA_DIR").unwrap_or_else(|_| "schema".into());
    let dir = format!("{base}/v3");
    std::fs::create_dir_all(&dir).unwrap();
    for entry in v3::all() {
        let mut schema = serde_json::to_value(entry.schema()).unwrap();
        // schemars 0.8 emits no $id; inject the canonical one.
        schema.as_object_mut().unwrap().insert(
            "$id".into(),
            format!(
                "https://schemas.cipherstash.com/eql/v3/{}.json",
                entry.domain()
            )
            .into(),
        );
        std::fs::write(
            format!("{dir}/{}.json", entry.domain()),
            serde_json::to_string_pretty(&schema).unwrap(),
        )
        .unwrap();
    }
}
