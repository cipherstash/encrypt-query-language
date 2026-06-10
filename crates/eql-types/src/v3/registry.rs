//! Runtime registry of every v3 domain type — the one hand-maintained
//! mapping from SQL domain name to Rust type.
//!
//! Three consumers: `tests/catalog_parity.rs` (asserts this list exactly
//! covers `eql-scalars::CATALOG`, so it cannot silently go stale), the
//! generic round-trip loop in `tests/v3_conformance.rs`, and the JSON Schema
//! exporter in `tests/export.rs`. Public so FFI consumers can enumerate the
//! protocol surface too.

use schemars::{schema::RootSchema, schema_for, JsonSchema};
use serde::{de::DeserializeOwned, Serialize};

use crate::v3::{date, int2, int4, int8, text, timestamptz};

/// One registered v3 domain type.
pub struct DomainType {
    /// Unqualified SQL domain name (e.g. `"int4_eq"`) — matches
    /// `eql-scalars` `ScalarSpec::domain_name`.
    pub domain: &'static str,
    /// The Rust type's full path (via `std::any::type_name`).
    pub type_name: &'static str,
    /// The type's JSON Schema.
    pub schema: fn() -> RootSchema,
    /// serde round-trip through the concrete type
    /// (`Value` → `T` → `Value`).
    pub roundtrip: fn(serde_json::Value) -> Result<serde_json::Value, serde_json::Error>,
}

fn entry<T>(domain: &'static str) -> DomainType
where
    T: DeserializeOwned + Serialize + JsonSchema,
{
    DomainType {
        domain,
        type_name: std::any::type_name::<T>(),
        schema: || schema_for!(T),
        roundtrip: |value| {
            let parsed: T = serde_json::from_value(value)?;
            serde_json::to_value(&parsed)
        },
    }
}

/// Every v3 domain type, in `eql-scalars::CATALOG` order (token order, then
/// each token's domains in manifest order).
pub fn all() -> Vec<DomainType> {
    vec![
        entry::<int4::Int4>("int4"),
        entry::<int4::Int4Eq>("int4_eq"),
        entry::<int4::Int4OrdOre>("int4_ord_ore"),
        entry::<int4::Int4Ord>("int4_ord"),
        entry::<int2::Int2>("int2"),
        entry::<int2::Int2Eq>("int2_eq"),
        entry::<int2::Int2OrdOre>("int2_ord_ore"),
        entry::<int2::Int2Ord>("int2_ord"),
        entry::<int8::Int8>("int8"),
        entry::<int8::Int8Eq>("int8_eq"),
        entry::<int8::Int8OrdOre>("int8_ord_ore"),
        entry::<int8::Int8Ord>("int8_ord"),
        entry::<date::Date>("date"),
        entry::<date::DateEq>("date_eq"),
        entry::<date::DateOrdOre>("date_ord_ore"),
        entry::<date::DateOrd>("date_ord"),
        entry::<timestamptz::Timestamptz>("timestamptz"),
        entry::<timestamptz::TimestamptzEq>("timestamptz_eq"),
        entry::<text::Text>("text"),
        entry::<text::TextEq>("text_eq"),
        entry::<text::TextMatch>("text_match"),
        entry::<text::TextOrdOre>("text_ord_ore"),
        entry::<text::TextOrd>("text_ord"),
    ]
}
