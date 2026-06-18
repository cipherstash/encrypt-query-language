//! fixture suite (CIP-3141): property tests over the real, committed fixture corpus.
//!
//! The fixture table `fixtures.eql_v2_<T>` carries `(plaintext, payload)` rows
//! encrypted by cipherstash-client during `test:sqlx:prep`. proptest selects a
//! sub-multiset of those rows (with repeats, so the equality diagonal includes
//! identical-ciphertext self-pairs) and the shared oracle engine checks every
//! pair. No new encryption — runs whenever the fixtures are present.
//!
//! Generic over `ScalarType`; instantiated per type at the bottom.

use anyhow::Result;
use eql_tests::property::{
    assert_eq_oracle, assert_ord_oracle, connect_pool, ensure_eql_installed, ensure_fixture_loaded,
    Row,
};
use eql_tests::scalar_domains::{ScalarType, Variant};
use proptest::prelude::*;
use proptest::test_runner::{Config, TestCaseError, TestRunner};
use sqlx::PgPool;

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
        other => panic!(
            "no embedded fixture for catalog token '{other}'; \
             add an include_str! arm in fixture_oracle.rs"
        ),
    }
}

/// Read every `(plaintext, payload::text)` fixture row for `T`, in id order.
/// Ensures the corpus is present in the shared DB first (it lives in
/// `#[sqlx::test]`'s ephemeral DBs by default, not the pool we connect to).
async fn load_fixture_rows<T: ScalarType>(pool: &PgPool) -> Result<Vec<Row<T>>> {
    // The base DB this pool connects to is not migrated by `#[sqlx::test]`; in a
    // CI shard it has no `eql_v3` surface, so apply the migrations (idempotent +
    // process-safe via the migrator's advisory lock) before any cast/query.
    ensure_eql_installed(pool, &super::migrator()).await?;
    ensure_fixture_loaded::<T>(pool, embedded_fixture_sql::<T>()).await?;
    let sql = format!(
        "SELECT plaintext, payload::text FROM {} ORDER BY id",
        T::fixture_table_name()
    );
    let raw: Vec<(T, String)> = sqlx::query_as(&sql).fetch_all(pool).await?;
    Ok(raw
        .into_iter()
        .map(|(plaintext, payload_json)| Row {
            plaintext,
            payload_json,
        })
        .collect())
}

/// Build a corpus by sampling indices (with repeats) into the loaded fixtures.
/// `idxs` are already bounded to `0..all.len()` by the proptest strategy.
fn pick<T: Clone>(all: &[Row<T>], idxs: &[usize]) -> Vec<Row<T>> {
    idxs.iter().map(|&i| all[i].clone()).collect()
}

/// Drive proptest from a sync context: sample `cases` index-multisets, and for
/// each run the async oracle on a current-thread runtime. Kept here (not in the
/// lib) because it wires proptest to the test binary.
fn run_fixture_property<T, F, Fut>(cases: u32, oracle: F) -> Result<()>
where
    T: ScalarType,
    F: Fn(PgPool, Vec<Row<T>>) -> Fut,
    Fut: std::future::Future<Output = Result<()>>,
{
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;
    let pool = rt.block_on(connect_pool())?;
    let all = rt.block_on(load_fixture_rows::<T>(&pool))?;
    anyhow::ensure!(
        !all.is_empty(),
        "fixture {} is empty",
        T::fixture_table_name()
    );

    let mut runner = TestRunner::new(Config {
        cases,
        // No regression file: these cases sample committed fixtures, nothing to
        // persist/replay, and it silences proptest's "no source file" warning.
        failure_persistence: None,
        ..Config::default()
    });
    let n = all.len();
    // Each case: a multiset of 2..=12 indices into the fixtures (repeats wanted).
    let strategy = prop::collection::vec(0..n, 2..13);
    runner
        .run(&strategy, |idxs| {
            let corpus = pick(&all, &idxs);
            rt.block_on(oracle(pool.clone(), corpus))
                // `{e:#}` renders anyhow's full cause chain inline; plain
                // `to_string()` drops it, hiding the real Postgres error (e.g.
                // `schema "eql_v3" does not exist`) behind only the context line.
                .map_err(|e| TestCaseError::fail(format!("{e:#}")))?;
            Ok(())
        })
        .map_err(|e| anyhow::anyhow!("fixture property failed: {e}"))
}

#[test]
fn prop_int4_eq_oracle_over_fixture() -> Result<()> {
    run_fixture_property::<i32, _, _>(48, |pool, corpus| async move {
        assert_eq_oracle::<i32>(&pool, &corpus).await
    })
}

#[test]
fn prop_int4_ord_oracle_over_fixture() -> Result<()> {
    run_fixture_property::<i32, _, _>(48, |pool, corpus| async move {
        assert_ord_oracle::<i32>(&pool, Variant::Ord, &corpus).await?;
        assert_ord_oracle::<i32>(&pool, Variant::OrdOre, &corpus).await
    })
}

macro_rules! fixture_oracle_suite {
    ($modname:ident, $ty:ty, ordered) => {
        mod $modname {
            use super::*;
            #[test]
            fn eq_oracle() -> Result<()> {
                run_fixture_property::<$ty, _, _>(32, |pool, c| async move {
                    assert_eq_oracle::<$ty>(&pool, &c).await
                })
            }
            #[test]
            fn ord_oracle() -> Result<()> {
                run_fixture_property::<$ty, _, _>(32, |pool, c| async move {
                    assert_ord_oracle::<$ty>(&pool, Variant::Ord, &c).await?;
                    assert_ord_oracle::<$ty>(&pool, Variant::OrdOre, &c).await
                })
            }
        }
    };
    ($modname:ident, $ty:ty, eq_only) => {
        mod $modname {
            use super::*;
            #[test]
            fn eq_oracle() -> Result<()> {
                run_fixture_property::<$ty, _, _>(32, |pool, c| async move {
                    assert_eq_oracle::<$ty>(&pool, &c).await
                })
            }
        }
    };
}

fixture_oracle_suite!(int2, i16, ordered);
fixture_oracle_suite!(int8, i64, ordered);
fixture_oracle_suite!(date, chrono::NaiveDate, ordered);
fixture_oracle_suite!(text, String, ordered);
fixture_oracle_suite!(timestamptz, chrono::DateTime<chrono::Utc>, eq_only);
