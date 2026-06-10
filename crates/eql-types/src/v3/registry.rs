//! Runtime registry of every v3 domain type — the one hand-maintained
//! list of types in catalog order.
//!
//! Each entry's domain name is derived from the type's own
//! [`V3Domain::SQL_DOMAIN`], so the type ↔ domain binding cannot be
//! mis-registered (there is no second string to typo or swap). Consumed by
//! `tests/catalog_parity.rs` (which asserts this list exactly covers
//! `eql-scalars::CATALOG`, so it cannot silently go stale) and by the
//! binding/schema exporters added in stacked changes. Public so FFI
//! consumers can enumerate the protocol surface too.

use serde::{de::DeserializeOwned, Serialize};

use crate::v3::{date, int2, int4, int8, text, timestamptz, V3Domain};

/// One registered v3 domain type.
pub struct DomainType {
    /// Unqualified SQL domain name (e.g. `"int4_eq"`) — `SQL_DOMAIN` minus
    /// the schema qualifier; matches `eql-scalars` `ScalarSpec::domain_name`.
    pub domain: &'static str,
    /// The Rust type's full path (via `std::any::type_name`).
    pub type_name: &'static str,
    /// serde round-trip through the concrete type
    /// (`Value` → `T` → `Value`).
    pub roundtrip: fn(serde_json::Value) -> Result<serde_json::Value, serde_json::Error>,
}

fn entry<T>() -> DomainType
where
    T: V3Domain + DeserializeOwned + Serialize,
{
    let domain = T::SQL_DOMAIN
        .strip_prefix("eql_v3.")
        .expect("SQL_DOMAIN must be qualified with the eql_v3 schema");
    DomainType {
        domain,
        type_name: std::any::type_name::<T>(),
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
        entry::<int4::Int4>(),
        entry::<int4::Int4Eq>(),
        entry::<int4::Int4OrdOre>(),
        entry::<int4::Int4Ord>(),
        entry::<int2::Int2>(),
        entry::<int2::Int2Eq>(),
        entry::<int2::Int2OrdOre>(),
        entry::<int2::Int2Ord>(),
        entry::<int8::Int8>(),
        entry::<int8::Int8Eq>(),
        entry::<int8::Int8OrdOre>(),
        entry::<int8::Int8Ord>(),
        entry::<date::Date>(),
        entry::<date::DateEq>(),
        entry::<date::DateOrdOre>(),
        entry::<date::DateOrd>(),
        entry::<timestamptz::Timestamptz>(),
        entry::<timestamptz::TimestamptzEq>(),
        entry::<text::Text>(),
        entry::<text::TextEq>(),
        entry::<text::TextMatch>(),
        entry::<text::TextOrdOre>(),
        entry::<text::TextOrd>(),
    ]
}
