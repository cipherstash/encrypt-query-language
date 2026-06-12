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
use eql_scalars::{Term, CATALOG};
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

    /// SQL domain the comparable value is cast to. Default: the generated
    /// scalar domain `eql_v3.<pg_type><variant_suffix>`. A non-scalar surface
    /// (e.g. a SteVec entry, whose single domain `eql_v3.ste_vec_entry` is
    /// variant-independent) overrides this to ignore the suffix.
    fn sql_domain(variant: Variant) -> String {
        format!("eql_v3.{}{}", Self::PG_TYPE, variant.suffix())
    }

    /// SQL expression that yields the comparable value from a fixture row.
    /// Default: the bare `payload` column (a whole encrypted-scalar payload).
    /// A SteVec-entry view overrides this with an extraction expression such
    /// as `(payload -> '<selector>')`, which already has type
    /// `eql_v3.ste_vec_entry`. The expression is cast to `sql_domain(variant)`
    /// at every call site, so a redundant `::eql_v3.ste_vec_entry` cast on an
    /// already-entry expression is a harmless no-op.
    fn column_expr() -> String {
        "payload".to_string()
    }

    /// A valid payload literal for this SQL domain family. Used by NULL
    /// propagation and typecheck tests where the payload is bound but never
    /// decrypted. Default: scalar root-envelope placeholder.
    fn placeholder_payload() -> &'static str {
        crate::helpers::PLACEHOLDER_PAYLOAD
    }

    /// Equality extractor expression for a domain-typed value expression.
    /// Default scalar Eq path is `eql_v3.eq_term(value)`.
    fn eq_extractor_expr(value_expr: &str) -> String {
        format!("eql_v3.eq_term({value_expr})")
    }

    /// Ordering extractor expression for a domain-typed value expression.
    /// Default scalar Ord/OrdOre path is `eql_v3.ord_term(value)`.
    /// SteVec entries override this to `eql_v3.ore_cllw(value)`.
    fn ord_extractor_expr(value_expr: &str) -> String {
        format!("eql_v3.ord_term({value_expr})")
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

/// A scalar with a **bloom-filter match** capability (`@>`/`<@` containment) —
/// currently only `text`, the one kind that declares a `Bloom`-bearing domain
/// (`_match`/`_search`). Provides three fixture plaintexts with known
/// containment relationships so the generated match arms can assert true hits
/// and a deterministic miss. The bound gates the match arms: a non-match scalar
/// never declares `_search`, so the `caps = [eq, ord, search]` matrix arm (the
/// only one emitting match cases) is never instantiated for it.
pub trait MatchScalar: ScalarType {
    /// A "haystack" plaintext whose bloom filter contains [`needle`](Self::needle)
    /// (they share n-grams). Present verbatim in `fixture_values()`.
    fn haystack() -> Self;

    /// A "needle" plaintext that is a sub-token of [`haystack`](Self::haystack).
    /// Present verbatim in `fixture_values()`.
    fn needle() -> Self;

    /// A plaintext n-gram-**disjoint** from [`needle`](Self::needle), so
    /// `needle @> disjoint` is a deterministic miss (a bloom filter only admits
    /// false positives, never false negatives). Present verbatim in
    /// `fixture_values()`.
    fn disjoint() -> Self;
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

impl MatchScalar for String {
    /// `"aardvark"` — its bloom filter contains `"aard"` (shared 3-grams
    /// `aar`, `ard`). Matches the haystack used by the sibling `text_match`
    /// behavioural suite. Present verbatim in `TEXT_FIXTURES`.
    fn haystack() -> Self {
        "aardvark".to_string()
    }

    /// `"aard"` — a sub-token of `"aardvark"`.
    fn needle() -> Self {
        "aard".to_string()
    }

    /// `"zzzz"` — 3-gram-disjoint from `"aard"` (`zzz` vs `aar`/`ard`), so
    /// `aard @> zzzz` is a deterministic miss. Kept disjoint in `TEXT_FIXTURES`
    /// precisely for this assertion.
    fn disjoint() -> Self {
        "zzzz".to_string()
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

/// Per-domain capability + payload shape, resolved from `CATALOG`. Each
/// variant maps to a domain suffix (`Eq` => `_eq`, `Search` => `_search`,
/// …); its terms, required payload keys, supported operators, and
/// per-operator extractors are derived from the catalog row for a given
/// scalar `token`, never hardcoded. This is the SAME single source codegen
/// renders from, so the harness routing cannot drift from the generated SQL.
/// `Ord` and `OrdOre` are deliberate twins — same operator surface,
/// different SQL domain names — for the scheme-explicit vs converged-name
/// migration story.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Variant {
    Storage,
    Eq,
    Ord,
    OrdOre,
    Search,
}

impl Variant {
    /// Every variant the family can materialise, in declaration order. Not
    /// every scalar declares every variant (only `text` declares `_search`),
    /// so iteration sites that span scalars must filter with
    /// [`Variant::is_declared_for`].
    pub const ALL: &'static [Variant] = &[
        Variant::Storage,
        Variant::Eq,
        Variant::Ord,
        Variant::OrdOre,
        Variant::Search,
    ];

    pub const fn suffix(self) -> &'static str {
        match self {
            Variant::Storage => "",
            Variant::Eq => "_eq",
            Variant::Ord => "_ord",
            Variant::OrdOre => "_ord_ore",
            Variant::Search => "_search",
        }
    }

    /// The fixed index terms this variant's domain carries for scalar `token`,
    /// from `CATALOG`. Panics if the `(token, suffix())` pair is not declared —
    /// the resolution backstop test guarantees every instantiated pair
    /// resolves, so a panic here means the matrix and catalog drifted. Guard
    /// cross-scalar iteration with [`Variant::is_declared_for`].
    pub fn terms_for(self, token: &str) -> &'static [Term] {
        CATALOG
            .iter()
            .find(|s| s.token == token)
            .and_then(|s| s.domain_by_suffix(self.suffix()))
            .map(|d| d.terms)
            .unwrap_or_else(|| {
                panic!(
                    "no catalog domain for ({token}, {self:?}) suffix `{}`",
                    self.suffix()
                )
            })
    }

    /// True when scalar `token` declares this variant's domain in `CATALOG`.
    /// Use to filter `Variant::ALL` when iterating across scalars that do not
    /// all declare the same variants (e.g. only `text` declares `_search`).
    pub fn is_declared_for(self, token: &str) -> bool {
        CATALOG
            .iter()
            .find(|s| s.token == token)
            .and_then(|s| s.domain_by_suffix(self.suffix()))
            .is_some()
    }

    /// Top-level JSONB keys the variant's domain CHECK requires for `token`:
    /// the EQL envelope (`v`, `i`, `c`) plus each term's payload key
    /// (`hm`/`ob`/`bf`), in term order. Catalog-derived — `text_ord` yields
    /// `[v, i, c, hm, ob]`; `text_search` yields `[v, i, c, hm, ob, bf]`. The
    /// matrix `payload_check` arm iterates this to assert each key's absence is
    /// rejected at the cast.
    pub fn payload_required_keys(self, token: &str) -> Vec<&'static str> {
        let mut keys = vec!["v", "i", "c"];
        keys.extend(Term::term_json_keys(self.terms_for(token)));
        keys
    }

    /// True when the variant's domain supports `=`/`<>` for `token`.
    pub fn supports_eq(self, token: &str) -> bool {
        Term::operators_for_terms(self.terms_for(token)).contains(&"=")
    }

    /// True when the variant's domain supports the four ordering operators.
    pub fn supports_ord(self, token: &str) -> bool {
        self.terms_for(token).iter().any(|t| t.provides_ordering())
    }

    /// The `eql_v3`-qualified extractor that serves `op` on this variant's
    /// domain for `token`, or `None` if unsupported (or `Storage`). Derived via
    /// `Term::extractor_for_operator` — the SAME single source codegen uses, so
    /// the harness routing cannot diverge from the generated SQL. For
    /// `text_ord` `[Hm, Ore]`, `=` => `eql_v3.eq_term`, `<` => `eql_v3.ord_term`.
    pub fn extractor_for_op(self, token: &str, op: &str) -> Option<String> {
        Term::extractor_for_operator(self.terms_for(token), op).map(|f| format!("eql_v3.{f}"))
    }

    /// The `eql_v3`-qualified extractor of this variant's first
    /// extractor-bearing term for `token`, or `None` for `Storage`. Used where
    /// a single representative extractor is needed independent of any operator
    /// (e.g. the `COUNT(DISTINCT)` deduplication arm). For a multi-term domain
    /// this is the first term's extractor (`text_ord` `[Hm, Ore]` => `eq_term`).
    pub fn primary_extractor(self, token: &str) -> Option<String> {
        Term::extractor_terms(self.terms_for(token))
            .first()
            .map(|t| format!("eql_v3.{}", t.extractor()))
    }
}

