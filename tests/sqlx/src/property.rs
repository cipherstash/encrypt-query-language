//! Shared substrate for the encrypted-domain property tests (CIP-3141).
//!
//! `assert_eq_oracle` / `assert_ord_oracle` take a set of
//! `(plaintext, payload_json)` rows and check SQL operator results against the
//! plaintext oracle over every ordered pair. The fixture suite feeds them rows
//! read from the generated fixtures (real ciphertext); the e2e suite feeds
//! them rows it batch-encrypts from freshly generated plaintexts. The engine is
//! identical for both.
//!
//! The `*_fn_oracle` helpers complement the operator oracles by calling the
//! generated `eql_v3.*` comparison **functions** by name across all three
//! [`Overload`]s, and `assert_extractor_oracle` checks term-extractor identity
//! (`eq_term` == payload `hm`, `ord_term` == payload `ob`). `assert_match_smoke`
//! is the example-based bloom-containment check for the text `_match` domain.
//!
//! Operator evaluation is read-only (`SELECT <a> op <b>`); the fixture suite
//! runs each property under `#[sqlx::test]` (its own migrated scratch DB), while
//! the e2e suite (single-process, feature-gated) uses a shared pool brought up
//! to the migrated state by `ensure_eql_installed`.

use crate::scalar_domains::{ScalarDomainSpec, ScalarType, Variant};
use anyhow::{Context, Result};
use eql_domains::Term;
use sqlx::{PgPool, Row as _};

/// Apply the SQLx migrations (the EQL install in `001_install_eql.sql`, plus the
/// regression-data migrations) to the DB behind `pool`.
///
/// Used by the e2e suite, which connects via `connect_pool()` to the base test
/// database (`DATABASE_URL`) rather than through `#[sqlx::test]`'s migrated
/// scratch DBs — its proptest case loop is synchronous and it batch-encrypts via
/// ZeroKMS, so it owns a long-lived pool. It runs single-process (gated behind
/// `proptest-e2e`, not in the nextest shards), so the shared DB is fine. The
/// fixture suite does NOT use this — it is a `#[sqlx::test]` and gets a migrated
/// DB for free.
///
/// `migrator` is `sqlx::migrate!("./migrations")` — the SAME embedded migration
/// set `#[sqlx::test]` runs, passed in from the test binary so the lib does not
/// embed the (gitignored, generated) migration files. `Migrator::run` is
/// idempotent (records applied versions in `_sqlx_migrations` and skips them)
/// and holds a database-level advisory lock for the duration, so concurrent
/// callers serialise; a developer's already-migrated local DB is a no-op.
pub async fn ensure_eql_installed(pool: &PgPool, migrator: &sqlx::migrate::Migrator) -> Result<()> {
    migrator
        .run(pool)
        .await
        .context("applying EQL migrations to the property-test DB")?;
    Ok(())
}

/// A single fixture row: a plaintext and its EQL payload rendered as a JSON
/// text literal (the `payload::text` form `fetch_fixture_payload` returns, or
/// `serde_json::Value::to_string()` for a freshly encrypted value).
#[derive(Clone)]
pub struct Row<T> {
    pub plaintext: T,
    pub payload_json: String,
}

/// One ordering-oracle result row: `(lt, lte, gt, gte, ord_term_lt)` for a pair.
type OrdRow = (
    Option<bool>,
    Option<bool>,
    Option<bool>,
    Option<bool>,
    Option<bool>,
);

/// Cast a JSON text literal into a domain value: `'<json>'::jsonb::<domain>`.
fn cast(payload_json: &str, domain: &str) -> String {
    format!("'{}'::jsonb::{}", payload_json.replace('\'', "''"), domain)
}

/// Render a JSON text literal as a bare `jsonb` value: `'<json>'::jsonb`. The
/// jsonb-side operand for the `(domain, jsonb)` / `(jsonb, domain)` overloads,
/// where the generated comparison function casts the raw jsonb itself.
fn jsonb(payload_json: &str) -> String {
    format!("'{}'::jsonb", payload_json.replace('\'', "''"))
}

