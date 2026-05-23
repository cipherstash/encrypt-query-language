//! Type-checked fixture generation framework.
//!
//! A fixture is one Rust file under `src/fixtures/` declaring a `FixtureSpec`.
//! `FixtureSpec::run()` generates the committed SQLx fixture script
//! `tests/sqlx/fixtures/<name>.sql`. See `docs/superpowers/specs/2026-05-22-fixture-plugin-mechanism-design.md`.

pub mod validation;

pub mod eql_plaintext;

pub use eql_plaintext::EqlPlaintext;

pub mod spec;

pub use spec::FixtureSpec;

pub mod driver;
