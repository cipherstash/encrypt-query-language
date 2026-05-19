//! Index-specific comparison function tests
//!
//! Tests the index-specific compare functions:
//! - compare_blake3()
//! - compare_hmac_256()
//! - compare_ore_block_u64_8_256()
//! - compare_ore_cllw()
//! - compare_ore_cllw()
//!
//! - src/blake3/compare_test.sql
//! - src/hmac_256/compare_test.sql
//! - src/ore_block_u64_8_256/compare_test.sql
//! - src/ore_cllw/compare_test.sql
//! - src/ore_cllw/compare_test.sql

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

// blake3_compare_{equal,less_than,greater_than} removed: they tested
// compare_blake3 against root-level b3-only payloads created by
// create_encrypted_json(id, 'b3'). With b3 removed from the synthetic
// base payload, those payloads no longer carry b3 and the tests are
// no longer meaningful at the root. compare_blake3 still exists and
// is exercised through ste_vec internal element comparisons.

//
// HMAC-256 Index Comparison Tests
//

#[sqlx::test]
async fn hmac_compare_equal(pool: PgPool) -> Result<()> {
    // Test: compare_hmac_256() with equal values

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
    // Test: compare_ore_cllw() with equal values
    //
    // {"number": {N}}
    // $.number: 3dba004f4d7823446e7cb71f6681b344

    let a = "((eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(1), '3dba004f4d7823446e7cb71f6681b344')).data)::eql_v2.ste_vec_entry";
    let b = "((eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(5), '3dba004f4d7823446e7cb71f6681b344')).data)::eql_v2.ste_vec_entry";
    let c = "((eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(10), '3dba004f4d7823446e7cb71f6681b344')).data)::eql_v2.ste_vec_entry";

    // 3 assertions: a=a, b=b, c=c should all return 0
    assert_compare!(
        &pool,
        "compare",
        a,
        a,
        0,
        "compare_ore_cllw(a, a) should equal 0"
    );
    assert_compare!(
        &pool,
        "compare",
        b,
        b,
        0,
        "compare_ore_cllw(b, b) should equal 0"
    );
    assert_compare!(
        &pool,
        "compare",
        c,
        c,
        0,
        "compare_ore_cllw(c, c) should equal 0"
    );

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_u64_compare_less_than(pool: PgPool) -> Result<()> {
    // Test: compare_ore_cllw() with less than comparisons
    //
    // {"number": {N}}
    // $.number: 3dba004f4d7823446e7cb71f6681b344

    let a = "((eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(1), '3dba004f4d7823446e7cb71f6681b344')).data)::eql_v2.ste_vec_entry";
    let b = "((eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(5), '3dba004f4d7823446e7cb71f6681b344')).data)::eql_v2.ste_vec_entry";
    let c = "((eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(10), '3dba004f4d7823446e7cb71f6681b344')).data)::eql_v2.ste_vec_entry";

    // 3 assertions: a<b, a<c, b<c should all return -1
    assert_compare!(
        &pool,
        "compare",
        a,
        b,
        -1,
        "compare_ore_cllw(a, b) should equal -1"
    );
    assert_compare!(
        &pool,
        "compare",
        a,
        c,
        -1,
        "compare_ore_cllw(a, c) should equal -1"
    );
    assert_compare!(
        &pool,
        "compare",
        b,
        c,
        -1,
        "compare_ore_cllw(b, c) should equal -1"
    );

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_u64_compare_greater_than(pool: PgPool) -> Result<()> {
    // Test: compare_ore_cllw() with greater than comparisons
    //
    // {"number": {N}}
    // $.number: 3dba004f4d7823446e7cb71f6681b344

    let a = "((eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(1), '3dba004f4d7823446e7cb71f6681b344')).data)::eql_v2.ste_vec_entry";
    let b = "((eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(5), '3dba004f4d7823446e7cb71f6681b344')).data)::eql_v2.ste_vec_entry";
    let c = "((eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(10), '3dba004f4d7823446e7cb71f6681b344')).data)::eql_v2.ste_vec_entry";

    // 3 assertions: b>a, c>a, c>b should all return 1
    assert_compare!(
        &pool,
        "compare",
        b,
        a,
        1,
        "compare_ore_cllw(b, a) should equal 1"
    );
    assert_compare!(
        &pool,
        "compare",
        c,
        a,
        1,
        "compare_ore_cllw(c, a) should equal 1"
    );
    assert_compare!(
        &pool,
        "compare",
        c,
        b,
        1,
        "compare_ore_cllw(c, b) should equal 1"
    );

    Ok(())
}

//
// ORE CLLW VAR Comparison Tests
//

#[sqlx::test]
async fn ore_cllw_var_compare_equal(pool: PgPool) -> Result<()> {
    // Test: compare_ore_cllw() with equal values
    //
    // {"hello": "world{N}"}
    // $.hello: d90b97b5207d30fe867ca816ed0fe4a7

    let a = "((eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(1), 'd90b97b5207d30fe867ca816ed0fe4a7')).data)::eql_v2.ste_vec_entry";
    let b = "((eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(2), 'd90b97b5207d30fe867ca816ed0fe4a7')).data)::eql_v2.ste_vec_entry";
    let c = "((eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(3), 'd90b97b5207d30fe867ca816ed0fe4a7')).data)::eql_v2.ste_vec_entry";

    // 3 assertions: a=a, b=b, c=c should all return 0
    assert_compare!(
        &pool,
        "compare",
        a,
        a,
        0,
        "compare_ore_cllw(a, a) should equal 0"
    );
    assert_compare!(
        &pool,
        "compare",
        b,
        b,
        0,
        "compare_ore_cllw(b, b) should equal 0"
    );
    assert_compare!(
        &pool,
        "compare",
        c,
        c,
        0,
        "compare_ore_cllw(c, c) should equal 0"
    );

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_var_compare_less_than(pool: PgPool) -> Result<()> {
    // Test: compare_ore_cllw() with less than comparisons
    //
    // {"hello": "world{N}"}
    // $.hello: d90b97b5207d30fe867ca816ed0fe4a7

    let a = "((eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(1), 'd90b97b5207d30fe867ca816ed0fe4a7')).data)::eql_v2.ste_vec_entry";
    let b = "((eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(2), 'd90b97b5207d30fe867ca816ed0fe4a7')).data)::eql_v2.ste_vec_entry";
    let c = "((eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(3), 'd90b97b5207d30fe867ca816ed0fe4a7')).data)::eql_v2.ste_vec_entry";

    // 3 assertions: a<b, a<c, b<c should all return -1
    assert_compare!(
        &pool,
        "compare",
        a,
        b,
        -1,
        "compare_ore_cllw(a, b) should equal -1"
    );
    assert_compare!(
        &pool,
        "compare",
        a,
        c,
        -1,
        "compare_ore_cllw(a, c) should equal -1"
    );
    assert_compare!(
        &pool,
        "compare",
        b,
        c,
        -1,
        "compare_ore_cllw(b, c) should equal -1"
    );

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_var_compare_greater_than(pool: PgPool) -> Result<()> {
    // Test: compare_ore_cllw() with greater than comparisons
    //
    // {"hello": "world{N}"}
    // $.hello: d90b97b5207d30fe867ca816ed0fe4a7

    let a = "((eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(1), 'd90b97b5207d30fe867ca816ed0fe4a7')).data)::eql_v2.ste_vec_entry";
    let b = "((eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(2), 'd90b97b5207d30fe867ca816ed0fe4a7')).data)::eql_v2.ste_vec_entry";
    let c = "((eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(3), 'd90b97b5207d30fe867ca816ed0fe4a7')).data)::eql_v2.ste_vec_entry";

    // 3 assertions: b>a, c>a, c>b should all return 1
    assert_compare!(
        &pool,
        "compare",
        b,
        a,
        1,
        "compare_ore_cllw(b, a) should equal 1"
    );
    assert_compare!(
        &pool,
        "compare",
        c,
        a,
        1,
        "compare_ore_cllw(c, a) should equal 1"
    );
    assert_compare!(
        &pool,
        "compare",
        c,
        b,
        1,
        "compare_ore_cllw(c, b) should equal 1"
    );

    Ok(())
}
