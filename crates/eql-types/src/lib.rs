//! # eql-types — canonical EQL payload types (prototype)
//!
//! One Rust definition per EQL payload shape — the single source of truth for:
//!
//! - **Rust** — consumed directly by `cipherstash-client` / `protect-ffi`
//! - **TypeScript** — generated via `ts-rs` (run `cargo test`, see `bindings/`)
//! - **JSON Schema** — generated via `schemars` (run `cargo test`, see `schema/`)
//!
//! ## Two tiers
//!
//! - [`v2_3`] — **FROZEN.** The `eql_v2_encrypted` wire contract, in production
//!   use by customers. Mirrors `eql-payload-v2.3.schema.json`, imperfections
//!   included. Nothing here may change.
//! - [`v3`] — the `eql_v3` schema's encrypted-domain types: one struct per
//!   SQL domain (`eql_v3.int4_eq`, `eql_v3.text_match`, …), *capability-encoded*
//!   — index terms are required fields, never `Option`. Mirrors
//!   `eql-scalars::CATALOG` 1:1, enforced by `tests/catalog_parity.rs`.
//!   The wire envelope version stays `v: 2` — see the [`v3`] module docs.
//!
//! ## Codegen rules (learned from the ts-rs spike)
//!
//! 1. **Field names ARE wire names** — no `#[serde(rename)]` on fields. ts-rs
//!    silently drops a `rename` that is bundled into an attribute it can't
//!    parse (`skip_serializing_if`); having no rename removes the footgun.
//! 2. Every `Option` field carries `#[ts(optional)]`, so it generates
//!    `field?: T` rather than a required `field: T | null`.
//! 3. `serde`, `ts-rs`, and `schemars` derives travel together on every type.

use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use ts_rs::TS;

pub mod v2_3;
pub mod v3;

/// EQL wire-format version. Hard-coded to `2` for every v2.x payload.
pub const EQL_SCHEMA_VERSION: u16 = 2;

/// Table + column identifier — wire shape `{"t": "...", "c": "..."}`.
///
/// Shared by every payload in both tiers.
#[derive(Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export)]
pub struct Identifier {
    /// Table name.
    pub t: String,
    /// Column name.
    pub c: String,
}
