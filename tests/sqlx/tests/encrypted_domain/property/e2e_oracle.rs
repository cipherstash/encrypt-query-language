//! e2e suite (CIP-3141): property tests over freshly generated values encrypted
//! end-to-end through ZeroKMS each run. Gated behind `proptest-e2e` (declared in
//! property/mod.rs) — needs CS_* creds, which `mise run test:sqlx` enables for
//! CI/local full SQLx runs.
//! Each proptest case generates one corpus of random integers — seeded with
//! type-specific extremes, zero, and deliberate duplicates so the equality-true
//! branch fires across distinct ciphertexts of the same plaintext — encrypts it
//! in one batched ZeroKMS call, then runs the all-pairs oracle.

use anyhow::Result;
use eql_tests::fixtures::cipherstash::{column_config_for, encrypt_store};
use eql_tests::fixtures::eql_plaintext::{Cast, EqlPlaintext};
use eql_tests::fixtures::index_kind::IndexKind;
use eql_tests::property::{assert_eq_oracle, assert_ord_oracle, connect_pool, Row};
use eql_tests::scalar_domains::ScalarType;
use eql_tests::scalar_domains::Variant;
use proptest::prelude::*;
use proptest::test_runner::{Config, TestCaseError, TestRunner};
use sqlx::PgPool;

/// Encrypt a batch of plaintext integers into `(plaintext, payload_json)` rows
/// via the existing fixture oracle. One ZeroKMS round trip for the whole batch.
async fn encrypt_rows<T>(pool_table: &str, cast: Cast, values: &[T]) -> Result<Vec<Row<T>>>
where
    T: ScalarType + EqlPlaintext + Clone,
{
    let config = column_config_for(&[IndexKind::Unique, IndexKind::Ore], cast)?;
    let payloads = encrypt_store(pool_table, "payload", values, &config).await?;
    // Fail fast on a count mismatch: a silent `zip` truncation would weaken the
    // oracle (fewer pairs than intended) and hide an encrypt_store contract
    // regression. (encrypt_store already checks this, but keep it local/explicit.)
    anyhow::ensure!(
        payloads.len() == values.len(),
        "encrypt_store returned {} payloads for {} plaintext values",
        payloads.len(),
        values.len()
    );
    Ok(values
        .iter()
        .cloned()
        .zip(payloads)
        .map(|(plaintext, payload)| Row {
            plaintext,
            payload_json: payload.to_string(),
        })
        .collect())
}

/// Drive proptest: each case is a corpus of integers. Generation is in-process;
/// encryption + oracle is async on a current-thread runtime.
fn run_e2e_property<T>(
    table: &str,
    cast: Cast,
    cases: u32,
    ordered: bool,
    seeds: &[T],
) -> Result<()>
where
    T: ScalarType + EqlPlaintext + Clone + 'static,
    T: proptest::arbitrary::Arbitrary,
    <T as proptest::arbitrary::Arbitrary>::Strategy: 'static,
{
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;
    let pool: PgPool = rt.block_on(connect_pool())?;

    // Shrinking is disabled for the e2e suite: every failed shrink attempt would
    // trigger another ZeroKMS batch, and ciphertext cannot be meaningfully
    // shrunk anyway. The catalog suite keeps normal shrinking.
    let mut runner = TestRunner::new(Config {
        cases,
        max_shrink_iters: 0,
        // Ciphertext can't be replayed across runs (fresh ZeroKMS each time), so
        // there's nothing to persist; also silences proptest's "no source file"
        // warning.
        failure_persistence: None,
        ..Config::default()
    });
    // 2..=10 random values, then we append deterministic seeds and duplicates
    // of the first two random values. Seeds guarantee min/max/zero coverage;
    // duplicates guarantee the eq-true branch across independently encrypted
    // ciphertexts.
    let strategy = prop::collection::vec(any::<T>(), 2..11);
    runner
        .run(&strategy, |mut values| {
            let dup0 = values[0].clone();
            let dup1 = values[1].clone();
            values.extend_from_slice(seeds);
            values.push(dup0);
            values.push(dup1);
            let rows = rt
                .block_on(encrypt_rows::<T>(table, cast, &values))
                .map_err(|e| TestCaseError::fail(format!("encrypt: {e}")))?;
            rt.block_on(async {
                assert_eq_oracle::<T>(&pool, &rows).await?;
                if ordered {
                    assert_ord_oracle::<T>(&pool, Variant::Ord, &rows).await?;
                    assert_ord_oracle::<T>(&pool, Variant::OrdOre, &rows).await?;
                }
                Ok::<_, anyhow::Error>(())
            })
            .map_err(|e| TestCaseError::fail(format!("oracle: {e}")))?;
            Ok(())
        })
        .map_err(|e| anyhow::anyhow!("e2e property failed: {e}"))
}

#[test]
fn prop_int4_eq_and_ord_oracle_e2e() -> Result<()> {
    // Low case count: each case is a ZeroKMS round trip. 8 keeps CI bounded.
    run_e2e_property::<i32>(
        "proptest_e2e_int4",
        Cast::INT,
        8,
        true,
        &[i32::MIN, 0, i32::MAX],
    )
}

#[test]
fn prop_int2_eq_and_ord_oracle_e2e() -> Result<()> {
    run_e2e_property::<i16>(
        "proptest_e2e_int2",
        Cast::SMALL_INT,
        8,
        true,
        &[i16::MIN, 0, i16::MAX],
    )
}

#[test]
fn prop_int8_eq_and_ord_oracle_e2e() -> Result<()> {
    run_e2e_property::<i64>(
        "proptest_e2e_int8",
        Cast::BIG_INT,
        8,
        true,
        &[i64::MIN, 0, i64::MAX],
    )
}