/// Equality oracle: for every ordered pair `(a, b)` in `rows`,
/// `a = b` (SQL, on the `_eq` domain) ⇔ `a.plaintext == b.plaintext`, and
/// `a <> b` is its negation.
pub async fn assert_eq_oracle<T: ScalarType>(pool: &PgPool, rows: &[Row<T>]) -> Result<()> {
    let domain = ScalarDomainSpec::new::<T>(Variant::Eq).sql_domain;
    for a in rows {
        for b in rows {
            let want = a.plaintext == b.plaintext;
            let sql = format!(
                "SELECT ({a_cast}) = ({b_cast}), ({a_cast}) <> ({b_cast})",
                a_cast = cast(&a.payload_json, &domain),
                b_cast = cast(&b.payload_json, &domain),
            );
            let (eq, neq): (Option<bool>, Option<bool>) = sqlx::query_as(&sql)
                .fetch_one(pool)
                .await
                .with_context(|| format!("eq-oracle pair query: {sql}"))?;
            anyhow::ensure!(
                eq == Some(want),
                "eq mismatch on {domain}: plaintext {:?}=={:?} is {want}, SQL `=` returned {eq:?}",
                a.plaintext,
                b.plaintext
            );
            anyhow::ensure!(
                neq == Some(!want),
                "neq mismatch on {domain}: plaintext {:?}!={:?} is {}, SQL `<>` returned {neq:?}",
                a.plaintext,
                b.plaintext,
                !want
            );
        }
    }
    Ok(())
}

/// Ordering oracle: for every ordered pair `(a, b)` and every comparison
/// operator, SQL agrees with the plaintext comparison; additionally
/// `ord_term(a) < ord_term(b)` ⇔ `a.plaintext < b.plaintext`.
/// `variant` is `Variant::Ord` or `Variant::OrdOre` (the two ordered twins).
pub async fn assert_ord_oracle<T: ScalarType>(
    pool: &PgPool,
    variant: Variant,
    rows: &[Row<T>],
) -> Result<()> {
    assert!(
        variant.supports_ord(T::PG_TYPE),
        "assert_ord_oracle needs an ordered variant"
    );
    let domain = ScalarDomainSpec::new::<T>(variant).sql_domain;
    for a in rows {
        for b in rows {
            let a_cast = cast(&a.payload_json, &domain);
            let b_cast = cast(&b.payload_json, &domain);
            let sql = format!(
                "SELECT ({a}) < ({b}), ({a}) <= ({b}), ({a}) > ({b}), ({a}) >= ({b}), \
                        eql_v3.ord_term({a}) < eql_v3.ord_term({b})",
                a = a_cast,
                b = b_cast,
            );
            let (lt, lte, gt, gte, term_lt): OrdRow = sqlx::query_as(&sql)
                .fetch_one(pool)
                .await
                .with_context(|| format!("ord-oracle pair query: {sql}"))?;

            let pa = &a.plaintext;
            let pb = &b.plaintext;
            anyhow::ensure!(lt == Some(pa < pb), "< mismatch on {domain}: {pa:?}<{pb:?}");
            anyhow::ensure!(
                lte == Some(pa <= pb),
                "<= mismatch on {domain}: {pa:?}<={pb:?}"
            );
            anyhow::ensure!(gt == Some(pa > pb), "> mismatch on {domain}: {pa:?}>{pb:?}");
            anyhow::ensure!(
                gte == Some(pa >= pb),
                ">= mismatch on {domain}: {pa:?}>={pb:?}"
            );
            anyhow::ensure!(
                term_lt == Some(pa < pb),
                "ord_term ordering mismatch on {domain}: {pa:?}<{pb:?}"
            );
        }
    }
    Ok(())
}

/// The three generated overloads of every binary comparison / containment
/// function: both operands cast to the domain, or one side left as raw `jsonb`
/// for the function to cast. Exercising all three covers the overload set — in
/// particular the jsonb-cast convenience paths the `_eq` / `_ord` operator
/// oracles never reach (they always cast both operands).
#[derive(Clone, Copy, Debug)]
pub enum Overload {
    DomainDomain,
    DomainJsonb,
    JsonbDomain,
}

impl Overload {
    /// All three overloads, for the per-pair fan-out.
    pub const ALL: [Overload; 3] = [
        Overload::DomainDomain,
        Overload::DomainJsonb,
        Overload::JsonbDomain,
    ];

    /// The `(left, right)` operand SQL expressions for JSON literals `la`/`lb`,
    /// casting the domain side via [`cast`] and leaving the jsonb side bare.
    fn operands(self, la: &str, lb: &str, domain: &str) -> (String, String) {
        match self {
            Overload::DomainDomain => (cast(la, domain), cast(lb, domain)),
            Overload::DomainJsonb => (cast(la, domain), jsonb(lb)),
            Overload::JsonbDomain => (jsonb(la), cast(lb, domain)),
        }
    }
}