/// Runtime spec built from `(T, Variant)`. The matrix macro consumes
/// this; nothing here is `const` because `sql_domain` is derived via
/// `format!` from `T::PG_TYPE`. The domains live in the `eql_v3` schema,
/// so `sql_domain` is schema-qualified (e.g. `eql_v3.int4_eq`).
#[derive(Debug, Clone)]
pub struct ScalarDomainSpec {
    pub sql_domain: String,
    /// SQL expression yielding the comparable value (default `"payload"`).
    pub column_expr: String,
    pub variant: Variant,
    pub placeholder_payload: &'static str,
    pub eq_extractor: fn(&str) -> String,
    pub ord_extractor: fn(&str) -> String,
    /// The scalar's catalog token (`T::PG_TYPE`, e.g. `"int4"`, `"text"`).
    /// Carried so the delegating capability methods can resolve the variant's
    /// terms from `CATALOG` without the call site re-supplying the token.
    pub token: &'static str,
}

impl ScalarDomainSpec {
    pub fn new<T: ScalarType>(variant: Variant) -> Self {
        Self {
            sql_domain: T::sql_domain(variant),
            column_expr: T::column_expr(),
            variant,
            placeholder_payload: T::placeholder_payload(),
            eq_extractor: T::eq_extractor_expr,
            ord_extractor: T::ord_extractor_expr,
            token: T::PG_TYPE,
        }
    }

