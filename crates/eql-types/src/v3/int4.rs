//! The `int4` encrypted-domain family — the reference scalar.
//!
//! | Rust type      | SQL domain             | Required keys | Operators                  |
//! |----------------|------------------------|---------------|----------------------------|
//! | [`Int4`]       | `eql_v3.int4`          | `v` `i` `c`        | none (storage only)        |
//! | [`Int4Eq`]     | `eql_v3.int4_eq`       | `v` `i` `c` `hm`   | `=` `<>`                   |
//! | [`Int4OrdOre`] | `eql_v3.int4_ord_ore`  | `v` `i` `c` `ob`   | `=` `<>` `<` `<=` `>` `>=` |
//! | [`Int4Ord`]    | `eql_v3.int4_ord`      | `v` `i` `c` `ob`   | `=` `<>` `<` `<=` `>` `>=` |

use schemars::{schema::RootSchema, schema_for};

use crate::v3::terms::{Ciphertext, Hmac256, OreBlockU64_8_256};
use crate::v3::DomainType;
use crate::{Identifier, SchemaVersion};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use ts_rs::TS;

/// `eql_v3.int4` — storage only; every operator is blocked.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct Int4 {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
}

impl DomainType for Int4 {
    fn sql_domain_static() -> &'static str {
        "eql_v3.int4"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(Int4)
    }
}

/// `eql_v3.int4_eq` — HMAC equality (`=`, `<>`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct Int4Eq {
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

impl DomainType for Int4Eq {
    fn sql_domain_static() -> &'static str {
        "eql_v3.int4_eq"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(Int4Eq)
    }
}

/// `eql_v3.int4_ord_ore` — full comparison (`=` `<>` `<` `<=` `>` `>=`),
/// scheme-explicit name. Same shape as [`Int4Ord`], distinct SQL domain.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct Int4OrdOre {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// Block-ORE order term. Serves equality too — ORE over a
    /// full-domain `int4` is lossless, so no separate `hm` is carried.
    pub ob: OreBlockU64_8_256,
}

impl DomainType for Int4OrdOre {
    fn sql_domain_static() -> &'static str {
        "eql_v3.int4_ord_ore"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(Int4OrdOre)
    }
}

/// `eql_v3.int4_ord` — full comparison (`=` `<>` `<` `<=` `>` `>=`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct Int4Ord {
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

impl DomainType for Int4Ord {
    fn sql_domain_static() -> &'static str {
        "eql_v3.int4_ord"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(Int4Ord)
    }
}

// jsonb `Type`/`Encode`/`Decode` for the domain types (feature `sqlx`), via the
// shared macro — each is a jsonb-backed `eql_v3.*` DOMAIN.
#[cfg(feature = "sqlx")]
mod sqlx_impls {
    use super::{Int4, Int4Eq, Int4Ord, Int4OrdOre};
    use crate::v3::sqlx_support::jsonb_domain_sqlx;

    jsonb_domain_sqlx!(Int4, Int4Eq, Int4Ord, Int4OrdOre);
}

/// SQL-backed property tests for the `int4` family (issue #237) — a property
/// per generated SQL function of each domain (the domain's "trait"): the term
/// extractor (`eq_term`/`ord_term`) and each comparison operator across all
/// three overloads. Generates plaintext `i32`s, encrypts via cipherstash-client,
/// converts the v2 payload to the v3 struct, and asserts the function agrees
/// with the plaintext oracle. Needs Postgres (v3 SQL installed) + ZeroKMS auth
/// (`CS_*` env or `stash auth login`); panics (fails) if auth is unavailable.
///
/// The per-domain boilerplate (conversions, `EncryptableScalar`, `Arbitrary`,
/// capability markers) and the comparison-oracle logic are shared in
/// `proptest_support`; this module is just int4's wiring + the readable
/// per-function properties.
#[cfg(all(test, feature = "proptest"))]
mod prop_tests {
    use super::{Int4Eq, Int4Ord, Int4OrdOre};
    use crate::v3::proptest_support::{
        eq, eq_term, gt, gte, impl_eq_domain, impl_ord_domain, lt, lte, neq, ord_term,
    };

