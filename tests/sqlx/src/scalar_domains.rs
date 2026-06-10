//! Type-generic substrate for the encrypted-scalar-domain test matrix.
//!
//! Adding a new encrypted scalar type (e.g. `i64` for int8, `f64` for
//! float8) is one `<T> => <R>` line in the `scalar_types!` list
//! (`scalar_types.rs`) plus an `EqlPlaintext` impl and a catalog row.
//! The `impl ScalarType` below is generated from that list. Everything
//! else — the four `eql_v2_<T>{,_eq,_ord,_ord_ore}` domains, per-domain
//! payload shapes, supported operators, index extractor expressions,
//! ground-truth result sets — is derived from `T::PG_TYPE`,
//! `T::fixture_values()`, and the `Variant` enum.

use anyhow::{bail, Context, Result};
use sqlx::PgPool;
use std::fmt::{Debug, Display};

/// One impl per scalar type. Two `const`s and the rest defaults.
pub trait ScalarType:
    Clone
    + Ord
    + Default
    + Debug
    + Display
    + Send
    + Sync
    + Unpin
    + 'static
    + for<'r> sqlx::Decode<'r, sqlx::Postgres>
    + sqlx::Type<sqlx::Postgres>
{
    /// Postgres native type token — also the suffix in the SQL domain
    /// name and the fixture script name. Examples: `"int4"`, `"int8"`.
    const PG_TYPE: &'static str;

    /// Distinct plaintext values present in the fixture, in a stable
    /// order that MUST match fixture insertion order (the SQL script's
    /// `id` sequence). Callers rely on this: the fixture-shape test
    /// compares this slice element-wise against the `ORDER BY id`
    /// plaintext column, and the scale/index arms index positionally
    /// (`[0]`, `[len / 2]`) without sorting. A lazily-built `Vec` impl
    /// must therefore be built deterministically in that same order.
    ///
    /// A method rather than a `const` because non-integer scalars (e.g.
    /// `chrono::NaiveDate`, whose `from_ymd_opt` is not `const`) cannot be
    /// materialised into a const slice; the harness builds those into a
    /// `LazyLock<Vec<_>>` and returns a borrow of it (see `date_values`).
    /// Integer scalars return their `eql_scalars::<T>_VALUES` const directly.
    ///
    /// For types driven by `scalar_matrix!` (caps = [eq, ord]), the values MUST
    /// include the three `OrderedScalar` pivots (`min_pivot()`, `max_pivot()`,
    /// `mid_pivot()`): the matrix uses those as comparison pivots and fetches
    /// each one's ciphertext via `fetch_fixture_payload`, which fails loudly if
    /// the row is absent.
    fn fixture_values() -> &'static [Self];

    /// `fixtures.eql_v2_<pg_type>`.
    fn fixture_table_name() -> String {
        format!("fixtures.eql_v2_{}", Self::PG_TYPE)
    }

    /// SQL-literal rendering via `Display`. Takes `&Self` so a non-`Copy`
    /// scalar (e.g. `String`) can be rendered without being consumed. Override
    /// for types whose `Display` form isn't a valid SQL literal (e.g. strings,
    /// dates).
    fn to_sql_literal(value: &Self) -> String {
        value.to_string()
    }

    /// Ground-truth result set for `WHERE col op pivot`. Default works
    /// for any `Ord` scalar; override only for non-orderable types.
    fn expected_forward(op: &str, pivot: Self) -> Vec<Self> {
        // `&Self`-taking predicate so the default impl stays generic over a
        // merely-`Clone` (non-`Copy`) scalar like `String`.
        let predicate: fn(&Self, &Self) -> bool = match op {
            "=" => |a, b| a == b,
            "<>" => |a, b| a != b,
            "<" => |a, b| a < b,
            "<=" => |a, b| a <= b,
            ">" => |a, b| a > b,
            ">=" => |a, b| a >= b,
            other => panic!("expected_forward: unsupported operator {other}"),
        };
        let mut values: Vec<Self> = Self::fixture_values()
            .iter()
            .filter(|v| predicate(v, &pivot))
            .cloned()
            .collect();
        values.sort();
        values
    }
}

