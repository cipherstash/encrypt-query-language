//! Shared substrate for the encrypted-domain property tests (CIP-3141).
//!
//! `assert_eq_oracle` / `assert_ord_oracle` take a corpus of
//! `(plaintext, payload_json)` rows and check SQL operator results against the
//! plaintext oracle over every ordered pair. Tier A feeds them rows read from
//! the live-encrypted fixture; Tier B feeds them rows it batch-encrypts from
//! freshly generated plaintexts. The engine is identical for both.
//!
//! Operator evaluation is read-only (`SELECT <a> op <b>`), so these helpers take
//! a `&PgPool` and need no per-test schema isolation.

use crate::scalar_domains::{ScalarDomainSpec, ScalarType, Variant};
use anyhow::{Context, Result};
use sqlx::PgPool;

/// A single corpus entry: a plaintext and its EQL payload rendered as a JSON
/// text literal (the `payload::text` form `fetch_fixture_payload` returns, or
/// `serde_json::Value::to_string()` for a freshly encrypted value).
pub struct Row<T> {
    pub plaintext: T,
    pub payload_json: String,
}

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
        variant.supports_ord(),
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
            let (lt, lte, gt, gte, term_lt): (
                Option<bool>,
                Option<bool>,
                Option<bool>,
                Option<bool>,
                Option<bool>,
            ) = sqlx::query_as(&sql)
                .fetch_one(pool)
                .await
                .with_context(|| format!("ord-oracle pair query: {sql}"))?;

            let pa = &a.plaintext;
            let pb = &b.plaintext;
            anyhow::ensure!(lt == Some(pa < pb), "< mismatch on {domain}: {pa:?}<{pb:?}");
            anyhow::ensure!(lte == Some(pa <= pb), "<= mismatch on {domain}: {pa:?}<={pb:?}");
            anyhow::ensure!(gt == Some(pa > pb), "> mismatch on {domain}: {pa:?}>{pb:?}");
            anyhow::ensure!(gte == Some(pa >= pb), ">= mismatch on {domain}: {pa:?}>={pb:?}");
            anyhow::ensure!(
                term_lt == Some(pa < pb),
                "ord_term ordering mismatch on {domain}: {pa:?}<{pb:?}"
            );
        }
    }
    Ok(())
}

/// Connect to the shared SQLx test database. Reads `DATABASE_URL`, falling back
/// to the documented local default (`localhost:7432`, cipherstash/password).
/// Used by the proptest tiers, which cannot use `#[sqlx::test]`'s injected pool
/// from a (sync) `proptest!` body.
pub async fn connect_pool() -> Result<PgPool> {
    let url = std::env::var("DATABASE_URL").unwrap_or_else(|_| {
        "postgres://cipherstash:password@localhost:7432/cipherstash".to_string()
    });
    PgPool::connect(&url)
        .await
        .with_context(|| format!("connecting property-test pool to {url}"))
}
