//! Index-specific comparison function tests
//!
//! Tests the index-specific compare functions:
//! - compare_blake3()
//! - compare_hmac_256()
//! - compare_ore_block_u64_8_256()
//! - compare_ore_cllw_u64_8()
//! - compare_ore_cllw_var_8()
//!
//! Converted from individual *_test.sql files:
//! - src/blake3/compare_test.sql
//! - src/hmac_256/compare_test.sql
//! - src/ore_block_u64_8_256/compare_test.sql
//! - src/ore_cllw_u64_8/compare_test.sql
//! - src/ore_cllw_var_8/compare_test.sql

use anyhow::Result;
use sqlx::PgPool;

// Helper macro to reduce repetition for compare tests
//
// Note: Uses format! for SQL construction because test data expressions
// (like "create_encrypted_json(1, 'b3')") must be evaluated by PostgreSQL,
// not passed as parameters. SQLx cannot pass PostgreSQL function calls as
// query parameters - they must be part of the SQL string.
macro_rules! assert_compare {
    ($pool:expr, $func:expr, $a:expr, $b:expr, $expected:expr, $msg:expr) => {
        let result: i32 = sqlx::query_scalar(&format!("SELECT eql_v2.{}({}, {})", $func, $a, $b))
            .fetch_one($pool)
            .await?;
        assert_eq!(result, $expected, $msg);
    };
}

//
// Blake3 Index Comparison Tests
//

#[sqlx::test]
async fn blake3_compare_equal(pool: PgPool) -> Result<()> {
    // Test: compare_blake3() with equal values
    // Original SQL: src/blake3/compare_test.sql lines 13,17,21

    let a = "create_encrypted_json(1, 'b3')";
    let b = "create_encrypted_json(2, 'b3')";
    let c = "create_encrypted_json(3, 'b3')";

    // 3 assertions: a=a, b=b, c=c should all return 0
    assert_compare!(
        &pool,
        "compare_blake3",
        a,
        a,
        0,
        "compare_blake3(a, a) should equal 0"
    );
    assert_compare!(
        &pool,
        "compare_blake3",
        b,
        b,
        0,
        "compare_blake3(b, b) should equal 0"
    );
    assert_compare!(
        &pool,
        "compare_blake3",
        c,
        c,
        0,
        "compare_blake3(c, c) should equal 0"
    );

    Ok(())
}

#[sqlx::test]
async fn blake3_compare_less_than(pool: PgPool) -> Result<()> {
    // Test: compare_blake3() with less than comparisons
    // Original SQL: src/blake3/compare_test.sql lines 14,15,19,23

    let a = "create_encrypted_json(1, 'b3')";
    let b = "create_encrypted_json(2, 'b3')";
    let c = "create_encrypted_json(3, 'b3')";

    // 4 assertions: a<b, a<c, b<c should all return -1
    assert_compare!(
        &pool,
        "compare_blake3",
        a,
        b,
        -1,
        "compare_blake3(a, b) should equal -1"
    );
    assert_compare!(
        &pool,
        "compare_blake3",
        a,
        c,
        -1,
        "compare_blake3(a, c) should equal -1"
    );
    assert_compare!(
        &pool,
        "compare_blake3",
        b,
        c,
        -1,
        "compare_blake3(b, c) should equal -1"
    );

    Ok(())
}

#[sqlx::test]
async fn blake3_compare_greater_than(pool: PgPool) -> Result<()> {
    // Test: compare_blake3() with greater than comparisons
    // Original SQL: src/blake3/compare_test.sql lines 18,22,23

    let a = "create_encrypted_json(1, 'b3')";
    let b = "create_encrypted_json(2, 'b3')";
    let c = "create_encrypted_json(3, 'b3')";

    // 3 assertions: b>a, c>a, c>b should all return 1
    assert_compare!(
        &pool,
        "compare_blake3",
        b,
        a,
        1,
        "compare_blake3(b, a) should equal 1"
    );
    assert_compare!(
        &pool,
        "compare_blake3",
        c,
        a,
        1,
        "compare_blake3(c, a) should equal 1"
    );
    assert_compare!(
        &pool,
        "compare_blake3",
        c,
        b,
        1,
        "compare_blake3(c, b) should equal 1"
    );

    Ok(())
}

//
// HMAC-256 Index Comparison Tests
//

