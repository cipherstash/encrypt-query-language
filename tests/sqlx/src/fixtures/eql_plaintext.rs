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
    pub const BIGINT: PlaintextSqlType = PlaintextSqlType("bigint");
    pub const DATE: PlaintextSqlType = PlaintextSqlType("date");
    pub const TIMESTAMPTZ: PlaintextSqlType = PlaintextSqlType("timestamp with time zone");
    pub const TEXT: PlaintextSqlType = PlaintextSqlType("text");
    pub const JSONB: PlaintextSqlType = PlaintextSqlType("jsonb");
    pub const NUMERIC: PlaintextSqlType = PlaintextSqlType("numeric");
    pub const BOOLEAN: PlaintextSqlType = PlaintextSqlType("boolean");

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
/// Only the wired kinds (the integer kinds, `Text`, plus `Date` / `Timestamptz`)
/// have `EqlPlaintext` impls, so only those resolve; the remaining kinds mirror the
/// `eql_scalars` accessor convention and `panic!`, since no impl can ever reach
/// them.
const fn cast_for_kind(kind: ScalarKind) -> Cast {
    match kind {
        ScalarKind::I32 => Cast::INT,
        ScalarKind::I16 => Cast::SMALL_INT,
        ScalarKind::I64 => Cast::BIG_INT,
        ScalarKind::Date => Cast::DATE,
        ScalarKind::Timestamptz => Cast::TIMESTAMP,
        ScalarKind::Text => Cast::TEXT,
        ScalarKind::Numeric => Cast::DECIMAL,
        ScalarKind::Bool => Cast::BOOLEAN,
        ScalarKind::Jsonb => {
            panic!("EqlPlaintext is only implemented for the wired scalar kinds")
        }
    }
}

/// The `plaintext` oracle column SQL type for a scalar kind, drawn from the
/// `PlaintextSqlType` allowlist. As with `cast_for_kind`, only the wired kinds
/// (integers, `Text`, plus `Date` / `Timestamptz`) resolve.
const fn plaintext_sql_type_for_kind(kind: ScalarKind) -> PlaintextSqlType {
    match kind {
        ScalarKind::I32 => PlaintextSqlType::INTEGER,
        ScalarKind::I16 => PlaintextSqlType::SMALLINT,
        ScalarKind::I64 => PlaintextSqlType::BIGINT,
        ScalarKind::Date => PlaintextSqlType::DATE,
        ScalarKind::Timestamptz => PlaintextSqlType::TIMESTAMPTZ,
        ScalarKind::Text => PlaintextSqlType::TEXT,
        ScalarKind::Numeric => PlaintextSqlType::NUMERIC,
        ScalarKind::Bool => PlaintextSqlType::BOOLEAN,
        ScalarKind::Jsonb => {
            panic!("EqlPlaintext is only implemented for the wired scalar kinds")
        }
    }
}

mod sealed {
    pub trait Sealed {}
    impl Sealed for i32 {}
    impl Sealed for i16 {}
    impl Sealed for i64 {}
    impl Sealed for chrono::NaiveDate {}
    impl Sealed for chrono::DateTime<chrono::Utc> {}
    impl Sealed for String {}
    impl Sealed for serde_json::Value {}
    impl Sealed for rust_decimal::Decimal {}
    impl Sealed for bool {}
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

impl EqlPlaintext for i64 {
    const KIND: ScalarKind = ScalarKind::I64;

    fn to_plaintext(&self) -> Plaintext {
        Plaintext::BigInt(Some(*self))
    }
}

impl EqlPlaintext for chrono::NaiveDate {
    const KIND: ScalarKind = ScalarKind::Date;

    fn to_plaintext(&self) -> Plaintext {
        Plaintext::NaiveDate(Some(*self))
    }
}

impl EqlPlaintext for chrono::DateTime<chrono::Utc> {
    const KIND: ScalarKind = ScalarKind::Timestamptz;

    fn to_plaintext(&self) -> Plaintext {
        Plaintext::Timestamp(Some(*self))
    }
}

impl EqlPlaintext for String {
    const KIND: ScalarKind = ScalarKind::Text;

    fn to_plaintext(&self) -> Plaintext {
        Plaintext::Text(Some(self.clone()))
    }
}

/// A JSON document plaintext — the encrypted-JSONB (SteVec) fixture value.
///
/// `serde_json::Value` is the document analogue of the scalar plaintexts:
/// `to_plaintext` lifts it into `Plaintext::Json`, which cipherstash-client
/// encrypts into a SteVec `eql_v3.json` payload under a JSON-indexed
/// `ColumnConfig` (`IndexKind::SteVec`). The `cast_for_kind` /
/// `plaintext_sql_type_for_kind` derivations panic on `ScalarKind::Jsonb`
/// (the scalar matrix never wires jsonb), so this impl OVERRIDES `CAST` and
/// `PLAINTEXT_SQL_TYPE` directly — the default const expressions are never
/// instantiated for this type. `KIND` is still `Jsonb` for documentation.
impl EqlPlaintext for serde_json::Value {
    const KIND: ScalarKind = ScalarKind::Jsonb;
    const CAST: Cast = Cast::JSONB;
    const PLAINTEXT_SQL_TYPE: PlaintextSqlType = PlaintextSqlType::JSONB;

    fn to_plaintext(&self) -> Plaintext {
        Plaintext::Json(Some(self.clone()))
    }
}

impl EqlPlaintext for rust_decimal::Decimal {
    const KIND: ScalarKind = ScalarKind::Numeric;

    fn to_plaintext(&self) -> Plaintext {
        Plaintext::Decimal(Some(*self))
    }
}

impl EqlPlaintext for bool {
    const KIND: ScalarKind = ScalarKind::Bool;

