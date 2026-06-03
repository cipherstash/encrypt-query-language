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

// The per-type scalar fixture modules (`eql_v2_int4`, `eql_v2_int2`, …) are
// generated from the harness list in `scalar_types.rs`. Each expands to
// `pub mod eql_v2_<T> { … scalar_fixture! … }`, reading its plaintext values
// directly from the catalog (`eql_scalars::<TOKEN>_VALUES`).
crate::scalar_types!(fixture_modules);
