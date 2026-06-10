//! # eql-types — canonical EQL payload types
//!
//! One Rust definition per EQL payload shape — the single source of truth
//! for every tool that produces or consumes EQL payloads
//! (`cipherstash-client`, `protect-ffi`, CipherStash Proxy). TypeScript
//! bindings and JSON Schemas are generated from these definitions in
//! stacked changes; the Rust types are the contract.
//!
//! The [`v3`] module holds the `eql_v3` encrypted-domain types: one struct
//! per SQL domain (`eql_v3.int4_eq`, `eql_v3.text_match`, …),
//! *capability-encoded* — index terms are required fields, never `Option`.
//! It mirrors `eql-scalars::CATALOG` 1:1, enforced by
//! `tests/catalog_parity.rs`.
//!
//! Wire rule: **field names ARE wire names** — no `#[serde(rename)]`
//! anywhere. The struct definition reads exactly like the JSON payload.

use serde::{Deserialize, Serialize};

pub mod v3;

/// EQL wire-format version. Hard-coded to `2` for every payload — including
/// the [`v3`] tier, whose generated domain CHECKs assert `VALUE->>'v' = '2'`.
pub const EQL_SCHEMA_VERSION: u16 = 2;

/// Table + column identifier — wire shape `{"t": "...", "c": "..."}`.
///
/// Shared by every payload.
#[derive(Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct Identifier {
    /// Table name.
    pub t: String,
    /// Column name.
    pub c: String,
}