    fn to_plaintext(&self) -> Plaintext {
        Plaintext::Boolean(Some(*self))
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

    #[test]
    fn i64_casts_to_big_int() {
        assert_eq!(<i64 as EqlPlaintext>::CAST.as_str(), "big_int");
    }

    #[test]
    fn i64_plaintext_sql_type_is_bigint() {
        assert_eq!(<i64 as EqlPlaintext>::PLAINTEXT_SQL_TYPE.as_str(), "bigint");
    }

    #[test]
    fn i64_to_plaintext_wraps_in_big_int_variant() {
        // i64 must lift into the BigInt variant so the fixture driver
        // encrypts it under the `big_int` cast, not `int`.
        match 42_i64.to_plaintext() {
            Plaintext::BigInt(Some(value)) => assert_eq!(value, 42),
            other => panic!("expected Plaintext::BigInt(Some(42)), got {other:?}"),
        }
    }

    #[test]
    fn naive_date_casts_to_date() {
        assert_eq!(<chrono::NaiveDate as EqlPlaintext>::CAST.as_str(), "date");
    }

    #[test]
    fn naive_date_plaintext_sql_type_is_date() {
        assert_eq!(
            <chrono::NaiveDate as EqlPlaintext>::PLAINTEXT_SQL_TYPE.as_str(),
            "date"
        );
    }

    #[test]
    fn naive_date_to_plaintext_wraps_in_naive_date_variant() {
        // A NaiveDate must lift into the NaiveDate variant so the fixture
        // driver encrypts it under the `date` cast.
        let d = chrono::NaiveDate::from_ymd_opt(1970, 1, 1).unwrap();
        match d.to_plaintext() {
            Plaintext::NaiveDate(Some(value)) => assert_eq!(value, d),
            other => panic!("expected Plaintext::NaiveDate(Some(1970-01-01)), got {other:?}"),
        }
    }

    #[test]
    fn datetime_utc_casts_to_timestamp() {
        // timestamptz is UTC-normalized — cipherstash has no tz-preserving
        // type, so it encrypts under the `timestamp` cast.
        assert_eq!(
            <chrono::DateTime<chrono::Utc> as EqlPlaintext>::CAST.as_str(),
            "timestamp"
        );
    }

    #[test]
    fn datetime_utc_plaintext_sql_type_is_timestamptz() {
        assert_eq!(
            <chrono::DateTime<chrono::Utc> as EqlPlaintext>::PLAINTEXT_SQL_TYPE.as_str(),
            "timestamp with time zone"
        );
    }

    #[test]
    fn datetime_utc_to_plaintext_wraps_in_timestamp_variant() {
        // A DateTime<Utc> must lift into the Timestamp variant so the fixture
        // driver encrypts it under the `timestamp` cast.
        let ts = chrono::DateTime::<chrono::Utc>::default();
        match ts.to_plaintext() {
            Plaintext::Timestamp(Some(value)) => assert_eq!(value, ts),
            other => panic!("expected Plaintext::Timestamp(Some(epoch)), got {other:?}"),
        }
    }

    #[test]
    fn string_cast_is_text() {
        assert_eq!(<String as EqlPlaintext>::CAST, Cast::TEXT);
    }

    #[test]
    fn string_plaintext_sql_type_is_text() {
        assert_eq!(
            <String as EqlPlaintext>::PLAINTEXT_SQL_TYPE,
            PlaintextSqlType::TEXT
        );
    }

    #[test]
    fn string_to_plaintext_is_text() {
        // A String must lift into the Text variant so the fixture driver
        // encrypts it under the `text` cast.
        let p = "hi".to_string().to_plaintext();
        assert!(matches!(p, Plaintext::Text(Some(ref s)) if s == "hi"));
    }

    #[test]
    fn json_value_casts_to_jsonb_and_plaintext_type_is_jsonb() {
        // The document impl OVERRIDES the kind-derived defaults (Jsonb would
        // panic in cast_for_kind), so assert the overrides resolve.
        assert_eq!(<serde_json::Value as EqlPlaintext>::CAST, Cast::JSONB);
        assert_eq!(
            <serde_json::Value as EqlPlaintext>::PLAINTEXT_SQL_TYPE,
            PlaintextSqlType::JSONB
        );
    }

    #[test]
    fn json_value_to_plaintext_wraps_in_json_variant() {
        // A document must lift into the Json variant so the fixture driver
        // encrypts it through the SteVec document path.
        let doc = serde_json::json!({ "hello": "world", "number": 1 });
        match doc.to_plaintext() {
            Plaintext::Json(Some(ref value)) => {
                assert_eq!(*value, serde_json::json!({ "hello": "world", "number": 1 }))
            }
            other => panic!("expected Plaintext::Json(Some(_)), got {other:?}"),
        }
    }

    #[test]
    fn bool_casts_to_boolean() {
        assert_eq!(<bool as EqlPlaintext>::CAST, Cast::BOOLEAN);
    }

    #[test]
    fn bool_plaintext_sql_type_is_boolean() {
        assert_eq!(
            <bool as EqlPlaintext>::PLAINTEXT_SQL_TYPE,
            PlaintextSqlType::BOOLEAN
        );
    }

    #[test]
    fn bool_to_plaintext_wraps_in_boolean_variant() {
        // A bool must lift into the Boolean variant so the fixture driver
        // encrypts it under the `boolean` cast (storage-only — no index term).
        match true.to_plaintext() {
            Plaintext::Boolean(Some(value)) => assert!(value),
            other => panic!("expected Plaintext::Boolean(Some(true)), got {other:?}"),
        }
        match false.to_plaintext() {
            Plaintext::Boolean(Some(value)) => assert!(!value),
            other => panic!("expected Plaintext::Boolean(Some(false)), got {other:?}"),
        }
    }
}
