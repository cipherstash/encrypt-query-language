//! Property-based and edge-case tests for the eql_v3 encrypted scalar domains
//! (CIP-3141). Deliberately NOT under `scalars::` — the matrix-inventory gate
//! (`mise run test:matrix:inventory`) discovers scalar types from every
//! `scalars::<X>::` test-name prefix, so a `scalars::property::…` test would be
//! mis-read as a scalar type and break the catalog cross-check.

/// The embedded SQLx migration set (`tests/sqlx/migrations`) — the SAME one
/// `#[sqlx::test]` applies to its scratch DBs. The property suites connect to
/// the base DB directly (their proptest case loop is sync and can't take
/// `#[sqlx::test]`'s injected pool), so they apply this themselves to reach the
/// migrated state the rest of the suite gets for free (see
/// `property::ensure_eql_installed`). The macro embeds the files at compile
/// time and resolves `./migrations` against the `eql_tests` crate root
/// (`tests/sqlx`); kept in the test target, not the lib, so the lib never
/// embeds the gitignored generated `001_install_eql.sql`.
pub(crate) fn migrator() -> sqlx::migrate::Migrator {
    sqlx::migrate!("./migrations")
}

// NULL / blocker / CHECK-constraint unit tests.
mod edge_cases;
// fixture suite: oracle over the committed fixture corpus (real ciphertext).
mod fixture_oracle;
// e2e suite: oracle over freshly generated + batch-encrypted values.
#[cfg(feature = "proptest-e2e")]
mod e2e_oracle;