/// Shared all-pairs driver for the **named-function** oracles. For every
/// ordered pair `(a, b)` in `rows`, emit a single `SELECT` whose columns are
/// `eql_v3.<func>(...)` for every `func` in `funcs` across every
/// [`Overload`] (a 6-column query for the two eq functions, 12 for the four
/// ord functions), then assert each column against `expected(a, b, func)`.
/// Collapsing each pair to one round trip keeps the only cost this family adds
/// (`SELECT` volume) in check; ZeroKMS cost is unchanged (the rows are already
/// encrypted). Complements — does not replace — the operator oracles.
async fn assert_named_fns<T, F>(
    pool: &PgPool,
    domain: &str,
    rows: &[Row<T>],
    funcs: &[&str],
    expected: F,
) -> Result<()>
where
    T: ScalarType,
    F: Fn(&T, &T, &str) -> bool,
{
    for a in rows {
        for b in rows {
            // One column per (overload, func); `meta` records the expected bool
            // alongside its label so a mismatch reports which overload/func failed.
            let mut exprs: Vec<String> = Vec::new();
            let mut meta: Vec<(Overload, &str, bool)> = Vec::new();
            for &overload in &Overload::ALL {
                let (l, r) = overload.operands(&a.payload_json, &b.payload_json, domain);
                for &func in funcs {
                    exprs.push(format!("eql_v3_internal.{func}({l}, {r})"));
                    meta.push((overload, func, expected(&a.plaintext, &b.plaintext, func)));
                }
            }
            let sql = format!("SELECT {}", exprs.join(", "));
            let row = sqlx::query(&sql)
                .fetch_one(pool)
                .await
                .with_context(|| format!("fn-oracle pair query: {sql}"))?;
            for (i, (overload, func, want)) in meta.iter().enumerate() {
                let got: Option<bool> = row
                    .try_get(i)
                    .with_context(|| format!("reading column {i} of: {sql}"))?;
                anyhow::ensure!(
                    got == Some(*want),
                    "fn eql_v3_internal.{func} on {domain} ({overload:?}): plaintext {:?} vs {:?} \
                     expected {want}, SQL returned {got:?}",
                    a.plaintext,
                    b.plaintext,
                );
            }
        }
    }
    Ok(())
}

/// Equality **function** oracle: `eql_v3.eq` / `eql_v3.neq` across all three
/// overloads agree with the plaintext (in)equality, for every ordered pair.
/// `variant` is the eq-capable domain to run on (`Eq` normally; `Search` for
/// text's combined `_search` domain). Complements `assert_eq_oracle`'s operator
/// checks by calling the named functions directly across the overload set.
pub async fn assert_eq_fn_oracle<T: ScalarType>(
    pool: &PgPool,
    variant: Variant,
    rows: &[Row<T>],
) -> Result<()> {
    let spec = ScalarDomainSpec::new::<T>(variant);
    anyhow::ensure!(
        spec.supports_eq(),
        "assert_eq_fn_oracle needs an eq-capable variant, got {variant:?} for {}",
        T::PG_TYPE
    );
    let domain = spec.sql_domain;
    assert_named_fns(
        pool,
        &domain,
        rows,
        &["eq", "neq"],
        |a, b, func| match func {
            "eq" => a == b,
            "neq" => a != b,
            other => unreachable!("assert_eq_fn_oracle func {other}"),
        },
    )
    .await
}

/// Ordering **function** oracle: `eql_v3.lt` / `lte` / `gt` / `gte` across all
/// three overloads agree with the plaintext ordering, for every ordered pair.
/// `variant` is an ordered domain (`Ord` / `OrdOre`, or `Search` for text).
pub async fn assert_ord_fn_oracle<T: ScalarType>(
    pool: &PgPool,
    variant: Variant,
    rows: &[Row<T>],
) -> Result<()> {
    let spec = ScalarDomainSpec::new::<T>(variant);
    anyhow::ensure!(
        spec.supports_ord(),
        "assert_ord_fn_oracle needs an ordered variant, got {variant:?} for {}",
        T::PG_TYPE
    );
    let domain = spec.sql_domain;
    assert_named_fns(
        pool,
        &domain,
        rows,
        &["lt", "lte", "gt", "gte"],
        |a, b, func| match func {
            "lt" => a < b,
            "lte" => a <= b,
            "gt" => a > b,
            "gte" => a >= b,
            other => unreachable!("assert_ord_fn_oracle func {other}"),
        },
    )
    .await
}

