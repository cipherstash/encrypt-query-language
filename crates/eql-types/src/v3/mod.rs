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

pub mod date;
pub mod int2;
pub mod int4;
pub mod int8;
pub mod registry;
pub mod terms;
pub mod text;
pub mod timestamptz;

/// The PostgreSQL schema every domain in this module inhabits.
pub const SQL_SCHEMA: &str = "eql_v3";

/// Implemented by every v3 domain payload type: the fully-qualified SQL
/// domain the payload inhabits (e.g. `"eql_v3.int4_eq"`).
///
/// The [`registry`] derives its domain names from this constant, so the
/// type ↔ domain binding has exactly one definition per type — there is no
/// second string to keep in sync, and two same-shaped types (`_ord` vs
/// `_ord_ore`) cannot be registered under each other's domain.
pub trait V3Domain {
    /// Fully-qualified SQL domain, e.g. `"eql_v3.int4_eq"`.
    const SQL_DOMAIN: &'static str;
}