#[sqlx::test]
async fn hmac_compare_equal(pool: PgPool) -> Result<()> {
    // Test: compare_hmac_256() with equal values
    // Original SQL: src/hmac_256/compare_test.sql lines 13,17,21

    let a = "create_encrypted_json(1, 'hm')";
    let b = "create_encrypted_json(2, 'hm')";
    let c = "create_encrypted_json(3, 'hm')";

    // 3 assertions: a=a, b=b, c=c should all return 0
    assert_compare!(
        &pool,
        "compare_hmac_256",
        a,
        a,
        0,
        "compare_hmac_256(a, a) should equal 0"
    );
    assert_compare!(
        &pool,
        "compare_hmac_256",
        b,
        b,
        0,
        "compare_hmac_256(b, b) should equal 0"
    );
    assert_compare!(
        &pool,
        "compare_hmac_256",
        c,
        c,
        0,
        "compare_hmac_256(c, c) should equal 0"
    );

    Ok(())
}

#[sqlx::test]
async fn hmac_compare_less_than(pool: PgPool) -> Result<()> {
    // Test: compare_hmac_256() with less than comparisons
    // Original SQL: src/hmac_256/compare_test.sql lines 14,15,19,23

    let a = "create_encrypted_json(1, 'hm')";
    let b = "create_encrypted_json(2, 'hm')";
    let c = "create_encrypted_json(3, 'hm')";

    // 3 assertions: a<b, a<c, b<c should all return -1
    assert_compare!(
        &pool,
        "compare_hmac_256",
        a,
        b,
        -1,
        "compare_hmac_256(a, b) should equal -1"
    );
    assert_compare!(
        &pool,
        "compare_hmac_256",
        a,
        c,
        -1,
        "compare_hmac_256(a, c) should equal -1"
    );
    assert_compare!(
        &pool,
        "compare_hmac_256",
        b,
        c,
        -1,
        "compare_hmac_256(b, c) should equal -1"
    );

    Ok(())
}

#[sqlx::test]
async fn hmac_compare_greater_than(pool: PgPool) -> Result<()> {
    // Test: compare_hmac_256() with greater than comparisons
    // Original SQL: src/hmac_256/compare_test.sql lines 18,22,23

    let a = "create_encrypted_json(1, 'hm')";
    let b = "create_encrypted_json(2, 'hm')";
    let c = "create_encrypted_json(3, 'hm')";

    // 3 assertions: b>a, c>a, c>b should all return 1
    assert_compare!(
        &pool,
        "compare_hmac_256",
        b,
        a,
        1,
        "compare_hmac_256(b, a) should equal 1"
    );
    assert_compare!(
        &pool,
        "compare_hmac_256",
        c,
        a,
        1,
        "compare_hmac_256(c, a) should equal 1"
    );
    assert_compare!(
        &pool,
        "compare_hmac_256",
        c,
        b,
        1,
        "compare_hmac_256(c, b) should equal 1"
    );

    Ok(())
}

//
// ORE Block U64 Comparison Tests
//

#[sqlx::test]
async fn ore_block_compare_equal(pool: PgPool) -> Result<()> {
    // Test: compare_ore_block_u64_8_256() with equal values
    // Original SQL: src/ore_block_u64_8_256/compare_test.sql lines 14,18,22

    let a = "create_encrypted_ore_json(1)";
    let b = "create_encrypted_ore_json(21)";
    let c = "create_encrypted_ore_json(42)";

    // 3 assertions: a=a, b=b, c=c should all return 0
    assert_compare!(
        &pool,
        "compare_ore_block_u64_8_256",
        a,
        a,
        0,
        "compare_ore_block_u64_8_256(a, a) should equal 0"
    );
    assert_compare!(
        &pool,
        "compare_ore_block_u64_8_256",
        b,
        b,
        0,
        "compare_ore_block_u64_8_256(b, b) should equal 0"
    );
    assert_compare!(
        &pool,
        "compare_ore_block_u64_8_256",
        c,
        c,
        0,
        "compare_ore_block_u64_8_256(c, c) should equal 0"
    );

    Ok(())
}

#[sqlx::test]
async fn ore_block_compare_less_than(pool: PgPool) -> Result<()> {
    // Test: compare_ore_block_u64_8_256() with less than comparisons
    // Original SQL: src/ore_block_u64_8_256/compare_test.sql lines 15,16,20,24

    let a = "create_encrypted_ore_json(1)";
    let b = "create_encrypted_ore_json(21)";
    let c = "create_encrypted_ore_json(42)";

    // 3 assertions: a<b, a<c, b<c should all return -1
    assert_compare!(
        &pool,
        "compare_ore_block_u64_8_256",
        a,
        b,
        -1,
        "compare_ore_block_u64_8_256(a, b) should equal -1"
    );
    assert_compare!(
        &pool,
        "compare_ore_block_u64_8_256",
        a,
        c,
        -1,
        "compare_ore_block_u64_8_256(a, c) should equal -1"
    );
    assert_compare!(
        &pool,
        "compare_ore_block_u64_8_256",
        b,
        c,
        -1,
        "compare_ore_block_u64_8_256(b, c) should equal -1"
    );

    Ok(())
}

