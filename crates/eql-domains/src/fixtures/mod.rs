//! The fixture/test layer of the catalog: the native-scalar vocabulary
//! (`ScalarKind` / `BoundedIntKind`), the `Fixture` value tag + `fixtures!`
//! builder, the per-type `TypeFixtures` records + `FIXTURES` table, and the
//! materialised `*_VALUES` slices. One-way dependency: this module references
//! catalog rows (`crate::INTEGER` …); the catalog never references this module.
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
    TypeFixtures, BOOLEAN_FIXTURES, DATE_FIXTURES, FIXTURES, REAL_FIXTURES, DOUBLE_FIXTURES,
    SMALLINT_FIXTURES, INTEGER_FIXTURES, BIGINT_FIXTURES, JSONB_FIXTURES, NUMERIC_FIXTURES, TEXT_FIXTURES,
    TIMESTAMP_FIXTURES,
};
pub use values::{SMALLINT_VALUES, INTEGER_VALUES, BIGINT_VALUES, TEXT_VALUES};
