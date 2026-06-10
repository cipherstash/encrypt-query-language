//! The `date` encrypted-domain family — an ordered, non-integer scalar.
//! Same four-domain ordered shape as [`crate::v3::int4`] (ORE compares
//! ciphertext, so dates order like integers); see that module for the
//! capability table.

use crate::v3::eql_v3_domain;
use crate::v3::terms::{Hmac256, OreBlockU64_8_256};

eql_v3_domain!(
    /// `eql_v3.date` — storage only; every operator is blocked.
    Date, domain = "date");

eql_v3_domain!(
/// `eql_v3.date_eq` — HMAC equality (`=`, `<>`).
DateEq, domain = "date_eq",
terms {
    /// HMAC-SHA-256 equality term.
    hm: Hmac256,
});

eql_v3_domain!(
/// `eql_v3.date_ord_ore` — full comparison, scheme-explicit name.
DateOrdOre, domain = "date_ord_ore",
terms {
    /// Block-ORE order term. Serves equality too.
    ob: OreBlockU64_8_256,
});

eql_v3_domain!(
/// `eql_v3.date_ord` — full comparison (`=` `<>` `<` `<=` `>` `>=`).
DateOrd, domain = "date_ord",
terms {
    /// Block-ORE order term. Serves equality too.
    ob: OreBlockU64_8_256,
});
