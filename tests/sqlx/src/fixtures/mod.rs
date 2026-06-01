//! Type-checked fixture generation framework.
//!
//! A fixture is one Rust file under `src/fixtures/` declaring a `FixtureSpec`.
//! `FixtureSpec::run()` generates the SQLx fixture script
//! `tests/sqlx/fixtures/<name>.sql` (gitignored — regenerated on every
//! `mise run test:sqlx`).

pub mod validation;

pub mod eql_plaintext;

pub use eql_plaintext::EqlPlaintext;

pub mod index_kind;

pub use index_kind::IndexKind;

pub mod spec;

pub use spec::FixtureSpec;

#[macro_use]
pub mod scalar_fixture;

pub mod cipherstash;

pub mod driver;

/// Generated from tasks/codegen/types/int4.toml `[fixture] values`.
/// Committed and verified by CI; never hand-edit (`mise run codegen:domain int4`).
pub mod int4_values;

pub mod eql_v2_int4;

/// Generated from tasks/codegen/types/int2.toml `[fixture] values`.
/// Committed and verified by CI; never hand-edit (`mise run codegen:domain int2`).
pub mod int2_values;

pub mod eql_v2_int2;
