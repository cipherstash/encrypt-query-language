//! Shared substrate for the encrypted-domain property tests (CIP-3141).
//!
//! `assert_eq_oracle` / `assert_ord_oracle` take a corpus of
//! `(plaintext, payload_json)` rows and check SQL operator results against the
//! plaintext oracle over every ordered pair. The fixture suite feeds them rows
//! read from the committed fixture corpus (real ciphertext); the e2e suite feeds
//! them rows it batch-encrypts from freshly generated plaintexts. The engine is
//! identical for both.
//!
//! Operator evaluation is read-only (`SELECT <a> op <b>`); the fixture suite
//! runs each property under `#[sqlx::test]` (its own migrated scratch DB), while
//! the e2e suite (single-process, feature-gated) uses a shared pool brought up
//! to the migrated state by `ensure_eql_installed`.

use crate::scalar_domains::{ScalarDomainSpec, ScalarType, Variant};
use anyhow::{Context, Result};
use sqlx::PgPool;

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

/// A single corpus entry: a plaintext and its EQL payload rendered as a JSON
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