/// Term-extractor **identity** oracle: the generated extractor returns the exact
/// term stored in the payload. For `variant`'s domain, drives whichever
/// extractors its catalog terms declare:
/// - an `Hm` term ⇒ `eql_v3.eq_term(<dom>)::text` equals the payload's `hm`
///   string (`eql_v3_internal.hmac_256` is a domain over `text`, so the hex comes back
///   verbatim — no `encode`/`decode`).
/// - an `Ore` term ⇒ the `ord_term` composite, re-rendered to a hex-block array
///   (`encode((t).bytes,'hex')` per block, ordinal order), equals the payload's
///   `ob` array.
///
/// `text_ord`/`text_search` carry both terms, so both identities are checked on
/// the one domain. The `hm`/`ob` values are read straight out of `payload_json`
/// with `serde_json` — no typed struct.
pub async fn assert_extractor_oracle<T: ScalarType>(
    pool: &PgPool,
    variant: Variant,
    rows: &[Row<T>],
) -> Result<()> {
    let spec = ScalarDomainSpec::new::<T>(variant);
    let domain = &spec.sql_domain;
    let terms = variant.terms_for(T::PG_TYPE);
    let check_eq = terms.contains(&Term::Hm);
    let check_ord = terms.iter().any(|t| t.provides_ordering());
    anyhow::ensure!(
        check_eq || check_ord,
        "assert_extractor_oracle needs an Hm or Ore term, got {variant:?} for {}",
        T::PG_TYPE
    );
    for row in rows {
        let value = cast(&row.payload_json, domain);
        let payload: serde_json::Value = serde_json::from_str(&row.payload_json)
            .with_context(|| format!("parsing payload_json: {}", row.payload_json))?;

        if check_eq {
            let hm = payload
                .get("hm")
                .and_then(|v| v.as_str())
                .with_context(|| format!("payload missing string `hm`: {}", row.payload_json))?;
            let sql = format!("SELECT eql_v3.eq_term({value})::text");
            let got: Option<String> = sqlx::query_scalar(&sql)
                .fetch_one(pool)
                .await
                .with_context(|| format!("eq_term identity query: {sql}"))?;
            anyhow::ensure!(
                got.as_deref() == Some(hm),
                "eq_term identity on {domain}: extractor returned {got:?}, payload hm={hm:?}",
            );
        }

        if check_ord {
            let ob: Vec<String> = payload
                .get("ob")
                .and_then(|v| v.as_array())
                .with_context(|| format!("payload missing array `ob`: {}", row.payload_json))?
                .iter()
                .map(|v| v.as_str().map(str::to_owned))
                .collect::<Option<Vec<String>>>()
                .with_context(|| {
                    format!("`ob` is not an array of strings: {}", row.payload_json)
                })?;
            // Re-render the ORE composite to its stored hex-block array
            // (lower-case `encode(...,'hex')`, in array-subscript order, which is
            // the order `jsonb_array_to_ore_block_256` built `terms` from the
            // payload's `ob`). `eql_v3_internal.ore_block_256_term` is a single-field
            // composite `(bytes bytea)`; a `WITH ORDINALITY AS u(t, n)` column-
            // alias list expands that single field to `bytea` (so `(t).bytes`
            // fails to resolve), so index `terms` with `generate_subscripts`
            // instead — that keeps each element a composite and gives explicit
            // ordering. `ord_term` is evaluated once.
            let sql = format!(
                "SELECT array(\
                     SELECT encode((ore.terms[i]).bytes, 'hex') \
                     FROM generate_subscripts(ore.terms, 1) AS i \
                     ORDER BY i) \
                 FROM (SELECT (eql_v3.ord_term({value})).terms AS terms) ore"
            );
            let got: Vec<String> = sqlx::query_scalar(&sql)
                .fetch_one(pool)
                .await
                .with_context(|| format!("ord_term identity query: {sql}"))?;
            anyhow::ensure!(
                got == ob,
                "ord_term identity on {domain}: extractor returned {got:?}, payload ob={ob:?}",
            );
        }
    }
    Ok(())
}