/// An **ordered** scalar — one whose `_ord` domains support `<`/`<=`/`>`/`>=`.
/// Carries the three comparison anchors the `scalar_matrix!` ordered arm sweeps:
/// the `min`/`max` boundaries and an interior `mid` pivot. All three must be
/// present verbatim in `fixture_values()` (the matrix fetches each pivot's
/// ciphertext via `fetch_fixture_payload`).
///
/// `min`/`max` are boundary anchors; `mid` is an interior anchor used by the
/// correctness/cross-shape sweep and the ORDER-BY-with-filter arm. `mid`
/// defaults to `Self::default()` — for signed scalars that is the numeric
/// origin (`0`, epoch), which is a fine interior anchor; lexicographic scalars
/// (e.g. `String`, whose `Default` is the degenerate empty string) override it
/// with a real median fixture.
pub trait OrderedScalar: ScalarType {
    /// The low boundary pivot. Integer scalars return `Self::MIN`; others an
    /// explicit sentinel. Present verbatim in `fixture_values()`.
    fn min_pivot() -> Self;

    /// The high boundary pivot. Integer scalars return `Self::MAX`; others an
    /// explicit sentinel. Present verbatim in `fixture_values()`.
    fn max_pivot() -> Self;

    /// The interior pivot. Defaults to `Self::default()` (the numeric origin for
    /// signed scalars); override where `Default` is not a usable fixture anchor.
    /// Present verbatim in `fixture_values()`.
    fn mid_pivot() -> Self {
        Self::default()
    }
}

/// A **signed** scalar — an ordered scalar with a numeric origin / sign
/// boundary (`int`, `date`). `text` is `OrderedScalar` but **not**
/// `SignedScalar`: lexicographic order has no origin. The bound gates the
/// signed-only sign-boundary test, so a `text` instantiation of it is a compile
/// error.
pub trait SignedScalar: OrderedScalar {
    /// The numeric origin (the sign boundary): `0` for integers, the epoch for
    /// dates. Fixtures straddle it (negatives below, positives above).
    fn origin() -> Self;
}

// The per-type `impl ScalarType` blocks for the **integer** scalars (each
// carrying its `PG_TYPE` token, `fixture_values() = eql_scalars::<TOKEN>_VALUES`,
// and `min_pivot()`/`max_pivot()` = `Self::MIN`/`Self::MAX`) are generated from
// the single harness list in `scalar_types.rs`. To add an integer type, add a
// `token => rust_type` line there — not an impl here.
//
// Temporal scalars (`chrono::NaiveDate`, and `DateTime<Utc>` in the stacked
// timestamptz PR) are hand-written below instead: their fixture values cannot be
// a `const` slice (chrono constructors are not `const`), and their pivots are
// explicit sentinels rather than `Self::MIN`/`Self::MAX`. The macro emits only
// integer impls.
crate::scalar_types!(scalar_type_impls);

