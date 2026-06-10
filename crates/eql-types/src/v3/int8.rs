//! The `int8` encrypted-domain family. Same four-domain ordered shape as
//! [`crate::v3::int4`] — see that module for the capability table.

use crate::v3::eql_v3_domain;
use crate::v3::terms::{Hmac256, OreBlockU64_8_256};

eql_v3_domain!(
    /// `eql_v3.int8` — storage only; every operator is blocked.
    Int8, domain = "int8");

eql_v3_domain!(
/// `eql_v3.int8_eq` — HMAC equality (`=`, `<>`).
Int8Eq, domain = "int8_eq",
terms {
    /// HMAC-SHA-256 equality term.
    hm: Hmac256,
});

eql_v3_domain!(
/// `eql_v3.int8_ord_ore` — full comparison, scheme-explicit name.
Int8OrdOre, domain = "int8_ord_ore",
terms {
    /// Block-ORE order term. Serves equality too.
    ob: OreBlockU64_8_256,
});

eql_v3_domain!(
/// `eql_v3.int8_ord` — full comparison (`=` `<>` `<` `<=` `>` `>=`).
Int8Ord, domain = "int8_ord",
terms {
    /// Block-ORE order term. Serves equality too.
    ob: OreBlockU64_8_256,
});
