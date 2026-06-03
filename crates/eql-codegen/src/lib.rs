//! Scalar encrypted-domain SQL generator. Renders the `eql-scalars` catalog to
//! the gitignored SQL surface and the committed `<T>_values.rs` consts. The SQL
//! surface is validated against the `tests/codegen/reference/int4` golden under
//! line-normalized comparison; `<T>_values.rs` is validated byte-exact.

pub mod consts;
pub mod context;
pub mod generate;
pub mod operator_surface;
pub mod templates;
pub mod writer;
