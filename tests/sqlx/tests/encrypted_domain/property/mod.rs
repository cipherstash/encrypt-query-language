//! Property-based and edge-case tests for the eql_v3 encrypted scalar domains
//! (CIP-3141). Deliberately NOT under `scalars::` — the matrix-inventory gate
//! (`mise run test:matrix:inventory`) discovers scalar types from every
//! `scalars::<X>::` test-name prefix, so a `scalars::property::…` test would be
//! mis-read as a scalar type and break the catalog cross-check.

/// The embedded SQLx migration set (`tests/sqlx/migrations`) — the SAME one
/// `#[sqlx::test]` applies to its scratch DBs. Only the e2e suite needs it: it
/// connects to the base DB directly (its proptest case loop is sync and it
/// batch-encrypts via ZeroKMS), so it applies the migrations itself to reach the
/// migrated state the rest of the suite gets for free (see
/// `property::ensure_eql_installed`). The fixture suite is a `#[sqlx::test]` and
/// needs none of this. The macro embeds the files at compile time and resolves
/// `./migrations` against the `eql_tests` crate root (`tests/sqlx`); kept in the
/// test target, not the lib, so the lib never embeds the gitignored generated
/// `001_install_eql.sql`. Gated to the e2e feature so it is not dead code in the
/// default (shard) build.
#[cfg(feature = "proptest-e2e")]
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
