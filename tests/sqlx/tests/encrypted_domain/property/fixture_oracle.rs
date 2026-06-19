//! fixture suite (CIP-3141): property tests over the real, committed fixture corpus.
//!
//! The fixture table `fixtures.eql_v2_<T>` carries `(plaintext, payload)` rows
//! encrypted by cipherstash-client during `test:sqlx:prep`. proptest selects a
//! sub-multiset of those rows (with repeats, so the equality diagonal includes
//! identical-ciphertext self-pairs) and the shared oracle engine checks every
//! pair. No new encryption — runs whenever the fixtures are present.
//!
//! Each test uses `#[sqlx::test]`, so it gets its OWN migrated scratch database
//! (the `eql_v3` surface is already installed by the embedded migrations) and
//! loads the fixture corpus into that isolated DB. This is what every other test
//! in the suite does; it avoids the shared-base-DB races that bite under
//! nextest's process-per-test parallelism (concurrent `CREATE SCHEMA`, and a
//! later test re-`DROP`/`CREATE`-ing a fixture table out from under an earlier
//! test's in-flight reads). The only wrinkle is that proptest's case loop is
//! synchronous; `drive_proptest` bridges it to the async injected pool.
//!
//! Generic over `ScalarType`; instantiated per type at the bottom.

use anyhow::{Context, Result};
use eql_tests::property::{assert_eq_oracle, assert_ord_oracle, Row};
use eql_tests::scalar_domains::{ScalarType, Variant};
use proptest::prelude::*;
use proptest::test_runner::{Config, TestCaseError, TestRunner};
use sqlx::PgPool;
use std::sync::Arc;

/// The fixture corpus SQL for `T`, `include_str!`-embedded into this test binary
/// at compile time (one arm per catalog token). Embedding rather than reading
/// from disk at runtime is what lets the prebuilt nextest archive carry the
/// corpus into CI shards, which do a fresh checkout where the gitignored
/// `tests/sqlx/fixtures/eql_v2_<T>.sql` files are absent. The path resolves
/// against the `eql_tests` crate root (`tests/sqlx`). Mirrors the loud catch-all
/// of the `generate_for_token` fixture dispatch.
fn embedded_fixture_sql<T: ScalarType>() -> &'static str {
    match T::PG_TYPE {
        "int4" => include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/fixtures/eql_v2_int4.sql"
        )),
        "int2" => include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/fixtures/eql_v2_int2.sql"
        )),
        "int8" => include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/fixtures/eql_v2_int8.sql"
        )),
        "date" => include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/fixtures/eql_v2_date.sql"
        )),
        "text" => include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/fixtures/eql_v2_text.sql"
        )),
        "timestamptz" => {
            include_str!(concat!(
                env!("CARGO_MANIFEST_DIR"),
                "/fixtures/eql_v2_timestamptz.sql"
            ))
        }
        "numeric" => include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/fixtures/eql_v2_numeric.sql"
        )),
        other => panic!(
            "no embedded fixture for catalog token '{other}'; \
             add an include_str! arm in fixture_oracle.rs"
        ),
    }
}

/// Load the committed fixture corpus for `T` into this test's isolated scratch
/// DB and read every `(plaintext, payload::text)` row, in id order. The corpus
/// SQL is self-contained (`CREATE SCHEMA IF NOT EXISTS fixtures` / `CREATE` /
/// `INSERT`); since the DB is private to this test there is no concurrency on it.
async fn load_rows<T: ScalarType>(pool: &PgPool) -> Result<Arc<Vec<Row<T>>>> {
    sqlx::raw_sql(embedded_fixture_sql::<T>())
        .execute(pool)
        .await
        .with_context(|| format!("loading fixture corpus for {}", T::PG_TYPE))?;
    let sql = format!(
        "SELECT plaintext, payload::text FROM {} ORDER BY id",
        T::fixture_table_name()
    );
    let raw: Vec<(T, String)> = sqlx::query_as(&sql).fetch_all(pool).await?;
    let rows: Vec<Row<T>> = raw
        .into_iter()
        .map(|(plaintext, payload_json)| Row {
            plaintext,
            payload_json,
        })
        .collect();
    anyhow::ensure!(
        !rows.is_empty(),
        "fixture {} is empty",
        T::fixture_table_name()
    );
    Ok(Arc::new(rows))
}

/// Build a corpus by sampling indices (with repeats) into the loaded fixtures.
/// `idxs` are already bounded to `0..all.len()` by the proptest strategy.
fn pick<T: Clone>(all: &[Row<T>], idxs: &[usize]) -> Vec<Row<T>> {
    idxs.iter().map(|&i| all[i].clone()).collect()
}