    pub fn supports_eq(&self) -> bool {
        self.variant.supports_eq(self.token)
    }

    pub fn supports_ord(&self) -> bool {
        self.variant.supports_ord(self.token)
    }

    /// Top-level JSONB keys the domain CHECK requires (envelope + term keys).
    pub fn payload_required_keys(&self) -> Vec<&'static str> {
        self.variant.payload_required_keys(self.token)
    }

    /// The `eql_v3`-qualified extractor serving `op`, or `None` if unsupported.
    pub fn extractor_for_op(&self, op: &str) -> Option<String> {
        self.variant.extractor_for_op(self.token, op)
    }

    /// A single representative extractor (first term's), independent of any
    /// operator. `None` for `Storage`.
    pub fn primary_extractor(&self) -> Option<String> {
        self.variant.primary_extractor(self.token)
    }

    /// Extractor expression for the variant's discriminating term applied to
    /// `value_expr`. Routes through the per-type `eq_extractor` / `ord_extractor`
    /// seams, so scalars produce `eql_v3.eq_term(...)` / `eql_v3.ord_term(...)`
    /// and a SteVec-entry view produces `eql_v3.eq_term(...)` / `eql_v3.ore_cllw(...)`.
    /// `Storage` has no discriminating term and returns `None`. `Search` (the
    /// combined `_search` domain, which provides ordering) routes through the
    /// ordered extractor like `Ord`/`OrdOre`.
    pub fn extractor_expr(&self, value_expr: &str) -> Option<String> {
        match self.variant {
            Variant::Storage => None,
            Variant::Eq => Some((self.eq_extractor)(value_expr)),
            Variant::Ord | Variant::OrdOre | Variant::Search => {
                Some((self.ord_extractor)(value_expr))
            }
        }
    }
}