/// Bloom-filter **match** smoke (text only, example-based). Bloom containment
/// admits false positives and the plaintext oracle is substring, not equality,
/// so this is curated rather than a random property: three fixtures with known
/// n-gram relationships (`haystack` ⊇ `needle`, `disjoint` shares none). Asserts
/// `eql_v3.contains` / `contained_by` respect **left-contains-right** `@>` and
/// that `match_term` yields a non-empty `bf` array. Operands are the payload
/// JSON literals cast to `domain` (`eql_v3.text_match`).
pub async fn assert_match_smoke(
    pool: &PgPool,
    domain: &str,
    haystack_json: &str,
    needle_json: &str,
    disjoint_json: &str,
) -> Result<()> {
    let haystack = cast(haystack_json, domain);
    let needle = cast(needle_json, domain);
    let disjoint = cast(disjoint_json, domain);

    // `contains(a, b)` = `match_term(a) @> match_term(b)` (a's bits ⊇ b's);
    // `contained_by` is its mirror. Each row: (label, sql, expected).
    let cases: [(&str, String, bool); 6] = [
        (
            "contains(haystack, needle)",
            format!("eql_v3_internal.contains({haystack}, {needle})"),
            true,
        ),
        (
            "contains(needle, haystack)",
            format!("eql_v3_internal.contains({needle}, {haystack})"),
            false,
        ),
        (
            "contains(haystack, disjoint)",
            format!("eql_v3_internal.contains({haystack}, {disjoint})"),
            false,
        ),
        (
            "contained_by(needle, haystack)",
            format!("eql_v3_internal.contained_by({needle}, {haystack})"),
            true,
        ),
        (
            "contained_by(haystack, needle)",
            format!("eql_v3_internal.contained_by({haystack}, {needle})"),
            false,
        ),
        (
            "contained_by(disjoint, haystack)",
            format!("eql_v3_internal.contained_by({disjoint}, {haystack})"),
            false,
        ),
    ];
    let sql = format!(
        "SELECT {}",
        cases
            .iter()
            .map(|(_, expr, _)| expr.clone())
            .collect::<Vec<_>>()
            .join(", ")
    );
    let row = sqlx::query(&sql)
        .fetch_one(pool)
        .await
        .with_context(|| format!("match-smoke containment query: {sql}"))?;
    for (i, (label, _, want)) in cases.iter().enumerate() {
        let got: Option<bool> = row
            .try_get(i)
            .with_context(|| format!("reading column {i} of: {sql}"))?;
        anyhow::ensure!(
            got == Some(*want),
            "match smoke {label} on {domain}: expected {want}, SQL returned {got:?}",
        );
    }

    // Each fixture's `match_term` must yield a non-empty bloom (`bf`) array.
    for (label, value) in [
        ("haystack", &haystack),
        ("needle", &needle),
        ("disjoint", &disjoint),
    ] {
        let sql = format!("SELECT eql_v3.match_term({value})::smallint[]");
        let bf: Vec<i16> = sqlx::query_scalar(&sql)
            .fetch_one(pool)
            .await
            .with_context(|| format!("match_term query for {label}: {sql}"))?;
        anyhow::ensure!(
            !bf.is_empty(),
            "match_term({label}) on {domain} returned an empty bloom array",
        );
    }
    Ok(())
}

/// Replace any `user:password@` userinfo in a connection URL with `***@` so it
/// is safe to put in error context / logs (the password never appears).
fn redact_url(url: &str) -> String {
    match url.split_once("://") {
        Some((scheme, rest)) => match rest.rsplit_once('@') {
            Some((_userinfo, host)) => format!("{scheme}://***@{host}"),
            None => format!("{scheme}://{rest}"),
        },
        None => "<redacted>".to_string(),
    }
}

/// Connect to the shared SQLx test database. Reads `DATABASE_URL`, falling back
/// to the documented local default (`localhost:7432`, cipherstash/password).
/// Used by the proptest suites, which cannot use `#[sqlx::test]`'s injected pool
/// from a (sync) `proptest!` body.
pub async fn connect_pool() -> Result<PgPool> {
    let url = std::env::var("DATABASE_URL").unwrap_or_else(|_| {
        "postgres://cipherstash:password@localhost:7432/cipherstash".to_string()
    });
    PgPool::connect(&url)
        .await
        // Redact userinfo so a connection failure never logs the password.
        .with_context(|| format!("connecting property-test pool to {}", redact_url(&url)))
}
