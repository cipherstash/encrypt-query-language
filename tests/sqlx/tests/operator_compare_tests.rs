//! Operator compare function tests
//!
//! Tests the main eql_v2.compare() function with all index types

use anyhow::Result;
use sqlx::PgPool;

// Helper macro to reduce repetition for compare tests
macro_rules! assert_compare {
    ($pool:expr, $sql_a:expr, $sql_b:expr, $expected:expr, $msg:expr) => {
        let result: i32 =
            sqlx::query_scalar(&format!("SELECT eql_v2.compare({}, {})", $sql_a, $sql_b))
                .fetch_one($pool)
                .await?;
        assert_eq!(result, $expected, $msg);
    };
}

#[sqlx::test]
async fn compare_ore_cllw_hello_path(pool: PgPool) -> Result<()> {
    // Test: compare() with ORE CLLW VAR 8 on $.hello path
    // {"hello": "world{N}"}
    // $.hello: d90b97b5207d30fe867ca816ed0fe4a7

    let a = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(1), 'd90b97b5207d30fe867ca816ed0fe4a7')";
    let b = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(2), 'd90b97b5207d30fe867ca816ed0fe4a7')";
    let c = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(3), 'd90b97b5207d30fe867ca816ed0fe4a7')";

    // 9 assertions: reflexive, transitive, and antisymmetric comparison properties
    assert_compare!(&pool, a, a, 0, "compare(a, a) should equal 0");
    assert_compare!(&pool, a, b, -1, "compare(a, b) should equal -1");
    assert_compare!(&pool, a, c, -1, "compare(a, c) should equal -1");
    assert_compare!(&pool, b, b, 0, "compare(b, b) should equal 0");
    assert_compare!(&pool, b, a, 1, "compare(b, a) should equal 1");
    assert_compare!(&pool, b, c, -1, "compare(b, c) should equal -1");
    assert_compare!(&pool, c, c, 0, "compare(c, c) should equal 0");
    assert_compare!(&pool, c, b, 1, "compare(c, b) should equal 1");
    assert_compare!(&pool, c, a, 1, "compare(c, a) should equal 1");

    Ok(())
}

#[sqlx::test]
async fn compare_ore_cllw_number_path(pool: PgPool) -> Result<()> {
    // Test: compare() with ORE CLLW VAR 8 on $.number path
    // {"number": {N}}
    // $.number: 3dba004f4d7823446e7cb71f6681b344

    let a = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(1), '3dba004f4d7823446e7cb71f6681b344')";
    let b = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(5), '3dba004f4d7823446e7cb71f6681b344')";
    let c = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(10), '3dba004f4d7823446e7cb71f6681b344')";

    // 9 assertions: reflexive, transitive, and antisymmetric comparison properties
    assert_compare!(&pool, a, a, 0, "compare(a, a) should equal 0");
    assert_compare!(&pool, a, b, -1, "compare(a, b) should equal -1");
    assert_compare!(&pool, a, c, -1, "compare(a, c) should equal -1");
    assert_compare!(&pool, b, b, 0, "compare(b, b) should equal 0");
    assert_compare!(&pool, b, a, 1, "compare(b, a) should equal 1");
    assert_compare!(&pool, b, c, -1, "compare(b, c) should equal -1");
    assert_compare!(&pool, c, c, 0, "compare(c, c) should equal 0");
    assert_compare!(&pool, c, b, 1, "compare(c, b) should equal 1");
    assert_compare!(&pool, c, a, 1, "compare(c, a) should equal 1");

    Ok(())
}