    // v2→v3 conversions + `EncryptableScalar` + `Arbitrary` + capability markers.
    impl_eq_domain!(Int4Eq, i32);
    impl_ord_domain!(Int4Ord, i32);
    impl_ord_domain!(Int4OrdOre, i32);

    // Each mod is the SQL surface of one domain, one macro per generated
    // function. Comments show the `eql_v3.*` signature each line stands in for.
    mod int4_eq {
        use super::*;
        eq_term!(Int4Eq); //                  eql_v3.eq_term(int4_eq) -> hmac_256
        eq!(Int4Eq, Int4Eq); //               eql_v3.eq(int4_eq, int4_eq)
        eq!(Int4Eq, Jsonb<Int4Eq>); //        eql_v3.eq(int4_eq, jsonb)
        eq!(Jsonb<Int4Eq>, Int4Eq); //        eql_v3.eq(jsonb, int4_eq)
        neq!(Int4Eq, Int4Eq); //              eql_v3.neq(int4_eq, int4_eq)
        neq!(Int4Eq, Jsonb<Int4Eq>); //       eql_v3.neq(int4_eq, jsonb)
        neq!(Jsonb<Int4Eq>, Int4Eq); //       eql_v3.neq(jsonb, int4_eq)
    }

    mod int4_ord {
        use super::*;
        ord_term!(Int4Ord); //                eql_v3.ord_term(int4_ord) -> ore_block_u64_8_256
        eq!(Int4Ord, Int4Ord);
        eq!(Int4Ord, Jsonb<Int4Ord>);
        eq!(Jsonb<Int4Ord>, Int4Ord);
        neq!(Int4Ord, Int4Ord);
        neq!(Int4Ord, Jsonb<Int4Ord>);
        neq!(Jsonb<Int4Ord>, Int4Ord);
        lt!(Int4Ord, Int4Ord);
        lt!(Int4Ord, Jsonb<Int4Ord>);
        lt!(Jsonb<Int4Ord>, Int4Ord);
        lte!(Int4Ord, Int4Ord);
        lte!(Int4Ord, Jsonb<Int4Ord>);
        lte!(Jsonb<Int4Ord>, Int4Ord);
        gt!(Int4Ord, Int4Ord);
        gt!(Int4Ord, Jsonb<Int4Ord>);
        gt!(Jsonb<Int4Ord>, Int4Ord);
        gte!(Int4Ord, Int4Ord);
        gte!(Int4Ord, Jsonb<Int4Ord>);
        gte!(Jsonb<Int4Ord>, Int4Ord);
    }

    // Same surface as `int4_ord`, distinct SQL domain.
    mod int4_ord_ore {
        use super::*;
        ord_term!(Int4OrdOre);
        eq!(Int4OrdOre, Int4OrdOre);
        eq!(Int4OrdOre, Jsonb<Int4OrdOre>);
        eq!(Jsonb<Int4OrdOre>, Int4OrdOre);
        neq!(Int4OrdOre, Int4OrdOre);
        neq!(Int4OrdOre, Jsonb<Int4OrdOre>);
        neq!(Jsonb<Int4OrdOre>, Int4OrdOre);
        lt!(Int4OrdOre, Int4OrdOre);
        lt!(Int4OrdOre, Jsonb<Int4OrdOre>);
        lt!(Jsonb<Int4OrdOre>, Int4OrdOre);
        lte!(Int4OrdOre, Int4OrdOre);
        lte!(Int4OrdOre, Jsonb<Int4OrdOre>);
        lte!(Jsonb<Int4OrdOre>, Int4OrdOre);
        gt!(Int4OrdOre, Int4OrdOre);
        gt!(Int4OrdOre, Jsonb<Int4OrdOre>);
        gt!(Jsonb<Int4OrdOre>, Int4OrdOre);
        gte!(Int4OrdOre, Int4OrdOre);
        gte!(Int4OrdOre, Jsonb<Int4OrdOre>);
        gte!(Jsonb<Int4OrdOre>, Int4OrdOre);
    }
}