/// Generate the test wiring for one chrono-backed (temporal) scalar from its
/// catalog row: a `LazyLock<Vec<T>>` parsing the catalog fixture strings, a
/// public `<accessor>()` returning a borrow of it, `impl ScalarType for T`, and
/// a `#[cfg(test)]` module asserting the parsed values track the catalog and
/// include the pivots. The chrono analogue of `eql_scalars::int_values!`
/// (integers materialise a `const` slice; temporals can't, so values live in a
/// `LazyLock`). `parse`/`min_pivot`/`max_pivot`/`sql_lit` are expressions so each
/// type supplies its own chrono parsing, sentinel pivots, and SQL literal form.
macro_rules! temporal_values {
    (
        cell      = $cell:ident,
        accessor  = $accessor:ident,
        rust_type = $ty:ty,
        spec      = $spec:path,
        variant   = $variant:ident,
        pg_type   = $pg:literal,
        parse     = $parse:expr,
        min_pivot = $min:expr,
        max_pivot = $max:expr,
        sql_lit   = $sql_lit:expr $(,)?
    ) => {
        static $cell: std::sync::LazyLock<Vec<$ty>> = std::sync::LazyLock::new(|| {
            let parse: fn(&str) -> $ty = $parse;
            $spec
                .fixtures
                .iter()
                .map(|f| match f {
                    ::eql_scalars::Fixture::$variant(s) => parse(s),
                    other => panic!(concat!("non-", $pg, " fixture in ", $pg, " catalog row: {:?}"), other),
                })
                .collect()
        });

        #[doc = concat!("Typed `", stringify!($ty), "` fixtures for `", $pg, "`, parsed once from the catalog.")]
        pub fn $accessor() -> &'static [$ty] {
            &$cell
        }

        impl ScalarType for $ty {
            const PG_TYPE: &'static str = $pg;
            fn fixture_values() -> &'static [$ty] { $accessor() }
            fn to_sql_literal(value: &$ty) -> String {
                let f: fn(&$ty) -> String = $sql_lit;
                f(value)
            }
        }

        impl OrderedScalar for $ty {
            fn min_pivot() -> $ty { $min }
            fn max_pivot() -> $ty { $max }
            // `mid_pivot` inherits the default `Self::default()`. Every chrono
            // temporal type's `Default` is the epoch (`1970-01-01` for a date),
            // which is also `origin()` — a real fixture and the sign boundary.
        }

        impl SignedScalar for $ty {
            // Temporal scalars encrypt as a signed offset from the epoch, so the
            // numeric origin is `Self::default()` (e.g. `1970-01-01`); fixtures
            // straddle it (earlier dates below, later dates above).
            fn origin() -> $ty { <$ty as ::core::default::Default>::default() }
        }

        #[cfg(test)]
        mod $accessor {
            use super::*;
            #[test]
            fn values_match_catalog_fixtures() {
                let parse: fn(&str) -> $ty = $parse;
                let want: Vec<$ty> = $spec.fixtures.iter().map(|f| match f {
                    ::eql_scalars::Fixture::$variant(s) => parse(s),
                    other => panic!("non-{} fixture: {:?}", $pg, other),
                }).collect();
                assert_eq!($accessor(), want.as_slice());
            }
            #[test]
            fn pivots_present_in_fixtures() {
                let vals = $accessor();
                assert!(vals.contains(&<$ty as OrderedScalar>::min_pivot()), "min pivot missing");
                assert!(vals.contains(&<$ty as OrderedScalar>::max_pivot()), "max pivot missing");
                // The matrix sweeps the interior `mid_pivot()` (here the default
                // origin) on every ordered suite and fetches its ciphertext via
                // `fetch_fixture_payload`, so it must be present verbatim too.
                assert!(vals.contains(&<$ty as OrderedScalar>::mid_pivot()), "mid/default pivot missing");
                assert_eq!(
                    <$ty as OrderedScalar>::mid_pivot(),
                    <$ty as SignedScalar>::origin(),
                    "for a signed temporal scalar mid_pivot == origin",
                );
            }
        }
    };
}

// `date`'s `ScalarType` wiring is generated from its catalog row by
// `temporal_values!` — the chrono analogue of the integer `int_values!` path.
// Values can't be a `const` slice (`from_ymd_opt` is not `const`), so they live
// in a `LazyLock<Vec<_>>` behind `date_values()`. `date_values()` is public so
// the `eql_v2_date` fixture module (emitted by `scalar_types!(fixture_modules)`)
// can hand the slice to `scalar_fixture!`.
temporal_values! {
    cell      = DATE_VALUES_CELL,
    accessor  = date_values,
    rust_type = chrono::NaiveDate,
    spec      = eql_scalars::DATE,
    variant   = Date,
    pg_type   = "date",
    parse     = |s| chrono::NaiveDate::parse_from_str(s, "%Y-%m-%d")
        .expect("catalog date fixture must be YYYY-MM-DD"),
    min_pivot = chrono::NaiveDate::from_ymd_opt(1900, 1, 1).expect("1900-01-01 valid"),
    max_pivot = chrono::NaiveDate::from_ymd_opt(2099, 12, 31).expect("2099-12-31 valid"),
    sql_lit   = |v| format!("'{v}'"),
}

