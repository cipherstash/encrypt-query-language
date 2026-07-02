//! Reusable wire-field newtypes shared by every v3 domain payload.
//!
//! Each newtype serializes as its inner value (serde's newtype-struct
//! default), so the wire shape is unchanged — but the *name* survives into
//! generated artifacts: ts-rs exports a named TS alias
//! (`export type Hmac256 = string`) that every domain binding imports, and
//! schemars registers a named definition that every domain schema `$ref`s.
//! A plain Rust `type` alias would vanish in both outputs.
//!
//! Names follow the SEM constructor names in `eql-domains` (`Term::ctor()`):
//! a future scheme change (e.g. a 12-block wide ORE term for timestamp
//! ordering) is a new newtype, not a hunt through `Vec<String>` fields.

use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use ts_rs::TS;

/// mp_base85 source ciphertext — the `c` envelope key.
///
/// Required by every v3 domain CHECK; present on every payload.
#[derive(Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct Ciphertext(pub String);

/// HMAC-SHA-256 equality term — the `hm` wire key. Backs the `_eq` domains
/// (`=`, `<>`). SQL-side constructor: `eql_v3.hmac_256`.
#[derive(Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct Hmac256(pub String);

/// CLLW-ORE ordered term — the `oc` wire key of a SteVec entry. Backs entry
/// ordering (`<` `<=` `>` `>=`) and equality on ordered leaves. SQL-side
/// constructor: `eql_v3.ore_cllw`. A SteVec entry carries exactly one of `hm`
/// (equality) XOR `oc` (ordering) — enforced by the SQL domain CHECK.
#[derive(Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct OreCllw(pub String);

/// A SteVec selector — the `s` wire key. Addresses a JSON path leaf within an
/// encrypted document (`eql_v3.json`); present on every entry and query element.
#[derive(Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct Selector(pub String);

/// Block-ORE order term — the `ob` wire key. Backs the `_ord` / `_ord_ore`
/// domains (`=` `<>` `<` `<=` `>` `>=`); ORE is lossless over the scalar's
/// domain, so it serves equality too. The block count is width-agnostic on the
/// wire (8 for the int scalars, 12 for timestamp, 14 for numeric) — the
/// array just carries more block strings. SQL-side constructor:
/// `eql_v3.ore_block_256`.
#[derive(Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct OreBlock256(pub Vec<String>);

/// Bloom-filter match term — the `bf` wire key. Backs the `_match` domains
/// (`@>`/`<@` containment).
///
/// **Signed** i16, not u16: EQL stores the filter as PostgreSQL `smallint[]`,
/// and filters sized above 32768 emit upper-half bit positions as negative
/// signed values.
#[derive(Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize, TS)]
#[ts(export, export_to = "v3/")]
pub struct BloomFilter(pub Vec<i16>);

/// Manual schema: bounds the items to the `smallint` range — the derive
/// emits only `format: "int16"`, a non-validating annotation in draft-07,
/// so an out-of-range bit position would pass schema validation and fail
/// at the database.
impl schemars::JsonSchema for BloomFilter {
    fn schema_name() -> std::borrow::Cow<'static, str> {
        "BloomFilter".into()
    }

    fn json_schema(_: &mut schemars::SchemaGenerator) -> schemars::Schema {
        // KEEP IN SYNC with the doc comment on `BloomFilter` above — it is the
        // canonical text. A derived `JsonSchema` would copy the doc comment
        // automatically; this manual impl can't, so this hand-written
        // paraphrase must be updated alongside it.
        schemars::json_schema!({
            "type": "array",
            "items": {
                "type": "integer",
                "format": "int16",
                "minimum": i16::MIN,
                "maximum": i16::MAX,
            },
            "description": "Bloom-filter match term — the `bf` wire key. Backs the `_match` \
                            domains (`@>`/`<@` containment). Signed i16: EQL stores the filter \
                            as PostgreSQL `smallint[]`, and filters sized above 32768 emit \
                            upper-half bit positions as negative signed values.",
        })
    }
}

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

impl From<Vec<String>> for OreBlock256 {
    fn from(value: Vec<String>) -> Self {
        Self(value)
    }
}

impl From<Vec<i16>> for BloomFilter {
    fn from(value: Vec<i16>) -> Self {
        Self(value)
    }
}

impl From<String> for OreCllw {
    fn from(value: String) -> Self {
        Self(value)
    }
}

impl From<String> for Selector {
    fn from(value: String) -> Self {
        Self(value)
    }
}
