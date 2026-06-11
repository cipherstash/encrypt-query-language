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