// `timestamptz`'s `ScalarType` wiring, generated from its catalog row by the
// same `temporal_values!` path as `date`. timestamptz is equality-only (its
// catalog row uses the eq-only domain shape), but the *value* wiring is
// identical to any temporal scalar: RFC3339 strings parsed once into
// `DateTime<Utc>` behind `timestamptz_values()`. The pivots are retained as the
// three equality anchors the matrix sweeps.
temporal_values! {
    cell      = TIMESTAMPTZ_VALUES_CELL,
    accessor  = timestamptz_values,
    rust_type = chrono::DateTime<chrono::Utc>,
    spec      = eql_scalars::TIMESTAMPTZ,
    variant   = Timestamptz,
    pg_type   = "timestamptz",
    parse     = |s| chrono::DateTime::parse_from_rfc3339(s)
        .expect("catalog timestamptz fixture must be RFC3339")
        .with_timezone(&chrono::Utc),
    min_pivot = "1900-01-01T00:00:00Z"
        .parse()
        .expect("1900-01-01T00:00:00Z is a valid timestamp"),
    max_pivot = "2099-12-31T23:59:59Z"
        .parse()
        .expect("2099-12-31T23:59:59Z is a valid timestamp"),
    sql_lit   = |v| format!("'{}'", v.to_rfc3339()),
}

/// Focused guards for the timestamptz value wiring that the `temporal_values!`
/// auto-generated tests can't cover, because every catalog fixture is already
/// `…Z` (UTC). Both tests intentionally live in the harness, not in
/// `eql-scalars`, which is deliberately zero-dep (no chrono).
#[cfg(test)]
mod timestamptz_value_guards {
    use super::*;

    // Mirror of the `temporal_values!` parse closure above. Kept independent so
    // a regression that drops the offset→UTC conversion in the macro invocation
    // is caught here rather than re-running the (all-UTC, tautological) catalog
    // fixtures.
    fn parse(s: &str) -> chrono::DateTime<chrono::Utc> {
        chrono::DateTime::parse_from_rfc3339(s)
            .expect("RFC3339")
            .with_timezone(&chrono::Utc)
    }

    /// The type's headline guarantee ("Values are UTC-normalized") exercised
    /// with a genuinely non-UTC input. Passes today; fails the moment the parse
    /// path stops converting offsets to UTC (e.g. a switch to `.naive_utc()` or
    /// constructing the `DateTime<Utc>` from the naive local time).
    #[test]
    fn rfc3339_offset_is_normalized_to_utc() {
        use chrono::{Datelike, Timelike};
        // 05:00 at +05:00 is midnight UTC — same instant as the Z form.
        assert_eq!(
            parse("2000-01-01T05:00:00+05:00"),
            parse("2000-01-01T00:00:00Z"),
        );
        // …and it lands on the UTC wall-clock, not the offset-local one.
        let utc = parse("2000-01-01T05:00:00+05:00");
        assert_eq!((utc.hour(), utc.day()), (0, 1));
    }

    /// `eql-scalars::invariant_tests::fixture_values_are_distinct_by_resolved_number`
    /// keys `Fixture::Timestamptz` by its literal string, so two RFC3339 strings
    /// that denote the same UTC instant (e.g. `…00:00Z` vs `…01:00+01:00`) would
    /// pass as "distinct" there. The fixture *table* keys on the parsed
    /// `DateTime<Utc>`, so an aliasing pair would silently insert duplicate
    /// `plaintext` rows and break `fetch_fixture_payload`'s `fetch_one`. This
    /// guards distinctness by instant, which is the property the table relies on.
    #[test]
    fn fixtures_are_distinct_by_instant() {
        use std::collections::HashSet;
        let vals = timestamptz_values(); // &[DateTime<Utc>], parsed from the catalog
        let unique: HashSet<_> = vals.iter().collect();
        assert_eq!(
            unique.len(),
            vals.len(),
            "two timestamptz fixtures alias to the same UTC instant",
        );
    }
}

// `text` is hand-written rather than driven by `temporal_values!`: it is an
// owned `String` (not chrono-backed), so it materialises its values from the
// `eql_scalars::TEXT_VALUES` const slice rather than parsing catalog strings.
// `text_values()` is public so the `eql_v2_text` fixture module (emitted by
// `scalar_types!(fixture_modules)`) can hand the slice to `scalar_fixture!`.

