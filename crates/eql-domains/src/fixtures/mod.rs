//! The fixture/test layer of the catalog: the native-scalar vocabulary
//! (`ScalarKind` / `BoundedIntKind`), the `Fixture` value tag + `fixtures!`
//! builder, the per-type `TypeFixtures` records + `FIXTURES` table, and the
//! materialised `*_VALUES` slices. One-way dependency: this module references
//! catalog rows (`crate::INT4` …); the catalog never references this module.
//!
//! `#[macro_use]` order matters: `fixture` (which defines `fixtures!`) must be
//! declared before `record` (which invokes it), without `#[macro_export]`.

#[macro_use]
pub(crate) mod fixture;
pub(crate) mod kind;
pub(crate) mod record;
pub(crate) mod values;

pub use fixture::Fixture;
pub use kind::{BoundedIntKind, ScalarKind};
pub use record::{
    TypeFixtures, BOOL_FIXTURES, DATE_FIXTURES, FIXTURES, FLOAT4_FIXTURES, FLOAT8_FIXTURES,
    INT2_FIXTURES, INT4_FIXTURES, INT8_FIXTURES, NUMERIC_FIXTURES, TEXT_FIXTURES,
    TIMESTAMPTZ_FIXTURES,
};
pub use values::{INT2_VALUES, INT4_VALUES, INT8_VALUES, TEXT_VALUES};
