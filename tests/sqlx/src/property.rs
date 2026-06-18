//! Shared substrate for the encrypted-domain property tests (CIP-3141).
//!
//! `assert_eq_oracle` / `assert_ord_oracle` take a corpus of
//! `(plaintext, payload_json)` rows and check SQL operator results against the
//! plaintext oracle over every ordered pair. The fixture suite feeds them rows
//! read from the committed fixture corpus (real ciphertext); the e2e suite feeds
//! them rows it batch-encrypts from freshly generated plaintexts. The engine is
//! identical for both.
//!
//! Operator evaluation is read-only (`SELECT <a> op <b>`), so these helpers take
//! a `&PgPool` and need no per-test schema isolation.

use crate::scalar_domains::{ScalarDomainSpec, ScalarType, Variant};
use anyhow::{Context, Result};
use sqlx::PgPool;
use std::collections::HashSet;
use std::sync::OnceLock;
use tokio::sync::Mutex;

/// Per-process record of which fixture corpora have been materialised into the
/// shared connection's DB, so concurrent property-test threads load each
/// `fixtures.eql_v2_<T>` table exactly once.
static FIXTURE_LOADED: OnceLock<Mutex<HashSet<&'static str>>> = OnceLock::new();

/// Per-process guard ensuring the EQL surface (the `eql_v3` schema the oracle
/// queries cast to) is installed into the connected DB exactly once.
static EQL_INSTALLED: OnceLock<Mutex<bool>> = OnceLock::new();

/// Ensure the EQL surface (the `eql_v3` schema + scalar domains/operators the
/// oracle queries cast to) is present in the DB behind `pool`.
///
/// The property suites connect via `connect_pool()` to the base test database
/// (`DATABASE_URL`), NOT through `#[sqlx::test]`'s migrated per-test scratch
/// DBs. In a CI shard that base DB is a stock Postgres with no EQL installed —
/// only the `build-archive` job ran `sqlx migrate run`, and against a different
/// Postgres — so every `::eql_v3.<T>_eq` cast would raise
/// `schema "eql_v3" does not exist`. This installs the surface on demand so the
/// suites are self-sufficient regardless of where they run (CI shard, local,
/// fork), instead of silently depending on a pre-installed base DB.
///
/// `install_sql` is the EQL installer (`migrations/001_install_eql.sql`),
/// `include_str!`-embedded into the test binary at compile time (see
/// `property/mod.rs`) so it travels inside the prebuilt nextest archive — the
/// same mechanism the fixture corpus uses. A process-wide async mutex
/// guarantees exactly-once execution across the parallel proptest threads, and
/// a presence check (`eql_v3.int4_eq`) skips the install when the DB already
/// has the surface (a developer's pre-installed local DB), where re-running the
/// non-idempotent installer would error on duplicate objects.
pub async fn ensure_eql_installed(pool: &PgPool, install_sql: &str) -> Result<()> {
    let guard = EQL_INSTALLED.get_or_init(|| Mutex::new(false));
    let mut installed = guard.lock().await;
    if *installed {
        return Ok(());
    }
    // Presence check: skip the installer if the surface is already there. int4
    // is the reference scalar type and is always part of the surface.
    let present: bool = sqlx::query_scalar("SELECT to_regtype('eql_v3.int4_eq') IS NOT NULL")
        .fetch_one(pool)
        .await
        .context("probing for an existing eql_v3 install")?;
    if !present {
        sqlx::raw_sql(install_sql)
            .execute(pool)
            .await
            .context("installing the EQL surface into the property-test DB")?;
    }
    *installed = true;
    Ok(())
}

/// Materialise the committed fixture corpus (real ciphertext) for `T` into the connected DB.
///
/// The fixture `.sql` files (`tests/sqlx/fixtures/eql_v2_<T>.sql`) are normally
/// loaded only into `#[sqlx::test]`'s ephemeral per-test databases. The property
/// suites connect to the shared test DB directly (they cannot use
/// `#[sqlx::test]`'s injected pool from a sync `proptest!` body), so the corpus
/// is not present there. This loads it on demand: the script is self-contained
/// and idempotent (`CREATE SCHEMA IF NOT EXISTS` / `DROP TABLE IF EXISTS` /
/// `CREATE` / `INSERT`), and a process-wide async mutex guarantees exactly-once
/// execution per type across the parallel test threads (each driving its own
/// runtime).
///
/// `script` is the fixture SQL, passed in by the caller. It is `include_str!`-
/// embedded into the test binary at compile time (see `fixture_oracle.rs`) so it
/// travels inside the prebuilt nextest archive that CI shards run from — those
/// shards do a fresh checkout where the gitignored `.sql` files are absent, so a
/// runtime `std::fs` read would fail there.
pub async fn ensure_fixture_loaded<T: ScalarType>(pool: &PgPool, script: &str) -> Result<()> {
    let guard = FIXTURE_LOADED.get_or_init(|| Mutex::new(HashSet::new()));
    let mut loaded = guard.lock().await;
    if loaded.contains(T::PG_TYPE) {
        return Ok(());
    }
    sqlx::raw_sql(script)
        .execute(pool)
        .await
        .with_context(|| format!("loading fixture corpus for {} into shared DB", T::PG_TYPE))?;
    loaded.insert(T::PG_TYPE);
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
