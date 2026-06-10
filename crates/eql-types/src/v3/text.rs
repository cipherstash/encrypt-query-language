//! The `text` encrypted-domain family — the ordered shape of
//! [`crate::v3::int4`] plus a `_match` domain backed by the Bloom-filter
//! term (`@>`/`<@` containment for `LIKE`-style matching).

use crate::v3::eql_v3_domain;
use crate::v3::terms::{BloomFilter, Hmac256, OreBlockU64_8_256};

eql_v3_domain!(
    /// `eql_v3.text` — storage only; every operator is blocked.
    Text, domain = "text");

eql_v3_domain!(
/// `eql_v3.text_eq` — HMAC equality (`=`, `<>`).
TextEq, domain = "text_eq",
terms {
    /// HMAC-SHA-256 equality term.
    hm: Hmac256,
});

eql_v3_domain!(
/// `eql_v3.text_match` — Bloom-filter containment match.
TextMatch, domain = "text_match",
terms {
    /// Bloom-filter match term (signed smallint bit positions).
    bf: BloomFilter,
});

eql_v3_domain!(
/// `eql_v3.text_ord_ore` — full lexicographic comparison,
/// scheme-explicit name.
TextOrdOre, domain = "text_ord_ore",
terms {
    /// Block-ORE order term. Serves equality too.
    ob: OreBlockU64_8_256,
});

eql_v3_domain!(
/// `eql_v3.text_ord` — full lexicographic comparison
/// (`=` `<>` `<` `<=` `>` `>=`).
TextOrd, domain = "text_ord",
terms {
    /// Block-ORE order term. Serves equality too.
    ob: OreBlockU64_8_256,
});