#[sqlx::test]
async fn compare_ore_block_u64_8_256(pool: PgPool) -> Result<()> {
    // Test: compare() with ORE Block U64 8 256

    let a = "create_encrypted_ore_json(1)";
    let b = "create_encrypted_ore_json(21)";
    let c = "create_encrypted_ore_json(42)";

    // 9 assertions: reflexive, transitive, and antisymmetric comparison properties
    assert_compare!(&pool, a, a, 0, "compare(a, a) should equal 0");
    assert_compare!(&pool, a, b, -1, "compare(a, b) should equal -1");
    assert_compare!(&pool, a, c, -1, "compare(a, c) should equal -1");
    assert_compare!(&pool, b, b, 0, "compare(b, b) should equal 0");
    assert_compare!(&pool, b, a, 1, "compare(b, a) should equal 1");
    assert_compare!(&pool, b, c, -1, "compare(b, c) should equal -1");
    assert_compare!(&pool, c, c, 0, "compare(c, c) should equal 0");
    assert_compare!(&pool, c, b, 1, "compare(c, b) should equal 1");
    assert_compare!(&pool, c, a, 1, "compare(c, a) should equal 1");

    Ok(())
}

// compare_blake3_index removed: post-discipline, eql_v2.compare's
// equality branch is hmac-only at the root. Blake3 is no longer in the
// root compare priority list. compare_blake3 still exists and is
// exercised inside ste_vec_contains for selector-level element
// comparisons.

// eql_v2.compare is strict ORE-only post-#219: equality (hm) and the
// literal-bytes fallback are removed from this function. The tests that
// previously asserted hm-fallback / literal-fallback semantics now assert
// the raise contract instead.

#[sqlx::test]
async fn compare_raises_on_hmac_only_payloads(pool: PgPool) -> Result<()> {
    // Strict eql_v2.compare contract: equality is hm-only via the inlined
    // `=` operator, NOT through compare(). Calling compare() on hm-only
    // payloads should raise with a directive error.
    let sql =
        "SELECT eql_v2.compare(create_encrypted_json(1, 'hm'), create_encrypted_json(2, 'hm'))";
    let err = sqlx::query(sql).fetch_one(&pool).await.expect_err(
        "expected compare() to raise on hm-only payloads under the strict ORE contract",
    );
    let msg = err.to_string();
    assert!(
        msg.contains("requires an ORE term"),
        "expected error to mention the strict ORE requirement; got: {msg}"
    );
    Ok(())
}

#[sqlx::test]
async fn compare_raises_when_no_index_terms_present(pool: PgPool) -> Result<()> {
    // Strict eql_v2.compare contract: no literal-bytes fallback. Payloads
    // without `ob` (root) or `oc` (sv element) raise.
    let sql = "SELECT eql_v2.compare('{\"a\": 1}'::jsonb::eql_v2_encrypted, '{\"b\": 2}'::jsonb::eql_v2_encrypted)";
    let err = sqlx::query(sql)
        .fetch_one(&pool)
        .await
        .expect_err("expected compare() to raise on payloads carrying no ORE term");
    let msg = err.to_string();
    assert!(
        msg.contains("requires an ORE term"),
        "expected error to mention the strict ORE requirement; got: {msg}"
    );
    Ok(())
}

#[sqlx::test]
async fn compare_raises_when_ore_term_is_json_null(pool: PgPool) -> Result<()> {
    // Strict eql_v2.compare contract: an `ob: null` payload doesn't satisfy
    // `has_ore_block_u64_8_256` (the has_* check rejects JSON null), so
    // compare() raises rather than silently falling through to hm.
    let sql = "SELECT eql_v2.compare(\
        ('{\"ob\": null}'::jsonb || create_encrypted_json(1, 'hm')::jsonb)::eql_v2_encrypted, \
        ('{\"ob\": null}'::jsonb || create_encrypted_json(2, 'hm')::jsonb)::eql_v2_encrypted)";
    let err = sqlx::query(sql)
        .fetch_one(&pool)
        .await
        .expect_err("expected compare() to raise when ob is JSON null and only hm is present");
    let msg = err.to_string();
    assert!(
        msg.contains("requires an ORE term"),
        "expected error to mention the strict ORE requirement; got: {msg}"
    );
    Ok(())
}
