//! The `int4` encrypted-domain family — the reference scalar.
//!
//! | Rust type      | SQL domain             | Required keys | Operators                  |
//! |----------------|------------------------|---------------|----------------------------|
//! | [`Int4`]       | `eql_v3.int4`          | `v` `i` `c`        | none (storage only)        |
//! | [`Int4Eq`]     | `eql_v3.int4_eq`       | `v` `i` `c` `hm`   | `=` `<>`                   |
//! | [`Int4OrdOre`] | `eql_v3.int4_ord_ore`  | `v` `i` `c` `ob`   | `=` `<>` `<` `<=` `>` `>=` |
//! | [`Int4Ord`]    | `eql_v3.int4_ord`      | `v` `i` `c` `ob`   | `=` `<>` `<` `<=` `>` `>=` |

use crate::v3::eql_v3_domain;
use crate::v3::terms::{Hmac256, OreBlockU64_8_256};

eql_v3_domain!(
    /// `eql_v3.int4` — storage only; every operator is blocked.
    Int4, domain = "int4");

eql_v3_domain!(
/// `eql_v3.int4_eq` — HMAC equality (`=`, `<>`).
Int4Eq, domain = "int4_eq",
terms {
    /// HMAC-SHA-256 equality term.
    hm: Hmac256,
});

eql_v3_domain!(
/// `eql_v3.int4_ord_ore` — full comparison (`=` `<>` `<` `<=` `>` `>=`),
/// scheme-explicit name. Same shape as [`Int4Ord`], distinct SQL domain.
Int4OrdOre, domain = "int4_ord_ore",
terms {
    /// Block-ORE order term. Serves equality too — ORE over a
    /// full-domain `int4` is lossless, so no separate `hm` is carried.
    ob: OreBlockU64_8_256,
});

eql_v3_domain!(
/// `eql_v3.int4_ord` — full comparison (`=` `<>` `<` `<=` `>` `>=`).
Int4Ord, domain = "int4_ord",
terms {
    /// Block-ORE order term. Serves equality too.
    ob: OreBlockU64_8_256,
});
