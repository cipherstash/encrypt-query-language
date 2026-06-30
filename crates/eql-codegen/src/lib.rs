//! Scalar encrypted-domain SQL generator. Renders the `eql-domains` catalog to
//! the committed SQL surface under `src/v3/scalars/<token>/`, drift-gated
//! byte-for-byte by `mise run codegen:parity` (regenerate in place +
//! `git diff --exit-code`, mirroring `types:check` for the Rust bindings). The
//! plaintext fixture lists the SQLx matrix consumes live in the catalog itself
//! (`eql_domains::INT4_VALUES` / `INT2_VALUES`), not in a generated file.

use std::path::PathBuf;

pub mod bindings;
pub mod consts;
pub mod context;
pub mod dump;
pub mod generate;
pub mod operator_surface;
pub mod writer;

/// The repository root, derived from this crate's manifest dir (the generator
/// writes the real `src/v3/scalars/` tree relative to it). `CARGO_MANIFEST_DIR`
/// is `crates/eql-codegen`, so the repo root is two parents up. Shared by the
/// binary, the in-crate tests, and the `tests/parity.rs` gate.
pub fn repo_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .unwrap()
        .parent()
        .unwrap()
        .to_path_buf()
}