#[sqlx::test]
async fn ore_block_compare_greater_than(pool: PgPool) -> Result<()> {
    // Test: compare_ore_block_u64_8_256() with greater than comparisons
    // Original SQL: src/ore_block_u64_8_256/compare_test.sql lines 19,23,24

    let a = "create_encrypted_ore_json(1)";
    let b = "create_encrypted_ore_json(21)";
    let c = "create_encrypted_ore_json(42)";

    // 3 assertions: b>a, c>a, c>b should all return 1
    assert_compare!(
        &pool,
        "compare_ore_block_u64_8_256",
        b,
        a,
        1,
        "compare_ore_block_u64_8_256(b, a) should equal 1"
    );
    assert_compare!(
        &pool,
        "compare_ore_block_u64_8_256",
        c,
        a,
        1,
        "compare_ore_block_u64_8_256(c, a) should equal 1"
    );
    assert_compare!(
        &pool,
        "compare_ore_block_u64_8_256",
        c,
        b,
        1,
        "compare_ore_block_u64_8_256(c, b) should equal 1"
    );

    Ok(())
}

//
// ORE CLLW U64 Comparison Tests
//

#[sqlx::test]
async fn ore_cllw_u64_compare_equal(pool: PgPool) -> Result<()> {
    // Test: compare_ore_cllw_u64_8() with equal values
    // Original SQL: src/ore_cllw_u64_8/compare_test.sql lines 16,20,24
    //
    // {"number": {N}}
    // $.number: 3dba004f4d7823446e7cb71f6681b344

    let a = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(1), '3dba004f4d7823446e7cb71f6681b344')";
    let b = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(5), '3dba004f4d7823446e7cb71f6681b344')";
    let c = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(10), '3dba004f4d7823446e7cb71f6681b344')";

    // 3 assertions: a=a, b=b, c=c should all return 0
    assert_compare!(
        &pool,
        "compare_ore_cllw_u64_8",
        a,
        a,
        0,
        "compare_ore_cllw_u64_8(a, a) should equal 0"
    );
    assert_compare!(
        &pool,
        "compare_ore_cllw_u64_8",
        b,
        b,
        0,
        "compare_ore_cllw_u64_8(b, b) should equal 0"
    );
    assert_compare!(
        &pool,
        "compare_ore_cllw_u64_8",
        c,
        c,
        0,
        "compare_ore_cllw_u64_8(c, c) should equal 0"
    );

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_u64_compare_less_than(pool: PgPool) -> Result<()> {
    // Test: compare_ore_cllw_u64_8() with less than comparisons
    // Original SQL: src/ore_cllw_u64_8/compare_test.sql lines 17,18,22,26
    //
    // {"number": {N}}
    // $.number: 3dba004f4d7823446e7cb71f6681b344

    let a = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(1), '3dba004f4d7823446e7cb71f6681b344')";
    let b = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(5), '3dba004f4d7823446e7cb71f6681b344')";
    let c = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(10), '3dba004f4d7823446e7cb71f6681b344')";

    // 3 assertions: a<b, a<c, b<c should all return -1
    assert_compare!(
        &pool,
        "compare_ore_cllw_u64_8",
        a,
        b,
        -1,
        "compare_ore_cllw_u64_8(a, b) should equal -1"
    );
    assert_compare!(
        &pool,
        "compare_ore_cllw_u64_8",
        a,
        c,
        -1,
        "compare_ore_cllw_u64_8(a, c) should equal -1"
    );
    assert_compare!(
        &pool,
        "compare_ore_cllw_u64_8",
        b,
        c,
        -1,
        "compare_ore_cllw_u64_8(b, c) should equal -1"
    );

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_u64_compare_greater_than(pool: PgPool) -> Result<()> {
    // Test: compare_ore_cllw_u64_8() with greater than comparisons
    // Original SQL: src/ore_cllw_u64_8/compare_test.sql lines 21,25,26
    //
    // {"number": {N}}
    // $.number: 3dba004f4d7823446e7cb71f6681b344

    let a = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(1), '3dba004f4d7823446e7cb71f6681b344')";
    let b = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(5), '3dba004f4d7823446e7cb71f6681b344')";
    let c = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(10), '3dba004f4d7823446e7cb71f6681b344')";

    // 3 assertions: b>a, c>a, c>b should all return 1
    assert_compare!(
        &pool,
        "compare_ore_cllw_u64_8",
        b,
        a,
        1,
        "compare_ore_cllw_u64_8(b, a) should equal 1"
    );
    assert_compare!(
        &pool,
        "compare_ore_cllw_u64_8",
        c,
        a,
        1,
        "compare_ore_cllw_u64_8(c, a) should equal 1"
    );
    assert_compare!(
        &pool,
        "compare_ore_cllw_u64_8",
        c,
        b,
        1,
        "compare_ore_cllw_u64_8(c, b) should equal 1"
    );

    Ok(())
}

