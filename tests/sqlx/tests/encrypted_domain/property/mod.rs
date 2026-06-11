//! Property-based and edge-case tests for the eql_v3 encrypted scalar domains
//! (CIP-3141). Deliberately NOT under `scalars::` — the matrix-inventory gate
//! (`mise run test:matrix:inventory`) discovers scalar types from every
//! `scalars::<X>::` test-name prefix, so a `scalars::property::…` test would be
//! mis-read as a scalar type and break the catalog cross-check.

// NULL / blocker / CHECK-constraint unit tests.
mod edge_cases;
// Tier A: oracle over the live-encrypted fixture corpus.
mod fixture_oracle;
// Tier B: oracle over freshly generated + batch-encrypted values.
#[cfg(feature = "proptest-live")]
mod live_oracle;
