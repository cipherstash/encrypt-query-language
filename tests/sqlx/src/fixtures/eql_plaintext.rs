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
use eql_scalars::ScalarKind;

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
    pub const SMALLINT: PlaintextSqlType = PlaintextSqlType("smallint");

    pub fn as_str(&self) -> &'static str {
        self.0
    }
}

impl fmt::Display for PlaintextSqlType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.0)
    }
}

/// The EQL `cast_as` for a scalar kind, drawn from the `Cast` allowlist.
///
/// Only the integer kinds have `EqlPlaintext` impls, so only those resolve;
/// the non-integer kinds mirror the `eql_scalars` accessor convention and
/// `panic!`, since no impl can ever reach them.
const fn cast_for_kind(kind: ScalarKind) -> Cast {
    match kind {
        ScalarKind::I32 => Cast::INT,
        ScalarKind::I16 => Cast::SMALL_INT,
        ScalarKind::I64 | ScalarKind::Numeric | ScalarKind::Text | ScalarKind::Jsonb => {
            panic!("EqlPlaintext is only implemented for integer scalar kinds")
        }
    }
}

/// The `plaintext` oracle column SQL type for a scalar kind, drawn from the
/// `PlaintextSqlType` allowlist. As with `cast_for_kind`, only integer kinds
/// resolve.
const fn plaintext_sql_type_for_kind(kind: ScalarKind) -> PlaintextSqlType {
    match kind {
        ScalarKind::I32 => PlaintextSqlType::INTEGER,
        ScalarKind::I16 => PlaintextSqlType::SMALLINT,
        ScalarKind::I64 | ScalarKind::Numeric | ScalarKind::Text | ScalarKind::Jsonb => {
            panic!("EqlPlaintext is only implemented for integer scalar kinds")
        }
    }
}

mod sealed {
    pub trait Sealed {}
    impl Sealed for i32 {}
    impl Sealed for i16 {}
}

/// A Rust type usable as a fixture `plaintext` value, carrying its EQL cast
/// and the SQL type of the `plaintext` column. Sealed; only this crate may
/// add impls.
///
/// Each impl supplies a single `KIND`; the EQL cast and `plaintext` column
/// SQL type are derived from it via `cast_for_kind` /
/// `plaintext_sql_type_for_kind`, so they cannot drift from the kind.
pub trait EqlPlaintext: sealed::Sealed {
    /// The scalar kind this plaintext type maps to. The single source of
    /// truth from which `CAST` and `PLAINTEXT_SQL_TYPE` are derived.
    const KIND: ScalarKind;

    const CAST: Cast = cast_for_kind(Self::KIND);
    const PLAINTEXT_SQL_TYPE: PlaintextSqlType = plaintext_sql_type_for_kind(Self::KIND);

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
    const KIND: ScalarKind = ScalarKind::I32;

    fn to_plaintext(&self) -> Plaintext {
        Plaintext::Int(Some(*self))
    }
}

impl EqlPlaintext for i16 {
    const KIND: ScalarKind = ScalarKind::I16;

    fn to_plaintext(&self) -> Plaintext {
        Plaintext::SmallInt(Some(*self))
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

    #[test]
    fn i16_casts_to_small_int() {
        assert_eq!(<i16 as EqlPlaintext>::CAST.as_str(), "small_int");
    }

    #[test]
    fn i16_plaintext_sql_type_is_smallint() {
        assert_eq!(
            <i16 as EqlPlaintext>::PLAINTEXT_SQL_TYPE.as_str(),
            "smallint"
        );
    }

    #[test]
    fn i16_to_plaintext_wraps_in_small_int_variant() {
        // i16 must lift into the SmallInt variant so the fixture driver
        // encrypts it under the `small_int` cast, not `int`.
        match 42_i16.to_plaintext() {
            Plaintext::SmallInt(Some(value)) => assert_eq!(value, 42),
            other => panic!("expected Plaintext::SmallInt(Some(42)), got {other:?}"),
        }
    }
}
