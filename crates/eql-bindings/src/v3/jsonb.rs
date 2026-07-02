//! The `jsonb` (SteVec) encrypted-JSONB payload types — HAND-WRITTEN.
//!
//! Unlike the scalar families, the SteVec struct bodies (fields, `#[serde(flatten)]`,
//! the `Option<bool>` array marker, per-struct serde strictness) are not derivable
//! from `eql-domains::CATALOG`, so they live here by hand — symmetric with the
//! hand-written SQL under `src/v3/jsonb/`. The generated `inventory.rs` still lists
//! these three domains (in CATALOG order) via its `Shape` branch. See the SteVec
//! caveat in `mod.rs` for why the entry/query structs are necessarily lax.

use schemars::{schema_for, JsonSchema, Schema};
use serde::{Deserialize, Serialize};
use ts_rs::TS;

use crate::v3::terms::{Ciphertext, Hmac256, OreCllw, Selector};
use crate::v3::DomainType;
use crate::{Identifier, SchemaVersion};

/// `eql_v3.json` — a SteVec encrypted-JSONB document (`{v, i, sv:[entry]}`, no
/// root ciphertext). Strict.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct SteVecDocument {
    pub v: SchemaVersion,
    pub i: Identifier,
    pub sv: Vec<SteVecEntry>,
}

/// `eql_v3.ste_vec_entry` — one sv element (returned by `->`). Carries a selector
/// `s`, ciphertext `c`, optional array-membership marker `a`, and exactly one of
/// `hm` XOR `oc`. LAX (flatten precludes `deny_unknown_fields`): tolerates the
/// root `i`/`v` merged in by `->`. XOR of the term is enforced by the SQL CHECK.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct SteVecEntry {
    pub s: Selector,
    pub c: Ciphertext,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub a: Option<bool>,
    #[serde(flatten)]
    pub term: SteVecTerm,
}

/// `eql_v3.ste_vec_query` — a containment needle (`{sv:[query-entry]}`). Strict.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct SteVecQuery {
    pub sv: Vec<SteVecQueryEntry>,
}

/// One element of a SteVec containment needle: a selector plus one term, and
/// (per the SQL CHECK) no ciphertext. LAX for the same flatten reason as
/// `SteVecEntry`; the "no `c`" contract is enforced by `is_valid_ste_vec_query_payload`.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct SteVecQueryEntry {
    pub s: Selector,
    #[serde(flatten)]
    pub term: SteVecTerm,
}

/// The per-entry deterministic term: exactly one of `hm` (HMAC equality) or `oc`
/// (CLLW-ORE ordering). Untagged — a document mixes both across its `sv` array.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(untagged)]
pub enum SteVecTerm {
    Hmac { hm: Hmac256 },
    OreCllw { oc: OreCllw },
}

macro_rules! ste_vec_domain_type {
    ($ty:ident, $sql:literal) => {
        impl DomainType for $ty {
            fn sql_domain_static() -> &'static str {
                $sql
            }
            fn sql_domain(&self) -> &'static str {
                Self::sql_domain_static()
            }
            fn schema(&self) -> Schema {
                schema_for!($ty)
            }
        }
    };
}

ste_vec_domain_type!(SteVecDocument, "eql_v3.json");
ste_vec_domain_type!(SteVecEntry, "eql_v3.ste_vec_entry");
ste_vec_domain_type!(SteVecQuery, "eql_v3.ste_vec_query");
