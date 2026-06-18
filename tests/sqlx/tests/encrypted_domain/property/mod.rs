//! Property-based and edge-case tests for the eql_v3 encrypted scalar domains
//! (CIP-3141). Deliberately NOT under `scalars::` — the matrix-inventory gate
//! (`mise run test:matrix:inventory`) discovers scalar types from every
//! `scalars::<X>::` test-name prefix, so a `scalars::property::…` test would be
//! mis-read as a scalar type and break the catalog cross-check.

// NULL / blocker / CHECK-constraint unit tests.
mod edge_cases;
// fixture suite: oracle over the committed fixture corpus (real ciphertext).
mod fixture_oracle;
// e2e suite: oracle over freshly generated + batch-encrypted values.
#[cfg(feature = "proptest-e2e")]
mod e2e_oracle;
