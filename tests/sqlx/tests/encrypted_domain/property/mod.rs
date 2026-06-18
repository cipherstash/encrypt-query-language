//! Property-based and edge-case tests for the eql_v3 encrypted scalar domains
//! (CIP-3141). Deliberately NOT under `scalars::` — the matrix-inventory gate
//! (`mise run test:matrix:inventory`) discovers scalar types from every
//! `scalars::<X>::` test-name prefix, so a `scalars::property::…` test would be
//! mis-read as a scalar type and break the catalog cross-check.

/// The EQL installer (`migrations/001_install_eql.sql`, the full release),
/// embedded at compile time so the property suites can install the `eql_v3`
/// surface into their base DB on demand (see `property::ensure_eql_installed`).
/// Same embed-into-the-archive rationale as the per-type fixture corpus in
/// `fixture_oracle.rs`: the file is produced by `test:sqlx:prep` before the
/// nextest archive is built, and the CI shards run from that archive without a
/// checkout of the gitignored generated SQL. The path resolves against the
/// `eql_tests` crate root (`tests/sqlx`).
pub(crate) const EQL_INSTALL_SQL: &str = include_str!(concat!(
    env!("CARGO_MANIFEST_DIR"),
    "/migrations/001_install_eql.sql"
));

// NULL / blocker / CHECK-constraint unit tests.
mod edge_cases;
// fixture suite: oracle over the committed fixture corpus (real ciphertext).
mod fixture_oracle;
// e2e suite: oracle over freshly generated + batch-encrypted values.
#[cfg(feature = "proptest-e2e")]
mod e2e_oracle;
