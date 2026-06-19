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

// The v3 jsonb (SteVec document) fixture — a hand-written `FixtureSpec`
// over `serde_json::Value`, generated through the same pipeline as the
// scalar `eql_v2_<T>` fixtures. Not a CATALOG scalar, so it is registered
// here directly rather than via `scalar_types!`.
pub mod v3_ste_vec;

// The scalar-shaped SteVec document fixture — a SteVec document carrying one
// int4 scalar at `$.field` per `eql_scalars::INT4_VALUES`. A SPLIT fixture
// (jsonb-document encryption input, int4 plaintext oracle), so it uses the
// `run_with_payloads` seam rather than `FixtureSpec::run`. Drives the
// jsonb-entry behaviour matrix (`JsonbEntryInt4`).
pub mod v3_doc_int4;

// The numeric scale-equivalence collision fixture (`1`, `1.0`, `2`). Not a
// CATALOG scalar — the catalog distinctness guard forbids the value-equal pair
// `1`/`1.0` — so it is hand-written and registered here directly (like the
// other `v3_` fixtures). Gives the `1 == 1.0` ORE collision an always-on
// (committed-fixture) home instead of a creds-gated runtime encryption.
pub mod v3_numeric_collision;

// Per-type "doubles" fixtures (each plaintext encrypted twice) for the
// cross-ciphertext-equality test. Non-catalog, like `v3_numeric_collision`.
pub mod eql_doubles;

// The per-type scalar fixture modules (`eql_v2_int4`, `eql_v2_int2`, …) are
// generated from the harness list in `scalar_types.rs`. Each expands to
// `pub mod eql_v2_<T> { … scalar_fixture! … }`, reading its plaintext values
// directly from the catalog (`eql_scalars::<TOKEN>_VALUES`).
crate::scalar_types!(fixture_modules);
