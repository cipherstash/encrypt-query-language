//! Maps a Rust plaintext type `T` to its EQL search-config cast and the SQL
//! type of the `plaintext` column.
//!
//! `Cast` and `PlaintextSqlType` are newtypes with private fields; the only
//! way to obtain one is via the predeclared constants on each type. That
//! makes the EQL allowlist structural — a `T::CAST` is, by construction, a
//! value EQL accepts. The trait is sealed so external crates cannot add
//! impls that bypass this guarantee.
//!
//! `to_plaintext` lifts the value into the cipherstash-client
//! `encryption::Plaintext` enum so the fixture generator can encrypt directly
//! via `eql::encrypt_eql` (no Proxy round trip).

use std::fmt;

use cipherstash_client::encryption::Plaintext;

/// The `cast_as` argument for `eql_v2.add_search_config`. The field is
/// private so the allowlist is the set of `pub const`s below.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Cast(&'static str);

impl Cast {
    pub const TEXT: Cast = Cast("text");
    pub const INT: Cast = Cast("int");
    pub const SMALL_INT: Cast = Cast("small_int");
    pub const BIG_INT: Cast = Cast("big_int");
    pub const REAL: Cast = Cast("real");
    pub const DOUBLE: Cast = Cast("double");
    pub const BOOLEAN: Cast = Cast("boolean");
    pub const DATE: Cast = Cast("date");
    pub const JSONB: Cast = Cast("jsonb");
    pub const JSON: Cast = Cast("json");
    pub const FLOAT: Cast = Cast("float");
    pub const DECIMAL: Cast = Cast("decimal");
    pub const TIMESTAMP: Cast = Cast("timestamp");

    pub fn as_str(&self) -> &'static str {
        self.0
    }
}

impl fmt::Display for Cast {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.0)
    }
}

/// The SQL type for the `plaintext` oracle column. As with `Cast`, the only
/// way to construct one is via the predeclared constants below.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PlaintextSqlType(&'static str);

impl PlaintextSqlType {
    pub const INTEGER: PlaintextSqlType = PlaintextSqlType("integer");

    pub fn as_str(&self) -> &'static str {
        self.0
    }
}

impl fmt::Display for PlaintextSqlType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.0)
    }
}

mod sealed {
    pub trait Sealed {}
    impl Sealed for i32 {}
}

/// A Rust type usable as a fixture `plaintext` value, carrying its EQL cast
/// and the SQL type of the `plaintext` column. Sealed; only this crate may
/// add impls.
pub trait EqlPlaintext: sealed::Sealed {
    const CAST: Cast;
    const PLAINTEXT_SQL_TYPE: PlaintextSqlType;

    /// Lift the Rust value into the cipherstash-client `Plaintext` enum the
    /// EQL encryption pipeline consumes. The mapping is total — every
    /// `EqlPlaintext` impl maps cleanly onto a `Plaintext::*(Some(_))`
    /// variant.
    ///
    /// Takes `&self` so future non-`Copy` plaintexts (`String`,
    /// `BigDecimal`, `Vec<u8>`) implement without unnecessary clones.
    fn to_plaintext(&self) -> Plaintext;
}

impl EqlPlaintext for i32 {
    const CAST: Cast = Cast::INT;
    const PLAINTEXT_SQL_TYPE: PlaintextSqlType = PlaintextSqlType::INTEGER;

    fn to_plaintext(&self) -> Plaintext {
        Plaintext::Int(Some(*self))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn i32_casts_to_int() {
        assert_eq!(<i32 as EqlPlaintext>::CAST.as_str(), "int");
    }

    #[test]
    fn i32_plaintext_sql_type_is_integer() {
        assert_eq!(
            <i32 as EqlPlaintext>::PLAINTEXT_SQL_TYPE.as_str(),
            "integer"
        );
    }

    #[test]
    fn i32_to_plaintext_wraps_in_int_variant() {
        // The trait must lift the raw i32 into the EQL pipeline's Plaintext
        // enum so the fixture driver can hand it to `eql::encrypt_eql`.
        match 42_i32.to_plaintext() {
            Plaintext::Int(Some(value)) => assert_eq!(value, 42),
            other => panic!("expected Plaintext::Int(Some(42)), got {other:?}"),
        }
    }
}
