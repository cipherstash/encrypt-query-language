//! Reusable wire-field newtypes shared by every v3 domain payload.
//!
//! Each newtype serializes as its inner value (serde's newtype-struct
//! default), so the wire shape is unchanged — but the *name* survives into
//! generated artifacts: ts-rs exports a named TS alias
//! (`export type Hmac256 = string`) that every domain binding imports, and
//! schemars registers a named definition that every domain schema `$ref`s.
//! A plain Rust `type` alias would vanish in both outputs.
//!
//! Names follow the SEM constructor names in `eql-scalars` (`Term::ctor()`):
//! a future scheme change (e.g. a 12-block wide ORE term for timestamptz
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

/// Block-ORE (u64, 8 blocks, 256) order term — the `ob` wire key. Backs the
/// `_ord` / `_ord_ore` domains (`=` `<>` `<` `<=` `>` `>=`); ORE is lossless
/// over the scalar's domain, so it serves equality too. SQL-side constructor:
/// `eql_v3.ore_block_u64_8_256`.
#[derive(Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct OreBlockU64_8_256(pub Vec<String>);

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
    fn schema_name() -> String {
        "BloomFilter".to_owned()
    }

    fn json_schema(_: &mut schemars::gen::SchemaGenerator) -> schemars::schema::Schema {
        use schemars::schema::{
            ArrayValidation, InstanceType, Metadata, NumberValidation, Schema, SchemaObject,
        };
        let items = SchemaObject {
            instance_type: Some(InstanceType::Integer.into()),
            format: Some("int16".to_owned()),
            number: Some(Box::new(NumberValidation {
                minimum: Some(f64::from(i16::MIN)),
                maximum: Some(f64::from(i16::MAX)),
                ..Default::default()
            })),
            ..Default::default()
        };
        SchemaObject {
            instance_type: Some(InstanceType::Array.into()),
            array: Some(Box::new(ArrayValidation {
                items: Some(Schema::Object(items).into()),
                ..Default::default()
            })),
            metadata: Some(Box::new(Metadata {
                // KEEP IN SYNC with the doc comment on `BloomFilter` above — it
                // is the canonical text. A derived `JsonSchema` would copy the
                // doc comment automatically; this manual impl can't, so this
                // hand-written paraphrase must be updated alongside it.
                description: Some(
                    "Bloom-filter match term — the `bf` wire key. Backs the `_match` \
                     domains (`@>`/`<@` containment). Signed i16: EQL stores the filter \
                     as PostgreSQL `smallint[]`, and filters sized above 32768 emit \
                     upper-half bit positions as negative signed values."
                        .to_owned(),
                ),
                ..Default::default()
            })),
            ..Default::default()
        }
        .into()
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
