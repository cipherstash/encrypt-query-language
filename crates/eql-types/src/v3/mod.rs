//! # `eql_v3` domain payload types
//!
//! One Rust struct per **SQL domain** in the `eql_v3` schema — the
//! capability-encoded design from the original `eql_v2_int4` prototype
//! (PR #236's first cut), formalized:
//! the SQL surface is generated from `eql-scalars::CATALOG`, and these types
//! mirror it 1:1 (enforced by `tests/catalog_parity.rs`, which fails if the
//! catalog and [`all`] ever disagree on the set or order of domains; the
//! catalog-derived wire-key gate is schema-based and lands with the stacked
//! schemars change, with per-type strictness spot checks in
//! `tests/v3_conformance.rs`).
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

use schemars::{schema::RootSchema, schema_for, JsonSchema};

pub mod date;
pub mod int2;
pub mod int4;
pub mod int8;
pub mod terms;
pub mod text;
pub mod timestamptz;

/// The PostgreSQL schema every domain in this module inhabits.
pub const SQL_SCHEMA: &str = "eql_v3";

/// Base URL for the canonical `$id` of every published v3 JSON Schema.
/// The per-domain `$id` is `{SCHEMA_ID_BASE}{domain}.json` (see
/// [`DomainType::schema_id`]); `tests/export.rs` injects it at write time.
pub const SCHEMA_ID_BASE: &str = "https://schemas.cipherstash.com/eql/v3/";

/// One v3 domain type — implemented by every payload type, so any payload
/// value can report the SQL domain it inhabits (`payload.sql_domain()`).
///
/// Each token file implements this next to the type it describes; the SQL
/// domain string is defined exactly once, in that impl, and
/// `tests/catalog_parity.rs` cross-checks every entry of [`all`] against
/// `eql-scalars::CATALOG` — a typo'd or mis-ordered domain fails there.
/// Public so FFI consumers can enumerate the protocol surface too.
pub trait DomainType {
    /// Fully-qualified SQL domain name, e.g. `"eql_v3.int4_eq"` — the
    /// per-type fact everything else derives from, defined once in each
    /// type's impl.
    ///
    /// `where Self: Sized` keeps the trait object-safe (the method is
    /// excluded from the vtable); through `dyn DomainType`, use
    /// [`Self::sql_domain`].
    fn sql_domain_static() -> &'static str
    where
        Self: Sized;

    /// Fully-qualified SQL domain name of this payload value.
    fn sql_domain(&self) -> &'static str;

    /// Unqualified SQL domain name (e.g. `"int4_eq"`) — [`Self::sql_domain`]
    /// minus the schema qualifier; matches `eql-scalars`
    /// `ScalarSpec::domain_name`.
    fn domain(&self) -> &'static str {
        self.sql_domain()
            .strip_prefix("eql_v3.")
            .expect("sql_domain must be qualified with the eql_v3 schema")
    }

    /// Canonical `$id` for this domain's published JSON Schema —
    /// `{SCHEMA_ID_BASE}{domain}.json`. The single source of truth for the
    /// identity `tests/export.rs` injects; pinned by `tests/catalog_parity.rs`.
    fn schema_id(&self) -> String {
        format!("{SCHEMA_ID_BASE}{}.json", self.domain())
    }

    /// The type's JSON Schema.
    fn schema(&self) -> RootSchema;
}

/// Type-level handle: lets [`all`] enumerate the domain types without
/// payload values to box — `Box::new(PhantomData::<Int4Eq>)` is zero-sized,
/// and the delegation goes through [`DomainType::sql_domain_static`], so no
/// payload instance is ever constructed.
impl<T> DomainType for PhantomData<T>
where
    T: DomainType + JsonSchema,
{
    fn sql_domain_static() -> &'static str {
        T::sql_domain_static()
    }

    fn sql_domain(&self) -> &'static str {
        T::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(T)
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
        Box::new(PhantomData::<text::TextSearch>),
    ]
}
