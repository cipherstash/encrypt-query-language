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
async fn compare_ore_cllw_var_8_hello_path(pool: PgPool) -> Result<()> {
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
async fn compare_ore_cllw_var_8_number_path(pool: PgPool) -> Result<()> {
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

#[sqlx::test]
async fn compare_blake3_index(pool: PgPool) -> Result<()> {
    // Test: compare() with Blake3 index

    let a = "create_encrypted_json(1, 'b3')";
    let b = "create_encrypted_json(2, 'b3')";
    let c = "create_encrypted_json(3, 'b3')";

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
async fn compare_hmac_256_index(pool: PgPool) -> Result<()> {
    // Test: compare() with HMAC 256 index

    let a = "create_encrypted_json(1, 'hm')";
    let b = "create_encrypted_json(2, 'hm')";
    let c = "create_encrypted_json(3, 'hm')";

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
async fn compare_no_index_terms(pool: PgPool) -> Result<()> {
    // Test: compare() with no index terms (fallback to literal comparison)

    let a = "'{\"a\": 1}'::jsonb::eql_v2_encrypted";
    let b = "'{\"b\": 2}'::jsonb::eql_v2_encrypted";
    let c = "'{\"c\": 3}'::jsonb::eql_v2_encrypted";

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
async fn compare_hmac_with_null_ore_index(pool: PgPool) -> Result<()> {
    // Test: compare() with HMAC when record has null ORE index of higher precedence
    //
    // BUG FIX COVERAGE:
    // ORE Block indexes 'ob' are used in compare before hmac_256 indexes.
    // If the index term is null {"ob": null} it should not be used.
    // Comparing two null values is evaluated as equality which is incorrect.

    let a = "('{\"ob\": null}'::jsonb || create_encrypted_json(1, 'hm')::jsonb)::eql_v2_encrypted";
    let b = "('{\"ob\": null}'::jsonb || create_encrypted_json(2, 'hm')::jsonb)::eql_v2_encrypted";
    let c = "('{\"ob\": null}'::jsonb || create_encrypted_json(3, 'hm')::jsonb)::eql_v2_encrypted";

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
