//! # `eql_v3` domain payload types
//!
//! One Rust struct per **SQL domain** in the `eql_v3` schema — the
//! capability-encoded design from the original `eql_v2_int4` prototype
//! (PR #236's first cut), formalized:
//! the SQL surface is generated from `eql-scalars::CATALOG`, and these types
//! mirror it 1:1 (enforced by `tests/catalog_parity.rs`, which fails if the
//! catalog and this module ever disagree on domains or required wire keys).
//!
//! **Versioning.** "v3" is the SQL schema generation (`eql_v3.*` domains).
//! The JSON envelope version is still `v: 2` ([`crate::EQL_SCHEMA_VERSION`]) —
//! every generated domain CHECK asserts `VALUE->>'v' = '2'`, and the wire
//! field names are unchanged from v2 (`hm`/`ob`/`bf`; the purpose-named
//! rename in the payload-scheme-discipline RFC is deferred).
//!
//! ## Shape of every payload
//!
//! Envelope (required by every domain CHECK, mirroring `ENVELOPE_KEYS` in
//! `eql-codegen/src/consts.rs`): `v`, `i`, `c`. Then the domain's required
//! term keys — `hm` for `_eq`, `ob` for `_ord`/`_ord_ore`, `bf` for
//! `_match`, none for storage-only. `Option` does not appear in this
//! module: the capability **is** the type identity. Hold a
//! [`int4::Int4Eq`] and `hm` is present, guaranteed by the Rust type and
//! (SQL-side) by the domain CHECK. A missing term key is a deserialization
//! error — the Rust analogue of the CHECK constraint.
//!
//! The types are also **strict**: every struct is
//! `#[serde(deny_unknown_fields)]`, so a payload carrying keys outside the
//! domain's set fails to deserialize rather than being silently stripped on
//! the next serialize (a pass-through consumer must not lose data it didn't
//! know about), and the `v` field is [`crate::SchemaVersion`], which rejects
//! any version other than `2`.
//!
//! ## Why there is no discriminated enum
//!
//! Cross-token: impossible — an `int4_eq` and an `int8_eq` payload are
//! byte-identical on the wire (`v`/`i`/`c`/`hm`); nothing discriminates them.
//! Per-token: deliberately omitted — an untagged enum over a token's domains
//! would discriminate by key-sniffing, the exact `v2_3::SteVecTerm` failure
//! mode this tier exists to retire, and `_ord` vs `_ord_ore` are identical
//! shapes that no sniffing can separate. Consumers read from a typed column
//! and already know the domain.

use std::marker::PhantomData;

use serde::{de::DeserializeOwned, Serialize};

pub mod date;
pub mod int2;
pub mod int4;
pub mod int8;
pub mod terms;
pub mod text;
pub mod timestamptz;

/// The PostgreSQL schema every domain in this module inhabits.
pub const SQL_SCHEMA: &str = "eql_v3";

/// Implemented by every v3 domain payload type: the fully-qualified SQL
/// domain the payload inhabits (e.g. `"eql_v3.int4_eq"`).
///
/// The [`DomainType`] blanket impl derives everything else from this
/// constant, so the type ↔ domain binding has exactly one definition per
/// type — there is no second string to keep in sync, and two same-shaped
/// types (`_ord` vs `_ord_ore`) cannot be enumerated under each other's
/// domain.
pub trait V3Domain {
    /// Fully-qualified SQL domain, e.g. `"eql_v3.int4_eq"`.
    const SQL_DOMAIN: &'static str;
}

/// Object-safe view of one v3 domain type — what [`all`] enumerates.
///
/// Implemented once, by the blanket impl below, for `PhantomData<T>` over
/// every payload type: a `Box<dyn DomainType>` is a zero-sized type-level
/// handle, not a payload instance. (The trait cannot be [`V3Domain`] itself:
/// an associated const is not object-safe, and [`Self::roundtrip`] needs
/// `Deserialize`, which is `Sized`-only — so the dyn surface lives on the
/// handle, and `V3Domain` stays the compile-time anchor it reads from.)
///
/// Consumed by `tests/catalog_parity.rs` (which asserts [`all`] exactly
/// covers `eql-scalars::CATALOG`, so the list cannot silently go stale) and
/// by the binding/schema exporters added in stacked changes. Public so FFI
/// consumers can enumerate the protocol surface too.
pub trait DomainType {
    /// Fully-qualified SQL domain name, e.g. `"eql_v3.int4_eq"`.
    fn sql_domain(&self) -> &'static str;

    /// Unqualified SQL domain name (e.g. `"int4_eq"`) — [`Self::sql_domain`]
    /// minus the schema qualifier; matches `eql-scalars`
    /// `ScalarSpec::domain_name`.
    fn domain(&self) -> &'static str {
        self.sql_domain()
            .strip_prefix("eql_v3.")
            .expect("SQL_DOMAIN must be qualified with the eql_v3 schema")
    }

    /// The Rust type's full path (via `std::any::type_name`).
    fn type_name(&self) -> &'static str;

    /// serde round-trip through the concrete type (`Value` → `T` → `Value`).
    fn roundtrip(&self, value: serde_json::Value) -> Result<serde_json::Value, serde_json::Error>;
}

impl<T> DomainType for PhantomData<T>
where
    T: V3Domain + DeserializeOwned + Serialize,
{
    fn sql_domain(&self) -> &'static str {
        T::SQL_DOMAIN
    }

    fn type_name(&self) -> &'static str {
        std::any::type_name::<T>()
    }

    fn roundtrip(&self, value: serde_json::Value) -> Result<serde_json::Value, serde_json::Error> {
        let parsed: T = serde_json::from_value(value)?;
        serde_json::to_value(&parsed)
    }
}

/// Every v3 domain type, in `eql-scalars::CATALOG` order (token order, then
/// each token's domains in manifest order) — the one hand-maintained list of
/// types in the crate.
pub fn all() -> Vec<Box<dyn DomainType>> {
    vec![
        Box::new(PhantomData::<int4::Int4>),
        Box::new(PhantomData::<int4::Int4Eq>),
        Box::new(PhantomData::<int4::Int4OrdOre>),
        Box::new(PhantomData::<int4::Int4Ord>),
        Box::new(PhantomData::<int2::Int2>),
        Box::new(PhantomData::<int2::Int2Eq>),
        Box::new(PhantomData::<int2::Int2OrdOre>),
        Box::new(PhantomData::<int2::Int2Ord>),
        Box::new(PhantomData::<int8::Int8>),
        Box::new(PhantomData::<int8::Int8Eq>),
        Box::new(PhantomData::<int8::Int8OrdOre>),
        Box::new(PhantomData::<int8::Int8Ord>),
        Box::new(PhantomData::<date::Date>),
        Box::new(PhantomData::<date::DateEq>),
        Box::new(PhantomData::<date::DateOrdOre>),
        Box::new(PhantomData::<date::DateOrd>),
        Box::new(PhantomData::<timestamptz::Timestamptz>),
        Box::new(PhantomData::<timestamptz::TimestamptzEq>),
        Box::new(PhantomData::<text::Text>),
        Box::new(PhantomData::<text::TextEq>),
        Box::new(PhantomData::<text::TextMatch>),
        Box::new(PhantomData::<text::TextOrdOre>),
        Box::new(PhantomData::<text::TextOrd>),
    ]
}
