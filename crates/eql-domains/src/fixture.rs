//! Inherent impls for [`Fixture`] — resolving a fixture to its integer value
//! (`numeric_value`). Definition lives in `lib.rs`.

use crate::{Fixture, ScalarKind};

impl Fixture {
    /// The integer value for this fixture (`Min`/`Max` -> kind bounds, `Zero` ->
    /// 0, `Int(n)` -> n), or `None` for the string-backed kinds. Does not
    /// range-check; `every_fixture_value_is_within_kind_bounds` guards the bounds.
    ///
    /// `const fn` so the `int_values!` materialiser can resolve a whole fixture
    /// list into a typed `&'static` array at compile time.
    pub const fn numeric_value(self, kind: ScalarKind) -> Option<i128> {
        match self {
            // `?` is not allowed in `const fn`, so match `as_bounded_int()`
            // explicitly. A pivot on a non-integer kind resolves to `None`; the
            // `pivot_sentinels_only_appear_with_integer_kinds` catalog test
            // guarantees that combination never reaches a real `CATALOG` row.
            Fixture::Min => match kind.as_bounded_int() {
                Some(k) => Some(k.min_value()),
                None => None,
            },
            Fixture::Max => match kind.as_bounded_int() {
                Some(k) => Some(k.max_value()),
                None => None,
            },
            Fixture::Zero => match kind.as_bounded_int() {
                Some(_) => Some(0),
                None => None,
            },
            // Gate the literal on the integer kinds too, mirroring the sentinels
            // above: a hand-built `Int(n)` on a non-integer kind resolves to
            // `None` rather than fabricating a number for a `Text`/`Date`/`Bool`
            // kind that has no integer projection.
            Fixture::Int(n) => match kind.as_bounded_int() {
                Some(_) => Some(n),
                None => None,
            },
            Fixture::Numeric(_)
            | Fixture::Text(_)
            | Fixture::Jsonb(_)
            | Fixture::Date(_)
            | Fixture::Timestamptz(_)
            | Fixture::Float(_)
            | Fixture::Bool(_) => None,
        }
    }
}
