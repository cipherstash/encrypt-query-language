//! Umbrella integration-test binary for the encrypted-domain type family.
//!
//! Cargo's default discovery picks this file up as a test binary; the
//! module tree under `encrypted_domain/` is pulled in via the `#[path]`
//! attributes below. Legacy tests under `tests/sqlx/tests/*.rs` continue
//! to compile as their own separate binaries.

#[path = "encrypted_domain/family/mod.rs"]
mod family;

#[path = "encrypted_domain/scalars/mod.rs"]
mod scalars;

// Text-specific behavioural suites (literal-payload smoke + fixture-backed
// match-containment). Deliberately NOT under `scalars::` — the matrix-inventory
// gate treats every `scalars::<X>::` prefix as a scalar type, so these would be
// mis-discovered as types `text_smoke` / `text_match`.
#[path = "encrypted_domain/text/text_smoke.rs"]
mod text_smoke;

#[path = "encrypted_domain/text/text_match.rs"]
mod text_match;

// Signed-only sign-boundary suite (`int`, `date`). Like the text suites it
// lives outside `scalars::` so the matrix-inventory snapshot (which pins the
// uniform per-type set) does not see the signed-only delta.
#[path = "encrypted_domain/signed.rs"]
mod signed;

// SteVec jsonb-entry behaviour matrix (the reduced `jsonb_entry_matrix!`).
// Deliberately NOT under `scalars::` — `JsonbEntryInt4` is not a catalog scalar,
// so its names live under `jsonb_entry::…` and are pinned by the separate
// `test:matrix:inventory:jsonb_entry` task, not the scalar inventory.
#[path = "encrypted_domain/jsonb_entry.rs"]
mod jsonb_entry;

// Property-based + edge-case tests (CIP-3141). Three tiers under `property::`,
// kept outside `scalars::` so the matrix-inventory gate does not mis-read them
// as scalar types. See `encrypted_domain/property/mod.rs`.
#[path = "encrypted_domain/property/mod.rs"]
mod property;
