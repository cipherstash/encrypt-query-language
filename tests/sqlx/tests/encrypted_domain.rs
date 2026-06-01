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
