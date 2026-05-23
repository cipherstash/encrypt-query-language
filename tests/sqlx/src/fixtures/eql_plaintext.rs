//! Maps a Rust plaintext type `T` to its EQL search-config cast and the SQL
//! type of the `plaintext` column.
//!
//! `CAST` is the `cast_as` argument to `eql_v2.add_search_config`;
//! `PLAINTEXT_SQL_TYPE` is the SQL type the `plaintext` oracle column is
//! declared with. Deriving both from `T` means a fixture author never
//! hand-writes them, and a future non-`i32` fixture needs no edits to the
//! framework schema code. #224 ships the `i32` impl only; further impls land
//! with the fixtures that introduce them.

/// A Rust type usable as a fixture `plaintext` value, carrying its EQL cast
/// and the SQL type of the `plaintext` column.
pub trait EqlPlaintext {
    /// The `cast_as` argument for `add_search_config` (e.g. `"int"`).
    /// Must be a member of `validation::ALLOWED_CASTS`.
    const CAST: &'static str;

    /// The SQL type for the `plaintext` column (e.g. `"integer"`).
    /// Lowercase so it passes `validation::is_valid_identifier` and can be
    /// validated the same way as every other SQL token.
    const PLAINTEXT_SQL_TYPE: &'static str;
}

impl EqlPlaintext for i32 {
    const CAST: &'static str = "int";
    const PLAINTEXT_SQL_TYPE: &'static str = "integer";
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::fixtures::validation::{is_valid_cast, is_valid_plaintext_type};

    #[test]
    fn i32_casts_to_int() {
        assert_eq!(<i32 as EqlPlaintext>::CAST, "int");
    }

    #[test]
    fn i32_cast_is_in_the_eql_allowlist() {
        // A const CAST that EQL would reject server-side is a framework bug.
        assert!(is_valid_cast(<i32 as EqlPlaintext>::CAST));
    }

    #[test]
    fn i32_plaintext_sql_type_is_integer() {
        assert_eq!(<i32 as EqlPlaintext>::PLAINTEXT_SQL_TYPE, "integer");
    }

    #[test]
    fn i32_plaintext_sql_type_is_in_the_allowlist() {
        // A const PLAINTEXT_SQL_TYPE outside the allowlist is a framework bug:
        // `.values()` would panic before any SQL is generated.
        assert!(is_valid_plaintext_type(
            <i32 as EqlPlaintext>::PLAINTEXT_SQL_TYPE
        ));
    }
}
