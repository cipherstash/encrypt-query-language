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

/// The envelope version field (`v`) — always exactly [`EQL_SCHEMA_VERSION`]
/// on the wire.
///
/// Deserialization rejects any other value: the Rust analogue of the domain
/// CHECK's `VALUE->>'v' = '2'`, so a wrong-version payload fails at the type
/// boundary instead of at INSERT. The inner value is private; the only
/// constructible instance is the current version.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash, Serialize)]
pub struct SchemaVersion(u16);

impl SchemaVersion {
    /// The current (only) wire version, `2`.
    pub const CURRENT: Self = Self(EQL_SCHEMA_VERSION);

    /// The wire value.
    pub const fn get(self) -> u16 {
        self.0
    }
}

impl Default for SchemaVersion {
    fn default() -> Self {
        Self::CURRENT
    }
}

impl<'de> Deserialize<'de> for SchemaVersion {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let v = u16::deserialize(deserializer)?;
        if v == EQL_SCHEMA_VERSION {
            Ok(Self(v))
        } else {
            Err(serde::de::Error::custom(format!(
                "unsupported EQL schema version {v} (expected {EQL_SCHEMA_VERSION})"
            )))
        }
    }
}

/// Table + column identifier — wire shape `{"t": "...", "c": "..."}`.
///
/// Shared by every payload.
#[derive(Default, Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Identifier {
    /// Table name.
    pub t: String,
    /// Column name.
    pub c: String,
}
