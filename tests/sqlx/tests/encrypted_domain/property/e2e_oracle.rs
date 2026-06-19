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
use eql_tests::fixtures::eql_plaintext::EqlPlaintext;
use eql_tests::fixtures::index_kind::IndexKind;
use eql_tests::property::{
    assert_eq_oracle, assert_ord_oracle, connect_pool, ensure_eql_installed, Row,
};
use eql_tests::scalar_domains::ScalarType;
use eql_tests::scalar_domains::Variant;
use proptest::prelude::*;
use proptest::test_runner::{Config, TestCaseError, TestRunner};
use sqlx::PgPool;

/// Encrypt a batch of plaintext values into `(plaintext, payload_json)` rows
/// via the existing fixture oracle. One ZeroKMS round trip for the whole batch.
/// The EQL cast is the type's own `EqlPlaintext::CAST` — never passed in, so it
/// cannot drift from `T`.
async fn encrypt_rows<T>(pool_table: &str, values: &[T]) -> Result<Vec<Row<T>>>
where
    T: ScalarType + EqlPlaintext + Clone,
{
    let config = column_config_for(
        &[IndexKind::Unique, IndexKind::Ore],
        <T as EqlPlaintext>::CAST,
    )?;
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
fn run_e2e_property<T>(table: &str, cases: u32, ordered: bool, seeds: &[T]) -> Result<()>
where
    T: ScalarType + EqlPlaintext + Clone + 'static,
{
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;
    let pool: PgPool = rt.block_on(connect_pool())?;
    // The base DB this pool connects to is not migrated by `#[sqlx::test]`; in a
    // CI shard it has no `eql_v3` surface, so apply the migrations (idempotent +
    // process-safe via the migrator's advisory lock) before any cast/query.
    rt.block_on(ensure_eql_installed(&pool, &super::migrator()))?;

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
    // Per-type bounded strategy (see ScalarType::arbitrary_value): integers draw
    // the full range, non-integer scalars draw from their cast-valid fixture set.
    let strategy = prop::collection::vec(T::arbitrary_value(), 2..11);
    runner
        .run(&strategy, |mut values| {
            let dup0 = values[0].clone();
            let dup1 = values[1].clone();
            values.extend_from_slice(seeds);
            values.push(dup0);
            values.push(dup1);
            let rows = rt
                .block_on(encrypt_rows::<T>(table, &values))
                // `{e:#}` keeps anyhow's full cause chain (the underlying error),
                // which a plain `{e}` would drop.
                .map_err(|e| TestCaseError::fail(format!("encrypt: {e:#}")))?;
            rt.block_on(async {
                assert_eq_oracle::<T>(&pool, &rows).await?;
                if ordered {
                    assert_ord_oracle::<T>(&pool, Variant::Ord, &rows).await?;
                    assert_ord_oracle::<T>(&pool, Variant::OrdOre, &rows).await?;
                }
                Ok::<_, anyhow::Error>(())
            })
            .map_err(|e| TestCaseError::fail(format!("oracle: {e:#}")))?;
            Ok(())
        })
        .map_err(|e| anyhow::anyhow!("e2e property failed: {e}"))
}

/// Each e2e case is a ZeroKMS round trip, so the case count stays low (8 keeps
/// CI bounded). One macro line per ordered scalar; the EQL cast is derived from
/// the type, the seeds are the per-type extremes + origin.
macro_rules! e2e_oracle_suite {
    ($modname:ident, $ty:ty, $table:literal, seeds = [$($seed:expr),* $(,)?]) => {
        mod $modname {
            use super::*;
            #[test]
            fn e2e_oracle() -> Result<()> {
                run_e2e_property::<$ty>($table, 8, true, &[$($seed),*])
            }
        }
    };
}

e2e_oracle_suite!(
    int4,
    i32,
    "proptest_e2e_int4",
    seeds = [i32::MIN, 0, i32::MAX]
);
e2e_oracle_suite!(
    int2,
    i16,
    "proptest_e2e_int2",
    seeds = [i16::MIN, 0, i16::MAX]
);
e2e_oracle_suite!(
    int8,
    i64,
    "proptest_e2e_int8",
    seeds = [i64::MIN, 0, i64::MAX]
);
e2e_oracle_suite!(
    date,
    chrono::NaiveDate,
    "proptest_e2e_date",
    seeds = [
        chrono::NaiveDate::from_ymd_opt(1900, 1, 1).unwrap(),
        chrono::NaiveDate::default(),
        chrono::NaiveDate::from_ymd_opt(2099, 12, 31).unwrap(),
    ]
);
e2e_oracle_suite!(
    timestamptz,
    chrono::DateTime<chrono::Utc>,
    "proptest_e2e_timestamptz",
    seeds = [
        chrono::DateTime::parse_from_rfc3339("1900-01-01T00:00:00Z")
            .unwrap()
            .with_timezone(&chrono::Utc),
        chrono::DateTime::<chrono::Utc>::default(),
        chrono::DateTime::parse_from_rfc3339("2099-12-31T23:59:59Z")
            .unwrap()
            .with_timezone(&chrono::Utc),
    ]
);
e2e_oracle_suite!(
    numeric,
    rust_decimal::Decimal,
    "proptest_e2e_numeric",
    seeds = [
        <rust_decimal::Decimal as std::str::FromStr>::from_str("-1000000000000").unwrap(),
        rust_decimal::Decimal::ZERO,
        <rust_decimal::Decimal as std::str::FromStr>::from_str("1000000000000").unwrap(),
    ]
);
e2e_oracle_suite!(
    text,
    String,
    "proptest_e2e_text",
    seeds = ["aard".to_string(), "frank".to_string(), "zzzz".to_string()]
);
e2e_oracle_suite!(
    float4,
    eql_tests::scalar_domains::F4,
    "proptest_e2e_float4",
    seeds = [
        eql_tests::scalar_domains::F4(f32::NEG_INFINITY),
        eql_tests::scalar_domains::F4(0.0),
        eql_tests::scalar_domains::F4(f32::INFINITY),
    ]
);
e2e_oracle_suite!(
    float8,
    eql_tests::scalar_domains::F8,
    "proptest_e2e_float8",
    seeds = [
        eql_tests::scalar_domains::F8(f64::NEG_INFINITY),
        eql_tests::scalar_domains::F8(0.0),
        eql_tests::scalar_domains::F8(f64::INFINITY),
    ]
);

/// Both float widths encrypt through the SINGLE f64 crypto path
/// (`F4::to_plaintext` widens `self.0 as f64`; `F8::to_plaintext` is the
/// identity), so an f32 value and its exact f64 widening MUST produce identical
/// index terms — this is the byte-identity the CHANGELOG claims. Encrypt the
/// same value both ways (an f32-exact value, so `x as f64` is lossless) and
/// assert the `hm` (HMAC equality) and `ob` (ORE) terms match across widths.
/// Creds/e2e-gated like the rest of this file.
#[test]
fn float4_and_float8_share_index_terms_for_the_same_value() -> Result<()> {
    use eql_tests::scalar_domains::{F4, F8};

    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?;

    // f32-exact value: `x as f64` is the same real number, so any term
    // difference would be a width artifact, which is exactly what we forbid.
    let x: f32 = 2.25;

    let f4_payloads = rt.block_on(async {
        let cfg = column_config_for(
            &[IndexKind::Unique, IndexKind::Ore],
            <F4 as EqlPlaintext>::CAST,
        )?;
        encrypt_store("xwidth_f4", "payload", &[F4(x)], &cfg).await
    })?;
    let f8_payloads = rt.block_on(async {
        let cfg = column_config_for(
            &[IndexKind::Unique, IndexKind::Ore],
            <F8 as EqlPlaintext>::CAST,
        )?;
        encrypt_store("xwidth_f8", "payload", &[F8(x as f64)], &cfg).await
    })?;

    // Pull a string index term from the EQL payload JSON (`hm` / `ob`).
    let term = |p: &serde_json::Value, key: &str| -> Result<String> {
        p.get(key)
            .and_then(serde_json::Value::as_str)
            .map(str::to_string)
            .ok_or_else(|| anyhow::anyhow!("payload missing string `{key}`: {p}"))
    };

    // HMAC equality term: identical plaintext + key => identical hm, so the two
    // widths are equality-interchangeable at the term level.
    assert_eq!(
        term(&f4_payloads[0], "hm")?,
        term(&f8_payloads[0], "hm")?,
        "float4 and float8 of the same value must share the hm equality term"
    );
    // ORE term: same f64 input => same ORE ciphertext, so ordering is identical.
    assert_eq!(
        term(&f4_payloads[0], "ob")?,
        term(&f8_payloads[0], "ob")?,
        "float4 and float8 of the same value must share the ob ORE term"
    );
    Ok(())
}