/// Bridge proptest's synchronous case loop to async oracle work running on the
/// `#[sqlx::test]` runtime and its injected `pool`.
///
/// `TestRunner::run` is synchronous and cannot `.await`; spinning up a nested
/// runtime inside the test's runtime is unsound, and the pool is bound to the
/// test's runtime so it cannot be driven from another. So the runner lives on a
/// dedicated OS thread that ships each generated case to the async side over a
/// channel and blocks for the verdict; the async side (this future, on the test
/// runtime) runs `body` against the pool and replies. The pool never crosses
/// runtimes, and it works under any runtime flavour. Shrinking is preserved:
/// proptest re-invokes the closure with shrunk inputs, which flow through the
/// same channel.
async fn drive_proptest<V, S, F, Fut>(config: Config, strategy: S, body: F) -> Result<()>
where
    V: std::fmt::Debug + Send + 'static,
    S: Strategy<Value = V> + Send + 'static,
    F: Fn(V) -> Fut,
    Fut: std::future::Future<Output = Result<()>>,
{
    use tokio::sync::{mpsc, oneshot};
    type Verdict = std::result::Result<(), String>;
    let (case_tx, mut case_rx) = mpsc::unbounded_channel::<(V, oneshot::Sender<Verdict>)>();

    // proptest drives cases on its own thread; `blocking_recv` is safe there
    // because it is not a runtime worker.
    let runner = std::thread::spawn(move || -> std::result::Result<(), String> {
        let mut runner = TestRunner::new(config);
        runner
            .run(&strategy, |value| {
                let (res_tx, res_rx) = oneshot::channel();
                case_tx
                    .send((value, res_tx))
                    .map_err(|_| TestCaseError::fail("oracle bridge: async side hung up"))?;
                match res_rx.blocking_recv() {
                    Ok(Ok(())) => Ok(()),
                    Ok(Err(msg)) => Err(TestCaseError::fail(msg)),
                    Err(_) => Err(TestCaseError::fail("oracle bridge: verdict dropped")),
                }
            })
            .map_err(|e| format!("{e}"))
    });

    // Service each case on the test runtime, where the pool lives. `{e:#}`
    // preserves anyhow's full cause chain (the real Postgres error).
    while let Some((value, res_tx)) = case_rx.recv().await {
        let verdict = body(value).await.map_err(|e| format!("{e:#}"));
        let _ = res_tx.send(verdict);
    }

    match runner.join() {
        Ok(Ok(())) => Ok(()),
        Ok(Err(msg)) => Err(anyhow::anyhow!("fixture property failed: {msg}")),
        Err(_) => Err(anyhow::anyhow!("proptest runner thread panicked")),
    }
}

/// Strategy + config shared by the eq and ord runs: `cases` multisets of
/// `2..=12` indices into the fixtures (repeats wanted so the equality diagonal
/// includes identical-ciphertext self-pairs). No regression file — these sample
/// committed fixtures, nothing to persist/replay.
fn config_and_strategy(cases: u32, n: usize) -> (Config, impl Strategy<Value = Vec<usize>>) {
    let config = Config {
        cases,
        failure_persistence: None,
        ..Config::default()
    };
    (config, prop::collection::vec(0..n, 2..13))
}

/// Equality-oracle property over `T`'s fixture corpus.
async fn run_eq_oracle<T: ScalarType>(pool: PgPool, cases: u32) -> Result<()> {
    let rows = load_rows::<T>(&pool).await?;
    let (config, strategy) = config_and_strategy(cases, rows.len());
    drive_proptest(config, strategy, move |idxs| {
        let pool = pool.clone();
        let rows = rows.clone();
        async move { assert_eq_oracle::<T>(&pool, &pick(&rows, &idxs)).await }
    })
    .await
}

/// Ordering-oracle property over `T`'s fixture corpus (both ordered twins).
async fn run_ord_oracle<T: ScalarType>(pool: PgPool, cases: u32) -> Result<()> {
    let rows = load_rows::<T>(&pool).await?;
    let (config, strategy) = config_and_strategy(cases, rows.len());
    drive_proptest(config, strategy, move |idxs| {
        let pool = pool.clone();
        let rows = rows.clone();
        async move {
            let corpus = pick(&rows, &idxs);
            assert_ord_oracle::<T>(&pool, Variant::Ord, &corpus).await?;
            assert_ord_oracle::<T>(&pool, Variant::OrdOre, &corpus).await
        }
    })
    .await
}

/// All fixtured scalars run the same number of proptest cases — the fixture
/// suite does no new encryption, so there is no reason for int4 to be
/// privileged. Raise here (one place) if a regression ever needs more cases.
const FIXTURE_ORACLE_CASES: u32 = 32;

macro_rules! fixture_oracle_suite {
    ($modname:ident, $ty:ty, ordered) => {
        mod $modname {
            use super::*;
            #[sqlx::test]
            async fn eq_oracle(pool: PgPool) -> Result<()> {
                run_eq_oracle::<$ty>(pool, FIXTURE_ORACLE_CASES).await
            }
            #[sqlx::test]
            async fn ord_oracle(pool: PgPool) -> Result<()> {
                run_ord_oracle::<$ty>(pool, FIXTURE_ORACLE_CASES).await
            }
        }
    };
    ($modname:ident, $ty:ty, eq_only) => {
        mod $modname {
            use super::*;
            #[sqlx::test]
            async fn eq_oracle(pool: PgPool) -> Result<()> {
                run_eq_oracle::<$ty>(pool, FIXTURE_ORACLE_CASES).await
            }
        }
    };
}

fixture_oracle_suite!(int4, i32, ordered);
fixture_oracle_suite!(int2, i16, ordered);
fixture_oracle_suite!(int8, i64, ordered);
fixture_oracle_suite!(date, chrono::NaiveDate, ordered);
fixture_oracle_suite!(timestamptz, chrono::DateTime<chrono::Utc>, ordered);
fixture_oracle_suite!(numeric, rust_decimal::Decimal, ordered);
fixture_oracle_suite!(text, String, ordered);
