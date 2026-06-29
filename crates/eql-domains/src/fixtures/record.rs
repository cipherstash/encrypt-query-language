//! The fixture-layer record: a `TypeFixtures` per scalar type, pairing a
//! structural catalog row (`&DomainFamily`) with its `ScalarKind` and its
//! plaintext fixture `values`. This is where `kind`/`fixtures` live now that
//! they are off `DomainFamily` — a fixture/test concern, not structural catalog
//! data. The `FIXTURES` table mirrors `CATALOG` order; the `const _` parity
//! block at the bottom of this file replaces the struct's old compiler-enforced
//! 1:1 — a build-time `assert!` over `CATALOG`/`FIXTURES`, not a runtime test.

use super::fixture::Fixture;
use super::kind::ScalarKind;
use crate::DomainFamily;

/// One scalar type's fixture-layer data: the structural catalog row it belongs
/// to (`family`), the native scalar it maps onto (`kind`), and its distinct
/// plaintext fixture `values`. `family` is a reference to the same
/// `DomainFamily` const that `CATALOG` carries, so `family.name` is the join key
/// back to the catalog.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct TypeFixtures {
    pub family: &'static DomainFamily,
    pub kind: ScalarKind,
    pub values: &'static [Fixture],
}

/// int4 fixtures. `N(..)` literals are range-checked against `i32` at compile
/// time by `fixtures!`.
pub const INT4_FIXTURES: TypeFixtures = TypeFixtures {
    family: &crate::INT4,
    kind: ScalarKind::I32,
    values: fixtures!(int i32;
        Min, N(-100), N(-1), Zero, N(1), N(2), N(5), N(10), N(17), N(25),
        N(42), N(50), N(100), N(250), N(1000), N(9999), Max),
};

/// int2 fixtures (`i16`-range-checked).
pub const INT2_FIXTURES: TypeFixtures = TypeFixtures {
    family: &crate::INT2,
    kind: ScalarKind::I16,
    values: fixtures!(int i16;
        Min, N(-30000), N(-100), N(-1), Zero, N(1), N(2), N(5), N(10), N(17),
        N(25), N(42), N(50), N(100), N(250), N(1000), N(9999), N(30000), Max),
};

/// int8 fixtures (`i64`-range-checked) — the int4 set plus two values beyond the
/// i32 range (`±5_000_000_000`) so the matrix exercises the full 64-bit width.
pub const INT8_FIXTURES: TypeFixtures = TypeFixtures {
    family: &crate::INT8,
    kind: ScalarKind::I64,
    values: fixtures!(int i64;
        Min, N(-5000000000), N(-100), N(-1), Zero, N(1), N(2), N(5), N(10), N(17),
        N(25), N(42), N(50), N(100), N(250), N(1000), N(9999), N(5000000000), Max),
};

/// date fixtures — ISO-8601 strings; the three temporal pivots
/// (`1900-01-01`, `1970-01-01`, `2099-12-31`) MUST be present verbatim.
pub const DATE_FIXTURES: TypeFixtures = TypeFixtures {
    family: &crate::DATE,
    kind: ScalarKind::Date,
    values: fixtures!(date;
        "1900-01-01", "1950-07-15", "1969-12-31", "1970-01-01", "1970-01-02",
        "1980-02-29", "1991-11-09", "1999-12-31", "2000-01-01", "2004-02-29",
        "2012-06-30", "2016-03-15", "2020-10-21", "2024-02-29", "2038-01-19",
        "2099-12-31"),
};

/// timestamptz fixtures — RFC3339 UTC strings; the three temporal pivots
/// (`1900-01-01T00:00:00Z`, `1970-01-01T00:00:00Z`, `2099-12-31T23:59:59Z`)
/// MUST be present verbatim.
pub const TIMESTAMPTZ_FIXTURES: TypeFixtures = TypeFixtures {
    family: &crate::TIMESTAMPTZ,
    kind: ScalarKind::Timestamptz,
    values: fixtures!(timestamptz;
        "1900-01-01T00:00:00Z", "1950-07-15T06:30:00Z", "1969-12-31T23:59:59Z",
        "1970-01-01T00:00:00Z", "1970-01-01T00:00:01Z", "1985-04-12T23:20:50Z",
        "1999-12-31T23:59:59Z", "2000-01-01T00:00:00Z", "2004-02-29T12:00:00Z",
        "2012-06-30T11:59:59Z", "2016-03-15T08:15:30Z", "2020-10-21T14:45:00Z",
        "2024-02-29T17:30:45Z", "2038-01-19T03:14:07Z", "2099-12-31T23:59:59Z"),
};