/// Typed `String` fixture values, built once from `text`'s catalog row.
/// `eql_scalars::TEXT_VALUES` is a `&[&'static str]` const, but the `ScalarType`
/// contract returns `&[Self]` = `&[String]` (owned), so we materialise them into
/// a `LazyLock<Vec<String>>` and return a borrow — the same shape as
/// `date_values`. (Unlike `date`, no parsing is needed; the values are the
/// strings verbatim.)
static TEXT_VALUES_CELL: std::sync::LazyLock<Vec<String>> = std::sync::LazyLock::new(|| {
    eql_scalars::TEXT_VALUES
        .iter()
        .map(|s| s.to_string())
        .collect()
});

/// The `String` fixture values, in catalog order. Public so the `eql_v2_text`
/// fixture module (emitted by `scalar_types!(fixture_modules)`) can hand the
/// slice to `scalar_fixture!`.
pub fn text_values() -> &'static [String] {
    &TEXT_VALUES_CELL
}

impl ScalarType for String {
    const PG_TYPE: &'static str = "text";

    fn fixture_values() -> &'static [Self] {
        text_values()
    }

    /// `Display` for a `String` is the unquoted text, which is not a valid SQL
    /// literal; quote it and double any embedded single quotes.
    fn to_sql_literal(value: &Self) -> String {
        format!("'{}'", value.replace('\'', "''"))
    }
}

impl OrderedScalar for String {
    /// Lexicographic min pivot — the lexicographically-smallest fixture
    /// (`"aard"`). Present verbatim in `fixture_values()`; keep in sync with
    /// `TEXT_FIXTURES`.
    fn min_pivot() -> Self {
        "aard".to_string()
    }

    /// Lexicographic max pivot — the lexicographically-largest fixture
    /// (`"zzzz"`).
    fn max_pivot() -> Self {
        "zzzz".to_string()
    }

    /// Interior pivot — a real median fixture. `String::default()` is `""`,
    /// which is degenerate for ORE (issue #262), so `text` overrides the
    /// inherited default with a genuine middle value.
    fn mid_pivot() -> Self {
        "frank".to_string()
    }
}

// `String` is deliberately NOT `SignedScalar`: lexicographic text has no
// numeric origin / sign boundary. The signed-only sign-boundary test bounds on
// `SignedScalar`, so a `String` instantiation of it would not compile.

#[cfg(test)]
mod text_value_tests {
    use super::*;

    /// The `min`/`mid`/`max` pivots resolve to fixture rows present verbatim, so
    /// `fetch_fixture_payload` can resolve each one's ciphertext.
    #[test]
    fn text_pivots_are_in_fixture_values() {
        let values = <String as ScalarType>::fixture_values();
        let min = <String as OrderedScalar>::min_pivot();
        let mid = <String as OrderedScalar>::mid_pivot();
        let max = <String as OrderedScalar>::max_pivot();
        assert!(values.contains(&min), "min_pivot {min:?} must be a fixture");
        assert!(values.contains(&mid), "mid_pivot {mid:?} must be a fixture");
        assert!(values.contains(&max), "max_pivot {max:?} must be a fixture");
        assert!(min <= mid && mid <= max, "min <= mid <= max must hold");
        // text has no numeric origin: the empty string is not a fixture.
        assert!(
            !values.iter().any(|v| v.is_empty()),
            "the empty string must not be a text fixture"
        );
    }

    /// The harness value list matches the catalog `TEXT_VALUES` in order — the
    /// oracle cannot drift from the catalog the fixture generator encrypts.
    #[test]
    fn text_values_match_catalog() {
        let got: Vec<&str> = <String as ScalarType>::fixture_values()
            .iter()
            .map(|s| s.as_str())
            .collect();
        assert_eq!(got, eql_scalars::TEXT_VALUES.to_vec());
    }

    /// Directly exercises the `String` `to_sql_literal` override's
    /// single-quote-doubling branch. Every `TEXT_VALUES` fixture is quote-free,
    /// so no DB-backed test reaches the `.replace('\'', "''")`; this pins it so a
    /// quoting/injection regression in the override is caught. (The sibling
    /// `sql_string_literal` helper is tested separately — this covers the
    /// trait method itself.)
    #[test]
    fn text_to_sql_literal_escapes_single_quotes() {
        assert_eq!(
            <String as ScalarType>::to_sql_literal(&"O'Brien".to_string()),
            "'O''Brien'"
        );
        // a quote-free value is wrapped but otherwise untouched
        assert_eq!(
            <String as ScalarType>::to_sql_literal(&"frank".to_string()),
            "'frank'"
        );
    }
}

