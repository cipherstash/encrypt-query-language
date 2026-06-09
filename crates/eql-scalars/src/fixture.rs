//! Inherent impls for [`Fixture`] — resolving a fixture to its integer value
//! (`numeric_value`) and rendering it as a Rust source literal
//! (`render_literal`). Definition lives in `lib.rs`.

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
            Fixture::Int(n) => Some(n),
            Fixture::Numeric(_)
            | Fixture::Text(_)
            | Fixture::Jsonb(_)
            | Fixture::Date(_)
            | Fixture::Timestamptz(_) => None,
        }
    }

    /// Render as a Rust source literal: sentinels -> named constant, `Int` -> the
    /// number, string kinds -> a `Debug`-quoted (Rust-escaped, not SQL) literal.
    pub fn render_literal(self, kind: ScalarKind) -> String {
        const PIVOT_MSG: &str = "Min/Max/Zero fixtures require an integer kind";
        match self {
            Fixture::Min => kind
                .as_bounded_int()
                .expect(PIVOT_MSG)
                .min_symbol()
                .to_string(),
            Fixture::Max => kind
                .as_bounded_int()
                .expect(PIVOT_MSG)
                .max_symbol()
                .to_string(),
            Fixture::Zero => kind
                .as_bounded_int()
                .expect(PIVOT_MSG)
                .zero_symbol()
                .to_string(),
            Fixture::Int(n) => n.to_string(),
            Fixture::Numeric(s)
            | Fixture::Text(s)
            | Fixture::Jsonb(s)
            | Fixture::Date(s)
            | Fixture::Timestamptz(s) => {
                format!("{s:?}")
            }
        }
    }
}
