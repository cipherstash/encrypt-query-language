//! The `int8` encrypted-domain family. Same four-domain ordered shape as
//! [`crate::v3::int4`] — see that module for the capability table.

use schemars::{schema::RootSchema, schema_for};

use crate::v3::terms::{Ciphertext, Hmac256, OreBlockU64_8_256};
use crate::v3::DomainType;
use crate::{Identifier, SchemaVersion};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use ts_rs::TS;

/// `eql_v3.int8` — storage only; every operator is blocked.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct Int8 {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
}

impl DomainType for Int8 {
    fn sql_domain_static() -> &'static str {
        "eql_v3.int8"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(Int8)
    }
}

/// `eql_v3.int8_eq` — HMAC equality (`=`, `<>`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct Int8Eq {
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

impl DomainType for Int8Eq {
    fn sql_domain_static() -> &'static str {
        "eql_v3.int8_eq"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(Int8Eq)
    }
}

/// `eql_v3.int8_ord_ore` — full comparison, scheme-explicit name.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct Int8OrdOre {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// Block-ORE order term. Serves equality too.
    pub ob: OreBlockU64_8_256,
}

impl DomainType for Int8OrdOre {
    fn sql_domain_static() -> &'static str {
        "eql_v3.int8_ord_ore"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(Int8OrdOre)
    }
}

/// `eql_v3.int8_ord` — full comparison (`=` `<>` `<` `<=` `>` `>=`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct Int8Ord {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// Block-ORE order term. Serves equality too.
    pub ob: OreBlockU64_8_256,
}

impl DomainType for Int8Ord {
    fn sql_domain_static() -> &'static str {
        "eql_v3.int8_ord"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(Int8Ord)
    }
}

// jsonb `Type`/`Encode`/`Decode` for the domain types (feature `sqlx`), via the
// shared macro.
#[cfg(feature = "sqlx")]
mod sqlx_impls {
    use super::{Int8, Int8Eq, Int8Ord, Int8OrdOre};
    use crate::v3::sqlx_support::jsonb_domain_sqlx;

    jsonb_domain_sqlx!(Int8, Int8Eq, Int8Ord, Int8OrdOre);
}

/// SQL-backed property tests for the `int8` family (issue #237) — the same
/// ordered shape as int4 (see `crate::v3::int4`), with plaintext `i64`. All the
/// boilerplate and the comparison-oracle logic live in `proptest_support`, so
/// this is just the int8 wiring + the per-function properties: adding a scalar
/// family is three macro invocations plus the readable properties.
#[cfg(all(test, feature = "proptest"))]
mod prop_tests {
    use super::{Int8Eq, Int8Ord, Int8OrdOre};
    use crate::v3::proptest_support::{
        eq, eq_term, gt, gte, impl_eq_domain, impl_ord_domain, lt, lte, neq, ord_term,
    };

    // v2→v3 conversions + `EncryptableScalar` + `Arbitrary` + capability markers.
    impl_eq_domain!(Int8Eq, i64);
    impl_ord_domain!(Int8Ord, i64);
    impl_ord_domain!(Int8OrdOre, i64);

    // Each mod is the SQL surface of one domain, one macro per generated
    // function (see `crate::v3::int4` for the annotated `eql_v3.*` signatures).
    mod int8_eq {
        use super::*;
        eq_term!(Int8Eq);
        eq!(Int8Eq, Int8Eq);
        eq!(Int8Eq, Jsonb<Int8Eq>);
        eq!(Jsonb<Int8Eq>, Int8Eq);
        neq!(Int8Eq, Int8Eq);
        neq!(Int8Eq, Jsonb<Int8Eq>);
        neq!(Jsonb<Int8Eq>, Int8Eq);
    }

    mod int8_ord {
        use super::*;
        ord_term!(Int8Ord);
        eq!(Int8Ord, Int8Ord);
        eq!(Int8Ord, Jsonb<Int8Ord>);
        eq!(Jsonb<Int8Ord>, Int8Ord);
        neq!(Int8Ord, Int8Ord);
        neq!(Int8Ord, Jsonb<Int8Ord>);
        neq!(Jsonb<Int8Ord>, Int8Ord);
        lt!(Int8Ord, Int8Ord);
        lt!(Int8Ord, Jsonb<Int8Ord>);
        lt!(Jsonb<Int8Ord>, Int8Ord);
        lte!(Int8Ord, Int8Ord);
        lte!(Int8Ord, Jsonb<Int8Ord>);
        lte!(Jsonb<Int8Ord>, Int8Ord);
        gt!(Int8Ord, Int8Ord);
        gt!(Int8Ord, Jsonb<Int8Ord>);
        gt!(Jsonb<Int8Ord>, Int8Ord);
        gte!(Int8Ord, Int8Ord);
        gte!(Int8Ord, Jsonb<Int8Ord>);
        gte!(Jsonb<Int8Ord>, Int8Ord);
    }

    mod int8_ord_ore {
        use super::*;
        ord_term!(Int8OrdOre);
        eq!(Int8OrdOre, Int8OrdOre);
        eq!(Int8OrdOre, Jsonb<Int8OrdOre>);
        eq!(Jsonb<Int8OrdOre>, Int8OrdOre);
        neq!(Int8OrdOre, Int8OrdOre);
        neq!(Int8OrdOre, Jsonb<Int8OrdOre>);
        neq!(Jsonb<Int8OrdOre>, Int8OrdOre);
        lt!(Int8OrdOre, Int8OrdOre);
        lt!(Int8OrdOre, Jsonb<Int8OrdOre>);
        lt!(Jsonb<Int8OrdOre>, Int8OrdOre);
        lte!(Int8OrdOre, Int8OrdOre);
        lte!(Int8OrdOre, Jsonb<Int8OrdOre>);
        lte!(Jsonb<Int8OrdOre>, Int8OrdOre);
        gt!(Int8OrdOre, Int8OrdOre);
        gt!(Int8OrdOre, Jsonb<Int8OrdOre>);
        gt!(Jsonb<Int8OrdOre>, Int8OrdOre);
        gte!(Int8OrdOre, Int8OrdOre);
        gte!(Int8OrdOre, Jsonb<Int8OrdOre>);
        gte!(Jsonb<Int8OrdOre>, Int8OrdOre);
    }
}
