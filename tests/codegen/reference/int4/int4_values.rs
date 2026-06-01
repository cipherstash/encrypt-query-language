// REFERENCE: hand-reviewed parity baseline for tasks/codegen/ — see ../README.md
//! Fixture plaintext values for the int4 encrypted-domain family.
//!
//! Generated from tasks/codegen/types/int4.toml `[fixture] values` —
//! the single source of truth shared by the fixture generator
//! (`fixtures::eql_v2_int4`) and the matrix oracle
//! (`ScalarType::FIXTURE_VALUES`).

/// Distinct plaintext values present in the `eql_v2_int4` fixture.
pub const VALUES: &[i32] = &[
    i32::MIN,
    -100,
    -1,
    0,
    1,
    2,
    5,
    10,
    17,
    25,
    42,
    50,
    100,
    250,
    1000,
    9999,
    i32::MAX,
];
