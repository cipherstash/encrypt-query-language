//! # `eql_v3` domain payload types
//!
//! One Rust struct per **SQL domain** in the `eql_v3` schema — the
//! capability-encoded design from the [`crate::int4`] prototype, formalized:
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
//! Envelope (required by every domain CHECK): `v`, `i`, `c`. Then the
//! domain's required term keys — `hm` for `_eq`, `ob` for `_ord`/`_ord_ore`,
//! `bf` for `_match`, none for storage-only. `Option` does not appear in
//! this module: the capability **is** the type identity. Hold a
//! [`int4::Int4Eq`] and `hm` is present, guaranteed by the Rust type and
//! (SQL-side) by the domain CHECK.
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

/// Defines one `eql_v3` domain payload type: the required envelope
/// (`v`, `i`, `c` — mirrors `ENVELOPE_KEYS` in `eql-codegen/src/consts.rs`)
/// plus the domain's required term fields. No `Option`, ever — a missing
/// term key is a deserialization error, the Rust analogue of the SQL
/// domain's CHECK constraint.
macro_rules! eql_v3_domain {
    (
        $(#[$meta:meta])*
        $name:ident, domain = $domain:literal
        $(, terms { $( $(#[$tmeta:meta])* $tkey:ident : $tty:ty ),+ $(,)? })?
    ) => {
        $(#[$meta])*
        #[derive(Clone, Debug, PartialEq, ::serde::Serialize, ::serde::Deserialize,
                 ::ts_rs::TS, ::schemars::JsonSchema)]
        #[ts(export, export_to = "v3/")]
        pub struct $name {
            /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`).
            pub v: u16,
            /// Table/column identifier. Required by the domain CHECK.
            pub i: $crate::Identifier,
            /// mp_base85 source ciphertext. Required by the domain CHECK.
            pub c: $crate::v3::terms::Ciphertext,
            $($(
                $(#[$tmeta])*
                pub $tkey: $tty,
            )+)?
        }

        impl $name {
            /// Fully-qualified SQL domain this payload inhabits.
            pub const SQL_DOMAIN: &'static str = concat!("eql_v3.", $domain);
        }
    };
}
pub(crate) use eql_v3_domain;
