//! Reusable wire-field newtypes shared by every v3 domain payload.
//!
//! Each newtype serializes as its inner value (serde's newtype-struct
//! default), so the wire shape is unchanged — but the *name* survives into
//! generated artifacts: the TypeScript bindings and JSON Schemas (added in
//! stacked changes) emit these as named aliases/definitions that every
//! domain type references. A plain Rust `type` alias would vanish there.
//!
//! Names follow the SEM constructor names in `eql-scalars` (`Term::ctor()`):
//! a future scheme change (e.g. a 12-block wide ORE term for timestamptz
//! ordering) is a new newtype, not a hunt through `Vec<String>` fields.

use serde::{Deserialize, Serialize};

/// mp_base85 source ciphertext — the `c` envelope key.
///
/// Required by every v3 domain CHECK; present on every payload.
#[derive(Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct Ciphertext(pub String);

/// HMAC-SHA-256 equality term — the `hm` wire key. Backs the `_eq` domains
/// (`=`, `<>`). SQL-side constructor: `eql_v3.hmac_256`.
#[derive(Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct Hmac256(pub String);

/// Block-ORE (u64, 8 blocks, 256) order term — the `ob` wire key. Backs the
/// `_ord` / `_ord_ore` domains (`=` `<>` `<` `<=` `>` `>=`); ORE is lossless
/// over the scalar's domain, so it serves equality too. SQL-side constructor:
/// `eql_v3.ore_block_u64_8_256`.
#[derive(Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct OreBlockU64_8_256(pub Vec<String>);

/// Bloom-filter match term — the `bf` wire key. Backs the `_match` domains
/// (`~~` containment via `@>`/`<@`).
///
/// **Signed** i16, not u16: EQL stores the filter as PostgreSQL `smallint[]`,
/// and filters sized above 32768 emit upper-half bit positions as negative
/// signed values.
#[derive(Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct BloomFilter(pub Vec<i16>);

impl From<String> for Ciphertext {
    fn from(value: String) -> Self {
        Self(value)
    }
}

impl From<String> for Hmac256 {
    fn from(value: String) -> Self {
        Self(value)
    }
}

impl From<Vec<String>> for OreBlockU64_8_256 {
    fn from(value: Vec<String>) -> Self {
        Self(value)
    }
}

impl From<Vec<i16>> for BloomFilter {
    fn from(value: Vec<i16>) -> Self {
        Self(value)
    }
}
