//! # `eql_v3` domain payload types
//!
//! One Rust struct per **SQL domain** in the `eql_v3` schema — the
//! capability-encoded design from the original int4 scalar prototype
//! (PR #236's first cut), formalized:
//! the SQL surface is generated from `eql-domains::CATALOG`, and these types
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
//!
//! ## Per-family caller-facing notes
//!
//! These are not derivable from the catalog and are documented here because the
//! per-family modules are generated.
//!
//! **`float8` / `float4` special values.** `-0.0` canonicalizes to `+0.0`
//! (equal under `=`, IEEE-consistent) and `±Inf` order correctly
//! (`-Inf < finite < +Inf`). **NaN is unordered and unspecified in the
//! encoder**: it can be encrypted, stored, and pass the domain CHECK, but it
//! carries **no comparison guarantee** and does NOT follow IEEE semantics. The
//! domain CHECK validates only the envelope — it cannot inspect the ciphertext
//! — so a NaN payload is never rejected server-side. **Reject NaN client-side
//! before encryption** if your column must not contain it; otherwise a NaN row
//! sorts at an arbitrary (but deterministic) position in an encrypted range
//! scan. See the `float_special` regression suite for the locked behaviour.
//!
//! **`bool` is storage-only by design.** It has no `_eq`/`_ord` domain and
//! carries no index term: a two-value column has so little cardinality that any
//! searchable index (even HMAC equality) would trivially leak the plaintext
//! distribution. The payload is `{v,i,c}` only and every operator is blocked.

pub mod bool;
pub mod date;
pub mod domain_type;
pub mod float4;
pub mod float8;
pub mod int2;
pub mod int4;
pub mod int8;
pub mod inventory;
pub mod numeric;
pub mod terms;
pub mod text;
pub mod timestamptz;

pub use domain_type::{DomainType, SCHEMA_ID_BASE, SQL_SCHEMA};
pub use inventory::all;
