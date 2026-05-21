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
//! - [`int4`] — **NEW** (targets EQL 2.4). Design freedom. Demonstrates
//!   *capability-encoded types* — the pattern that removes the runtime
//!   index-term guessing `eql_v2_encrypted` forces onto every consumer.
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

pub mod int4;
pub mod v2_3;

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