/// numeric fixtures — distinct by `Decimal` value, mirroring `ore-rs`'s order
/// vectors; includes 0 and the min/max pivots (`±1000000000000`).
pub const NUMERIC_FIXTURES: TypeFixtures = TypeFixtures {
    family: &crate::NUMERIC,
    kind: ScalarKind::Numeric,
    values: fixtures!(numeric;
        "-1000000000000", "-1000000", "-1.001", "-1", "-0.5", "-0.001",
        "0", "0.001", "0.5", "0.999999999", "1", "1.001", "1000000", "1000000000000"),
};

/// text fixtures — lexicographic spread (`aard` min, `frank` mid, `zzzz` max
/// pivots, present verbatim), a known substring pair, and the G3-4b divergence
/// pair (`qabcqbcaqcabqabd` / `abcabd`). The empty string is deliberately absent
/// (issue #262).
pub const TEXT_FIXTURES: TypeFixtures = TypeFixtures {
    family: &crate::TEXT,
    kind: ScalarKind::Text,
    values: fixtures!(text;
        "aard", "aardvark", "alice", "bob", "carol",
        "dave", "erin", "frank", "mallory", "trent", "zzzz",
        "qabcqbcaqcabqabd", "abcabd"),
};

/// bool fixtures — both values. Storage-only: encrypted (ciphertext only), never
/// a comparison pivot.
pub const BOOL_FIXTURES: TypeFixtures = TypeFixtures {
    family: &crate::BOOL,
    kind: ScalarKind::Bool,
    values: fixtures!(bool; false, true),
};

/// float4 fixtures — IEEE-754 strings, every value dyadic (f32-exact); pivots
/// `-inf` / `0` / `inf` present verbatim. NaN and `-0.0` excluded.
pub const FLOAT4_FIXTURES: TypeFixtures = TypeFixtures {
    family: &crate::FLOAT4,
    kind: ScalarKind::F32,
    values: fixtures!(float;
        "-inf", "-1024", "-2.25", "-1", "-0.5", "-0.25",
        "0", "0.25", "0.5", "1", "2.25", "1024", "inf"),
};

/// float8 fixtures — IEEE-754 strings; pivots `-inf` / `0` / `inf` present
/// verbatim. NaN and `-0.0` excluded.
pub const FLOAT8_FIXTURES: TypeFixtures = TypeFixtures {
    family: &crate::FLOAT8,
    kind: ScalarKind::F64,
    values: fixtures!(float;
        "-inf", "-1e300", "-1000000", "-1.5", "-1", "-0.001",
        "0", "0.001", "1", "1.5", "1000000", "1e300", "inf"),
};

/// The fixture table — one record per scalar type, in `CATALOG` order. The
/// fixture-layer mirror of `CATALOG`; the `const _` parity block below pins the
/// parity at build time.
pub const FIXTURES: &[TypeFixtures] = &[
    INT4_FIXTURES,
    INT2_FIXTURES,
    INT8_FIXTURES,
    DATE_FIXTURES,
    TIMESTAMPTZ_FIXTURES,
    NUMERIC_FIXTURES,
    TEXT_FIXTURES,
    BOOL_FIXTURES,
    FLOAT4_FIXTURES,
    FLOAT8_FIXTURES,
];

/// Compile-time `&str` equality, usable in `const` context. `str::eq` /
/// `PartialEq` are not `const fn` on stable, so the parity block below needs its
/// own byte-wise comparison.
const fn str_eq(a: &str, b: &str) -> bool {
    let (a, b) = (a.as_bytes(), b.as_bytes());
    if a.len() != b.len() {
        return false;
    }
    let mut i = 0;
    while i < a.len() {
        if a[i] != b[i] {
            return false;
        }
        i += 1;
    }
    true
}

/// Compile-time parity guard: `FIXTURES` must mirror `CATALOG` exactly, in
/// order. This is the build-time invariant that REPLACES `DomainFamily`'s old
/// compiler-enforced `kind`/`fixtures` fields — every catalog row has exactly
/// one fixture record and vice-versa, same order. As a `const` item it is
/// const-evaluated on every `cargo build`: a missing, extra, or misaligned
/// `TypeFixtures` fails the build with `error[E0080]: evaluation panicked`
/// carrying the message below — it cannot be `#[cfg]`-gated away or skipped by a
/// test filter. It proves NAME + ORDERING coverage only; fixture-VALUE
/// correctness is gated by the in-crate value/invariant tests, not here.
const _: () = {
    assert!(
        FIXTURES.len() == crate::CATALOG.len(),
        "every CATALOG family needs exactly one TypeFixtures (FIXTURES.len() != CATALOG.len())"
    );
    let mut i = 0;
    while i < crate::CATALOG.len() {
        assert!(
            str_eq(crate::CATALOG[i].name, FIXTURES[i].family.name),
            "FIXTURES must mirror CATALOG in order: name mismatch at this index"
        );
        i += 1;
    }
};
