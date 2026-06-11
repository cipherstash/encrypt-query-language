//! Direct unit tests for the generalized N-block ORE comparator
//! `eql_v3.compare_ore_block_256_term`.
//!
//! The malformed-length guards here are creds-free: they construct ORE terms
//! by hand from short byte strings, so they exercise the length validation
//! without needing real (ZeroKMS-generated) ciphertexts. The wide-term ordering
//! test (added in Phase 4) uses generated numeric fixtures.

use anyhow::Result;
use sqlx::PgPool;

/// A `bytea` whose length is NOT a valid `49*N + 16` must raise, not silently
/// return 0. Uses a 4-byte term (equal lengths so the equal-length guard does
/// not fire first).
#[sqlx::test]
async fn comparator_rejects_non_conforming_length(pool: PgPool) -> Result<()> {
    let sql = "SELECT eql_v3.compare_ore_block_256_term( \
        ROW('\\x00010203'::bytea)::eql_v3.ore_block_256_term, \
        ROW('\\x04050607'::bytea)::eql_v3.ore_block_256_term)";
    let err = sqlx::query_scalar::<_, i32>(sql)
        .fetch_one(&pool)
        .await
        .expect_err("a 4-byte ORE term must raise, not return a comparison");
    assert!(
        err.to_string()
            .to_lowercase()
            .contains("malformed ore term"),
        "expected malformed-term error, got: {err}"
    );
    Ok(())
}

/// A 16-byte term satisfies `(16 - 16) % 49 == 0` and derives N = 0; the
/// `<= 16` clause must still reject it (otherwise it falls through to the
/// all-blocks-equal path and wrongly returns 0).
#[sqlx::test]
async fn comparator_rejects_sixteen_byte_term(pool: PgPool) -> Result<()> {
    let sql = "SELECT eql_v3.compare_ore_block_256_term( \
        ROW(repeat('a', 16)::bytea)::eql_v3.ore_block_256_term, \
        ROW(repeat('b', 16)::bytea)::eql_v3.ore_block_256_term)";
    let err = sqlx::query_scalar::<_, i32>(sql)
        .fetch_one(&pool)
        .await
        .expect_err("a 16-byte ORE term (N=0) must raise");
    assert!(
        err.to_string()
            .to_lowercase()
            .contains("malformed ore term"),
        "expected malformed-term error, got: {err}"
    );
    Ok(())
}

/// Width: a numeric ORE term must be 14 blocks => 49*14 + 16 = 702 bytes.
#[sqlx::test(fixtures(path = "../fixtures", scripts("eql_v2_numeric")))]
async fn numeric_term_is_14_blocks(pool: PgPool) -> Result<()> {
    let width: i32 = sqlx::query_scalar(
        "SELECT octet_length((((eql_v3.ord_term( \
            (SELECT payload FROM fixtures.eql_v2_numeric WHERE plaintext = (-1000000)::numeric) \
            ::eql_v3.numeric_ord)).terms)[1]).bytes)",
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(width, 702, "numeric ORE term must be 14 blocks (702 bytes)");
    Ok(())
}

/// Full ascending chain of 14-block numeric terms: every adjacent pair must
/// order `-1`. Spans sign, magnitude, and fractional (low-block) scale, so the
/// left blocks — not just the right blocks — decide ordering. This is the
/// regression the missed `9 -> 1+n` left-offset would fail; a single pair could
/// pass against that bug.
#[sqlx::test(fixtures(path = "../fixtures", scripts("eql_v2_numeric")))]
async fn numeric_terms_order_in_ascending_chain(pool: PgPool) -> Result<()> {
    let ascending = [
        "-1000000000000",
        "-1000000",
        "-1.001",
        "-1",
        "-0.5",
        "-0.001",
        "0",
        "0.001",
        "0.5",
        "0.999999999",
        "1",
        "1.001",
        "1000000",
        "1000000000000",
    ];
    for pair in ascending.windows(2) {
        let (lo, hi) = (pair[0], pair[1]);
        let cmp: i32 = sqlx::query_scalar(&format!(
            "SELECT eql_v3.compare_ore_block_256_terms( \
                eql_v3.ord_term((SELECT payload FROM fixtures.eql_v2_numeric WHERE plaintext = ({lo})::numeric)::eql_v3.numeric_ord), \
                eql_v3.ord_term((SELECT payload FROM fixtures.eql_v2_numeric WHERE plaintext = ({hi})::numeric)::eql_v3.numeric_ord))"
        ))
        .fetch_one(&pool)
        .await?;
        assert_eq!(cmp, -1, "{lo} must order before {hi}");
    }
    Ok(())
}

/// Symmetric 12-block (timestamptz, N=12 => 604 bytes) width + ordering check.
/// 12 is the only N strictly between the working 8 and the headline 14.
#[sqlx::test(fixtures(path = "../fixtures", scripts("eql_v2_timestamptz")))]
async fn timestamptz_term_is_12_blocks_and_orders(pool: PgPool) -> Result<()> {
    let width: i32 = sqlx::query_scalar(
        "SELECT octet_length((((eql_v3.ord_term( \
            (SELECT payload FROM fixtures.eql_v2_timestamptz WHERE plaintext = '1970-01-01T00:00:00Z'::timestamptz) \
            ::eql_v3.timestamptz_ord)).terms)[1]).bytes)",
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(
        width, 604,
        "timestamptz ORE term must be 12 blocks (604 bytes)"
    );

    let cmp: i32 = sqlx::query_scalar(
        "SELECT eql_v3.compare_ore_block_256_terms( \
            eql_v3.ord_term((SELECT payload FROM fixtures.eql_v2_timestamptz WHERE plaintext = '1900-01-01T00:00:00Z'::timestamptz)::eql_v3.timestamptz_ord), \
            eql_v3.ord_term((SELECT payload FROM fixtures.eql_v2_timestamptz WHERE plaintext = '2099-12-31T23:59:59Z'::timestamptz)::eql_v3.timestamptz_ord))",
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(cmp, -1, "1900 must order before 2099");
    Ok(())
}