/// True when scalar `token` declares any domain carrying the `Bloom` term —
/// i.e. its proxy-generated fixture payload includes a `bf` (bloom-filter) key.
/// Catalog-derived: only `text` (via `_match`/`_search`) declares a Bloom
/// domain, so only text fixtures carry `bf`. Note the proxy always emits `hm`
/// and `ob` for every scalar's fixture regardless of the declared domains, so
/// those two are asserted unconditionally; `bf` is the term that actually
/// tracks the catalog.
pub fn token_has_bloom_term(token: &str) -> bool {
    CATALOG
        .iter()
        .find(|s| s.token == token)
        .map(|s| s.domains.iter().any(|d| d.terms.contains(&Term::Bloom)))
        .unwrap_or(false)
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
        "SELECT ({col})::text FROM {table} WHERE plaintext = {lit}",
        col = T::column_expr(),
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

#[cfg(test)]
mod helper_panic_tests {
    use super::*;

    // The cross-shape arm only ever passes the six comparison operators to these
    // helpers; an unexpected symbol is a harness bug and must fail loudly rather
    // than silently mis-route a row set. These pin that guard.

    #[test]
    fn commute_op_maps_the_six_comparisons() {
        assert_eq!(commute_op("="), "=");
        assert_eq!(commute_op("<>"), "<>");
        assert_eq!(commute_op("<"), ">");
        assert_eq!(commute_op("<="), ">=");
        assert_eq!(commute_op(">"), "<");
        assert_eq!(commute_op(">="), "<=");
    }

    #[test]
    #[should_panic(expected = "commute_op: unsupported operator")]
    fn commute_op_panics_on_unsupported() {
        let _ = commute_op("@>");
    }

    #[test]
    #[should_panic(expected = "expected_forward: unsupported operator")]
    fn expected_forward_panics_on_unsupported() {
        let _ = <i32 as ScalarType>::expected_forward("@>", 0);
    }
}

#[cfg(test)]
mod seam_tests {
    use super::*;

    /// The access-path / extractor seam defaults must reproduce today's scalar
    /// SQL exactly: bare `payload`, `eql_v3.<pg_type><suffix>`, and
    /// `eql_v3.ord_term(...)` for the ordered extractor. A view type that
    /// overrides these (e.g. `JsonbEntryInt4`) is what makes entry reuse
    /// possible — but the defaults are the no-regression contract.
    #[test]
    fn scalar_defaults_reproduce_today_sql() {
        let spec = ScalarDomainSpec::new::<i32>(Variant::Ord);
        assert_eq!(spec.column_expr, "payload");
        assert_eq!(spec.sql_domain, "eql_v3.int4_ord");
        assert_eq!(
            spec.extractor_expr("value"),
            Some("eql_v3.ord_term(value)".to_string()),
        );
        assert_eq!(
            (spec.eq_extractor)("value"),
            "eql_v3.eq_term(value)".to_string(),
        );
        assert_eq!(
            spec.placeholder_payload,
            crate::helpers::PLACEHOLDER_PAYLOAD
        );
    }

    /// The Eq variant routes through the equality extractor; Storage has none.
    #[test]
    fn scalar_eq_and_storage_extractor_routes() {
        let eq = ScalarDomainSpec::new::<i32>(Variant::Eq);
        assert_eq!(eq.sql_domain, "eql_v3.int4_eq");
        assert_eq!(
            eq.extractor_expr("value"),
            Some("eql_v3.eq_term(value)".to_string())
        );

        let storage = ScalarDomainSpec::new::<i32>(Variant::Storage);
        assert_eq!(storage.sql_domain, "eql_v3.int4");
        assert_eq!(storage.extractor_expr("value"), None);
    }
}

#[cfg(test)]
mod catalog_resolution_tests {
    use super::*;

    /// The runtime `(token, suffix)` lookup behind `Variant::terms_for` fails as
    /// a panic. Backstop it: every `(scalar, Variant::suffix())` pair the matrix
    /// could instantiate must resolve in `CATALOG`, and the resolved term set
    /// must agree with the catalog row — a drift between the `Variant` model and
    /// the catalog would otherwise only surface when that specific DB test runs.
    #[test]
    fn every_matrix_variant_pair_resolves_in_catalog() {
        for spec in CATALOG {
            for variant in Variant::ALL {
                let suffix = variant.suffix();
                // A variant is instantiated for a token iff that token declares
                // the suffix; only assert those pairs.
                if let Some(d) = spec.domain_by_suffix(suffix) {
                    assert!(
                        variant.is_declared_for(spec.token),
                        "{}{} declared in CATALOG but is_declared_for is false",
                        spec.token,
                        suffix
                    );
                    assert_eq!(
                        variant.terms_for(spec.token),
                        d.terms,
                        "{}{} term set drift between Variant and CATALOG",
                        spec.token,
                        suffix
                    );
                }
            }
        }
    }
}
