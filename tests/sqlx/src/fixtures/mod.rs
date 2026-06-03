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

/// Scalar fixtures read their plaintext value lists directly from the catalog
/// (`eql_scalars::INT4_VALUES` / `INT2_VALUES`) — see `scalar_fixture!`. There
/// is no generated `<T>_values.rs` module any more.
pub mod eql_v2_int4;

pub mod eql_v2_int2;