/// Per-domain capability + payload shape. Storage carries no terms, `Eq`
/// adds `hm`, `Ord`/`OrdOre` add `ob`. `Ord` and `OrdOre` are deliberate
/// twins — same operator surface, different SQL domain names — for the
/// scheme-explicit vs converged-name migration story.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Variant {
    Storage,
    Eq,
    Ord,
    OrdOre,
}

impl Variant {
    /// Every variant the family currently materialises, in declaration
    /// order. Tests iterate over this rather than hand-listing variants
    /// so adding a future variant requires no test edit.
    pub const ALL: &'static [Variant] =
        &[Variant::Storage, Variant::Eq, Variant::Ord, Variant::OrdOre];

    pub const fn suffix(self) -> &'static str {
        match self {
            Variant::Storage => "",
            Variant::Eq => "_eq",
            Variant::Ord => "_ord",
            Variant::OrdOre => "_ord_ore",
        }
    }

    /// Term key the variant requires on its CHECK constraint. `Storage`
    /// requires nothing beyond the envelope; `Eq` requires `hm`;
    /// `Ord` / `OrdOre` require `ob`. Read by tests that need to know
    /// "what term does this variant carry?" — not by payload builders;
    /// see `PLACEHOLDER_PAYLOAD`.
    pub const fn required_term(self) -> Option<&'static str> {
        match self {
            Variant::Storage => None,
            Variant::Eq => Some("hm"),
            Variant::Ord | Variant::OrdOre => Some("ob"),
        }
    }

    /// Top-level JSONB keys the variant's domain CHECK requires.
    /// Storage requires the EQL envelope (`v`, `i`, `c`); ord-capable
    /// variants additionally require their term key (`hm` / `ob`). The
    /// matrix `payload_check` arm iterates this to assert each key's
    /// absence is rejected at the cast.
    pub fn payload_required_keys(self) -> impl Iterator<Item = &'static str> {
        ["v", "i", "c"].into_iter().chain(self.required_term())
    }

    pub const fn supports_eq(self) -> bool {
        !matches!(self, Variant::Storage)
    }

    pub const fn supports_ord(self) -> bool {
        matches!(self, Variant::Ord | Variant::OrdOre)
    }

    /// Function name of the discriminating extractor for this variant,
    /// or `None` if the variant carries no extractor (`Storage`). Returns
    /// just the function name — call sites append `(column)` themselves so
    /// the accessor is decoupled from any specific column-naming
    /// convention. `Eq` resolves to `eql_v3.eq_term`; `Ord` and `OrdOre`
    /// both resolve to `eql_v3.ord_term`.
    pub const fn extractor_fn(self) -> Option<&'static str> {
        match self {
            Variant::Storage => None,
            Variant::Eq => Some("eql_v3.eq_term"),
            Variant::Ord | Variant::OrdOre => Some("eql_v3.ord_term"),
        }
    }
}

/// Runtime spec built from `(T, Variant)`. The matrix macro consumes
/// this; nothing here is `const` because `sql_domain` is derived via
/// `format!` from `T::PG_TYPE`. The domains live in the `eql_v3` schema,
/// so `sql_domain` is schema-qualified (e.g. `eql_v3.int4_eq`).
#[derive(Debug, Clone)]
pub struct ScalarDomainSpec {
    pub sql_domain: String,
    pub variant: Variant,
}

impl ScalarDomainSpec {
    pub fn new<T: ScalarType>(variant: Variant) -> Self {
        Self {
            sql_domain: format!("eql_v3.{}{}", T::PG_TYPE, variant.suffix()),
            variant,
        }
    }

    pub fn supports_eq(&self) -> bool {
        self.variant.supports_eq()
    }

    pub fn supports_ord(&self) -> bool {
        self.variant.supports_ord()
    }

    pub fn extractor_fn(&self) -> Option<&'static str> {
        self.variant.extractor_fn()
    }
}

/// SQL string-literal escaping for direct interpolation.
pub fn sql_string_literal(value: &str) -> String {
    format!("'{}'", value.replace('\'', "''"))
}