//
// ORE CLLW VAR Comparison Tests
//

#[sqlx::test]
async fn ore_cllw_var_compare_equal(pool: PgPool) -> Result<()> {
    // Test: compare_ore_cllw_var_8() with equal values
    // Original SQL: src/ore_cllw_var_8/compare_test.sql lines 16,20,24
    //
    // {"hello": "world{N}"}
    // $.hello: d90b97b5207d30fe867ca816ed0fe4a7

    let a = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(1), 'd90b97b5207d30fe867ca816ed0fe4a7')";
    let b = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(2), 'd90b97b5207d30fe867ca816ed0fe4a7')";
    let c = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(3), 'd90b97b5207d30fe867ca816ed0fe4a7')";

    // 3 assertions: a=a, b=b, c=c should all return 0
    assert_compare!(
        &pool,
        "compare_ore_cllw_var_8",
        a,
        a,
        0,
        "compare_ore_cllw_var_8(a, a) should equal 0"
    );
    assert_compare!(
        &pool,
        "compare_ore_cllw_var_8",
        b,
        b,
        0,
        "compare_ore_cllw_var_8(b, b) should equal 0"
    );
    assert_compare!(
        &pool,
        "compare_ore_cllw_var_8",
        c,
        c,
        0,
        "compare_ore_cllw_var_8(c, c) should equal 0"
    );

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_var_compare_less_than(pool: PgPool) -> Result<()> {
    // Test: compare_ore_cllw_var_8() with less than comparisons
    // Original SQL: src/ore_cllw_var_8/compare_test.sql lines 17,18,22,26
    //
    // {"hello": "world{N}"}
    // $.hello: d90b97b5207d30fe867ca816ed0fe4a7

    let a = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(1), 'd90b97b5207d30fe867ca816ed0fe4a7')";
    let b = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(2), 'd90b97b5207d30fe867ca816ed0fe4a7')";
    let c = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(3), 'd90b97b5207d30fe867ca816ed0fe4a7')";

    // 3 assertions: a<b, a<c, b<c should all return -1
    assert_compare!(
        &pool,
        "compare_ore_cllw_var_8",
        a,
        b,
        -1,
        "compare_ore_cllw_var_8(a, b) should equal -1"
    );
    assert_compare!(
        &pool,
        "compare_ore_cllw_var_8",
        a,
        c,
        -1,
        "compare_ore_cllw_var_8(a, c) should equal -1"
    );
    assert_compare!(
        &pool,
        "compare_ore_cllw_var_8",
        b,
        c,
        -1,
        "compare_ore_cllw_var_8(b, c) should equal -1"
    );

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_var_compare_greater_than(pool: PgPool) -> Result<()> {
    // Test: compare_ore_cllw_var_8() with greater than comparisons
    // Original SQL: src/ore_cllw_var_8/compare_test.sql lines 21,25,26
    //
    // {"hello": "world{N}"}
    // $.hello: d90b97b5207d30fe867ca816ed0fe4a7

    let a = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(1), 'd90b97b5207d30fe867ca816ed0fe4a7')";
    let b = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(2), 'd90b97b5207d30fe867ca816ed0fe4a7')";
    let c = "eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(3), 'd90b97b5207d30fe867ca816ed0fe4a7')";

    // 3 assertions: b>a, c>a, c>b should all return 1
    assert_compare!(
        &pool,
        "compare_ore_cllw_var_8",
        b,
        a,
        1,
        "compare_ore_cllw_var_8(b, a) should equal 1"
    );
    assert_compare!(
        &pool,
        "compare_ore_cllw_var_8",
        c,
        a,
        1,
        "compare_ore_cllw_var_8(c, a) should equal 1"
    );
    assert_compare!(
        &pool,
        "compare_ore_cllw_var_8",
        c,
        b,
        1,
        "compare_ore_cllw_var_8(c, b) should equal 1"
    );

    Ok(())
}
