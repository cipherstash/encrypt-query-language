//! Type-generic substrate for the encrypted-scalar-domain test matrix.
//!
//! Adding a new encrypted scalar type (e.g. `i64` for int8, `f64` for
//! float8) is one `<T> => <R>` line in the `scalar_harness!` list
//! (`scalar_harness.rs`) plus an `EqlPlaintext` impl and a catalog row.
//! The `impl ScalarType` below is generated from that list. Everything
//! else — the four `eql_v2_<T>{,_eq,_ord,_ord_ore}` domains, per-domain
//! payload shapes, supported operators, index extractor expressions,
//! ground-truth result sets — is derived from `T::PG_TYPE`,
//! `T::FIXTURE_VALUES`, and the `Variant` enum.

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

    /// Distinct plaintext values present in the fixture. Order doesn't
    /// matter — `expected_forward` sorts before returning.
    ///
    /// For types driven by `ordered_numeric_matrix!`, the fixture MUST
    /// include `MIN`, `MAX`, and zero (`Default::default()`): the matrix
    /// uses those three as comparison pivots and fetches each one's
    /// ciphertext via `fetch_fixture_payload`, which fails loudly if the
    /// row is absent.
    const FIXTURE_VALUES: &'static [Self];

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
        let mut values: Vec<Self> = Self::FIXTURE_VALUES
            .iter()
            .copied()
            .filter(|v| predicate(*v, pivot))
            .collect();
        values.sort();
        values
    }
}

// The per-type `impl ScalarType` blocks (one per scalar, each carrying its
// `PG_TYPE` token string and `FIXTURE_VALUES = eql_scalars::<TOKEN>_VALUES`)
// are generated from the single harness list in `scalar_harness.rs`. To add a
// type, add a `token => rust_type` line there — not an impl here.
crate::scalar_harness!(scalar_type_impls);

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
