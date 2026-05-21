//! # `eql_v2_int4` variant family — NEW (targets EQL 2.4)
//!
//! Where [`crate::v2_3`] is frozen, this module has design freedom. It mirrors
//! the SQL domain family from `encrypt-query-language#225`.
//!
//! ## The idea: capability-encoded types
//!
//! `eql_v2_encrypted` is one mega-type with every index term optional — so a
//! consumer must runtime-check "do I have an `hm`?". The int4 family instead
//! splits storage into one type per **capability**:
//!
//! | Rust type   | SQL domain          | Required keys | Operators                  |
//! |-------------|---------------------|---------------|----------------------------|
//! | [`Int4`]    | `eql_v2_int4`       | `c`           | none (storage only)        |
//! | [`Int4Eq`]  | `eql_v2_int4_eq`    | `c`, `hm`     | `=` `<>`                   |
//! | [`Int4Ord`] | `eql_v2_int4_ord`   | `c`, `ob`     | `=` `<>` `<` `<=` `>` `>=` |
//!
//! The capability is the **type identity**. There are no optional index-term
//! fields: hold an [`Int4Eq`] and `hm` is present — guaranteed by the Rust
//! type, and (on the SQL side) by the domain's `CHECK` constraint. The runtime
//! guard the `protect-dynamodb` bug reached for becomes impossible to need.
//!
//! `Option` does not appear in this module.

use crate::Identifier;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use ts_rs::TS;

/// `eql_v2_int4` — storage only. Carries `c`; every operator is blocked.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export)]
pub struct Int4 {
    /// Schema version.
    pub v: u16,
    /// Table/column identifier.
    pub i: Identifier,
    /// mp_base85 ciphertext. Required by the domain's CHECK constraint.
    pub c: String,
}

/// `eql_v2_int4_eq` — HMAC equality (`=`, `<>`).
///
/// `hm` is a required field. There is no `Option`: the type *is* the
/// equality capability. A payload without `hm` cannot be deserialized into
/// this type — the Rust analogue of the SQL domain's CHECK constraint.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export)]
pub struct Int4Eq {
    /// Schema version.
    pub v: u16,
    /// Table/column identifier.
    pub i: Identifier,
    /// mp_base85 ciphertext. Required.
    pub c: String,
    /// HMAC-SHA256 equality term. Required.
    pub hm: String,
}

/// `eql_v2_int4_ord` — equality + ORE-block range (`=` `<>` `<` `<=` `>` `>=`).
///
/// Deliberately carries no `hm`: ORE over a full-domain `int4` is lossless, so
/// the order term `ob` doubles as an exact equality term.
/// (`eql_v2_int4_ord_ore` in #225 is the same shape under a scheme-explicit
/// name — structurally identical, so it is not a separate Rust type.)
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export)]
pub struct Int4Ord {
    /// Schema version.
    pub v: u16,
    /// Table/column identifier.
    pub i: Identifier,
    /// mp_base85 ciphertext. Required.
    pub c: String,
    /// Block ORE term. Required — serves both range and equality.
    pub ob: Vec<String>,
}

// ===========================================================================
// PROPOSAL (beyond #225) — a self-describing wire discriminator
// ===========================================================================
//
// On the wire, an int4 payload is discriminated only by *which key is present*
// (`hm` vs `ob`). The SQL domain name carries the rest — but once the JSON
// leaves SQL (into protect-ffi, into TypeScript, into a log line) that
// information is gone and a consumer is back to sniffing keys: the same
// untagged failure mode that produced the original protect-dynamodb bug.
//
// While the int4 family is still pre-release, a one-field capability tag `x`
// makes every payload self-describing and gives Rust / TS / SQL a single
// literal discriminant. This is the tagged-union lesson applied to a type we
// are still free to change.

/// **Proposed.** Self-describing int4 payload — `x` is the capability tag.
///
/// Generates a clean TypeScript discriminated union (`switch (p.x)` with
/// exhaustiveness) and a JSON Schema `oneOf` with a per-branch `const`.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export)]
#[serde(tag = "x")]
pub enum Int4Tagged {
    /// `x: "int4"` — storage only.
    #[serde(rename = "int4")]
    Storage {
        v: u16,
        i: Identifier,
        c: String,
    },
    /// `x: "int4_eq"` — HMAC equality.
    #[serde(rename = "int4_eq")]
    Eq {
        v: u16,
        i: Identifier,
        c: String,
        hm: String,
    },
    /// `x: "int4_ord"` — equality + ORE-block range.
    #[serde(rename = "int4_ord")]
    Ord {
        v: u16,
        i: Identifier,
        c: String,
        ob: Vec<String>,
    },
}
