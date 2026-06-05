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
    Copy
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
    /// For types driven by `ordered_numeric_matrix!`, the values MUST
    /// include the three pivots (`min_pivot()`, `max_pivot()`, and zero
    /// `Default::default()`): the matrix uses those as comparison pivots and
    /// fetches each one's ciphertext via `fetch_fixture_payload`, which fails
    /// loudly if the row is absent.
    fn fixture_values() -> &'static [Self];

    /// The low comparison pivot swept by the correctness / cross-shape arms.
    /// Integer scalars return `Self::MIN`; temporal scalars return an explicit
    /// sentinel (e.g. `1900-01-01`). A trait method rather than `Self::MIN`
    /// because `chrono::DateTime<Utc>` exposes `MAX_UTC`, not an inherent
    /// `::MAX` const. The pivot must be present verbatim in `fixture_values()`.
    fn min_pivot() -> Self;

    /// The high comparison pivot. Integer scalars return `Self::MAX`; temporal
    /// scalars return an explicit sentinel (e.g. `2099-12-31`). Must be present
    /// verbatim in `fixture_values()`.
    fn max_pivot() -> Self;

    /// `fixtures.eql_v2_<pg_type>`.
    fn fixture_table_name() -> String {
        format!("fixtures.eql_v2_{}", Self::PG_TYPE)
    }

    /// SQL-literal rendering via `Display`. Override for types whose
    /// `Display` form isn't a valid SQL literal (e.g. strings, dates).
    fn to_sql_literal(value: Self) -> String {
        value.to_string()
    }

    /// Ground-truth result set for `WHERE col op pivot`. Default works
    /// for any `Ord` scalar; override only for non-orderable types.
    fn expected_forward(op: &str, pivot: Self) -> Vec<Self> {
        let predicate: fn(Self, Self) -> bool = match op {
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
            .copied()
            .filter(|v| predicate(*v, pivot))
            .collect();
        values.sort();
        values
    }
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
            fn min_pivot() -> $ty { $min }
            fn max_pivot() -> $ty { $max }
            fn to_sql_literal(value: $ty) -> String {
                let f: fn(&$ty) -> String = $sql_lit;
                f(&value)
            }
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
                assert!(vals.contains(&<$ty as ScalarType>::min_pivot()), "min pivot missing");
                assert!(vals.contains(&<$ty as ScalarType>::max_pivot()), "max pivot missing");
                // The matrix sweeps a zero pivot (`Default::default()`) on every
                // ordered/eq-only suite and fetches its ciphertext via
                // `fetch_fixture_payload`, so it must be present verbatim too.
                assert!(vals.contains(&<$ty as Default>::default()), "zero/default pivot missing");
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
        lit = T::to_sql_literal(plaintext),
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
