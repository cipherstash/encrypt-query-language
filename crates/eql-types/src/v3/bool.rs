//! The `bool` encrypted-domain family — the storage-only / encryption-only
//! scalar.
//!
//! | Rust type  | SQL domain     | Required keys | Operators           |
//! |------------|----------------|---------------|---------------------|
//! | [`Bool`]   | `eql_v3.bool`  | `v` `i` `c`   | none (storage only) |
//!
//! `bool` is the only **storage-only** scalar: it has no `_eq`/`_ord` domain
//! and carries no index term, so the value is encrypted at rest and decrypted
//! by the proxy but is never searchable server-side. A two-value column has so
//! little cardinality that any searchable index (even HMAC equality) would
//! trivially leak the plaintext distribution. The payload is `{v,i,c}` only —
//! no `hm`/`ob`/`bf` — and every operator on the domain is blocked.

use schemars::{schema::RootSchema, schema_for};

use crate::v3::terms::Ciphertext;
use crate::v3::DomainType;
use crate::{Identifier, SchemaVersion};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use ts_rs::TS;

/// `eql_v3.bool` — storage only / encryption-only; every operator is blocked.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct Bool {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
}

impl DomainType for Bool {
    fn sql_domain_static() -> &'static str {
        "eql_v3.bool"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(Bool)
    }
}