/// `a op b` and `b op' a` return the same row set when `op'` is the
/// commutator of `op`. Used by the cross-shape arm when the column moves
/// to the right operand.
pub fn commute_op(op: &str) -> &'static str {
    match op {
        "=" => "=",
        "<>" => "<>",
        "<" => ">",
        "<=" => ">=",
        ">" => "<",
        ">=" => "<=",
        other => panic!("commute_op: unsupported operator {other}"),
    }
}

/// Fetch the payload row keyed by `plaintext` from `T`'s fixture table.
pub async fn fetch_fixture_payload<T: ScalarType>(pool: &PgPool, plaintext: T) -> Result<String> {
    let sql = format!(
        "SELECT payload::text FROM {table} WHERE plaintext = {lit}",
        table = T::fixture_table_name(),
        lit = T::to_sql_literal(&plaintext),
    );
    sqlx::query_scalar(&sql)
        .fetch_one(pool)
        .await
        .with_context(|| {
            format!(
                "fetching {} payload for plaintext={:?}",
                T::fixture_table_name(),
                plaintext
            )
        })
}

/// Sorted plaintexts matching `predicate` against `T`'s fixture table.
async fn scalar_plaintexts_matching<T: ScalarType>(
    pool: &PgPool,
    predicate: &str,
) -> Result<Vec<T>> {
    let sql = format!(
        "SELECT plaintext FROM {table} WHERE {predicate} ORDER BY plaintext",
        table = T::fixture_table_name(),
    );
    let mut rows: Vec<T> = sqlx::query_scalar(&sql)
        .fetch_all(pool)
        .await
        .with_context(|| format!("running scalar plaintext query: {sql}"))?;
    rows.sort();
    Ok(rows)
}

/// Run `predicate` against `T`'s fixture; assert plaintexts equal `expected`.
pub async fn assert_scalar_plaintexts<T: ScalarType>(
    pool: &PgPool,
    domain: &str,
    op: &str,
    predicate: &str,
    expected: &[T],
) -> Result<()> {
    let actual = scalar_plaintexts_matching::<T>(pool, predicate).await?;
    let mut want = expected.to_vec();
    want.sort();
    assert_eq!(
        actual, want,
        "domain={domain} operator={op} predicate={predicate} must match expected plaintexts"
    );
    Ok(())
}

/// Unified raise-assertion: query must error and the message must contain
/// `expected_msg`. Covers blocker raises (`expected_msg = "operator X is
/// not supported for {domain}"`) and native-operator absence
/// (`"operator does not exist"`). Bind slots are `Option<&str>`: `Some`
/// = bind the payload, `None` = bind NULL.
pub async fn assert_raises(
    pool: &PgPool,
    sql: &str,
    binds: &[Option<&str>],
    expected_msg: &str,
) -> Result<()> {
    let mut q = sqlx::query(sql);
    for b in binds {
        q = q.bind(*b);
    }
    let result = q.fetch_one(pool).await;
    let err = match result {
        Ok(_) => bail!("SQL must raise: {sql}"),
        Err(e) => e.to_string(),
    };
    if !err.contains(expected_msg) {
        bail!("SQL={sql} expected error containing {expected_msg:?}, got {err}");
    }
    Ok(())
}

/// Unified NULL-result assertion: the query must succeed and return NULL.
/// Used for supported operators where STRICT semantics propagate NULL.
pub async fn assert_null(pool: &PgPool, sql: &str, binds: &[Option<&str>]) -> Result<()> {
    let mut q = sqlx::query_scalar::<_, Option<bool>>(sql);
    for b in binds {
        q = q.bind(*b);
    }
    let result: Option<bool> = q
        .fetch_one(pool)
        .await
        .with_context(|| format!("running null-result assertion: {sql}"))?;
    if result.is_some() {
        bail!("SQL={sql} with NULL operand must yield NULL, got {result:?}");
    }
    Ok(())
}

/// Blocker error message — the contract every encrypted-domain blocker
/// must satisfy regardless of arg shape or NULL configuration.
pub fn blocker_msg(domain: &str, op: &str) -> String {
    format!("operator {op} is not supported for {domain}")
}
