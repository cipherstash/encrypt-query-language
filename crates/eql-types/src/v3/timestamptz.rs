//! The `timestamptz` encrypted-domain family — **equality-only** (storage +
//! `_eq`). There is no ordered domain: cipherstash encrypts timestamps at
//! native 12-block ORE width, but EQL's only ORE comparator is hardcoded to
//! 8 blocks, so an ordered timestamptz domain would silently mis-order.
//! Ordering arrives with a future wide-ORE term (see `eql-scalars`).

use crate::v3::eql_v3_domain;
use crate::v3::terms::Hmac256;

eql_v3_domain!(
    /// `eql_v3.timestamptz` — storage only; every operator is blocked.
    Timestamptz, domain = "timestamptz");

eql_v3_domain!(
/// `eql_v3.timestamptz_eq` — HMAC equality (`=`, `<>`).
TimestamptzEq, domain = "timestamptz_eq",
terms {
    /// HMAC-SHA-256 equality term.
    hm: Hmac256,
});
