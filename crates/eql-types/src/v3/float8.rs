//! The `float8` encrypted-domain family — an ordered, non-integer scalar
//! backed by IEEE-754 `double precision` (`f64`), the native width of the float
//! crypto path. Same four-domain ordered shape as [`crate::v3::int4`]; see that
//! module for the capability table.
//!
//! Both float widths encrypt through a single f64 crypto path
//! (`Plaintext::Float`), so the wire shape is identical to
//! [`crate::v3::float4`] — an 8-block `ob` term (`f64::ENCODED_LEN == 8`, same
//! as `int8`).
//!
//! ## Special values (caller-facing)
//!
//! `-0.0` canonicalizes to `+0.0` (equal under `=`, IEEE-consistent) and
//! `±Inf` order correctly (`-Inf < finite < +Inf`). **NaN is unordered and
//! unspecified in the encoder**: it can be encrypted, stored, and pass the
//! domain CHECK, but it carries **no comparison guarantee** and does NOT follow
//! IEEE semantics (where NaN compares false against everything). The domain
//! CHECK validates only the envelope — it cannot inspect the ciphertext — so a
//! NaN payload is never rejected server-side. **Reject NaN client-side before
//! encryption** if your column must not contain it; otherwise a NaN row sorts
//! at an arbitrary (but deterministic) position in an encrypted range scan
//! rather than being excluded the way native Postgres `double precision` would.
//! See the `float_special` regression suite for the locked behaviour.

use schemars::{schema::RootSchema, schema_for};

use crate::v3::terms::{Ciphertext, Hmac256, OreBlock256};
use crate::v3::DomainType;
use crate::{Identifier, SchemaVersion};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use ts_rs::TS;

/// `eql_v3.float8` — storage only; every operator is blocked.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct Float8 {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
}

impl DomainType for Float8 {
    fn sql_domain_static() -> &'static str {
        "eql_v3.float8"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(Float8)
    }
}

/// `eql_v3.float8_eq` — HMAC equality (`=`, `<>`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct Float8Eq {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// HMAC-SHA-256 equality term.
    pub hm: Hmac256,
}

impl DomainType for Float8Eq {
    fn sql_domain_static() -> &'static str {
        "eql_v3.float8_eq"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(Float8Eq)
    }
}

/// `eql_v3.float8_ord_ore` — full comparison, scheme-explicit name.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct Float8OrdOre {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// Block-ORE order term (8 blocks for float). Serves equality too.
    pub ob: OreBlock256,
}

impl DomainType for Float8OrdOre {
    fn sql_domain_static() -> &'static str {
        "eql_v3.float8_ord_ore"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(Float8OrdOre)
    }
}

/// `eql_v3.float8_ord` — full comparison (`=` `<>` `<` `<=` `>` `>=`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct Float8Ord {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// Block-ORE order term (8 blocks for float). Serves equality too.
    pub ob: OreBlock256,
}

impl DomainType for Float8Ord {
    fn sql_domain_static() -> &'static str {
        "eql_v3.float8_ord"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(Float8Ord)
    }
}
