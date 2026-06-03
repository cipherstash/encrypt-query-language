//! Scalar encrypted-domain SQL generator. Renders the `eql-scalars` catalog to
//! the gitignored SQL surface, validated byte-for-byte against the
//! `tests/codegen/reference/int4` golden (modulo the one `-- REFERENCE:`
//! provenance line each reference file carries). The plaintext fixture lists
//! the SQLx matrix consumes live in the catalog itself
//! (`eql_scalars::INT4_VALUES` / `INT2_VALUES`), not in a generated file.

pub mod consts;
pub mod context;
pub mod generate;
pub mod operator_surface;
pub mod writer;
