//! The `int2` encrypted-domain family. Same four-domain ordered shape as
//! [`crate::v3::int4`] — see that module for the capability table.

use crate::v3::eql_v3_domain;
use crate::v3::terms::{Hmac256, OreBlockU64_8_256};

eql_v3_domain!(
    /// `eql_v3.int2` — storage only; every operator is blocked.
    Int2, domain = "int2");

eql_v3_domain!(
/// `eql_v3.int2_eq` — HMAC equality (`=`, `<>`).
Int2Eq, domain = "int2_eq",
terms {
    /// HMAC-SHA-256 equality term.
    hm: Hmac256,
});

eql_v3_domain!(
/// `eql_v3.int2_ord_ore` — full comparison, scheme-explicit name.
Int2OrdOre, domain = "int2_ord_ore",
terms {
    /// Block-ORE order term. Serves equality too.
    ob: OreBlockU64_8_256,
});

eql_v3_domain!(
/// `eql_v3.int2_ord` — full comparison (`=` `<>` `<` `<=` `>` `>=`).
Int2Ord, domain = "int2_ord",
terms {
    /// Block-ORE order term. Serves equality too.
    ob: OreBlockU64_8_256,
});
