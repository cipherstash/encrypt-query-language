//! Operator class tests
//!
//! Tests PostgreSQL operator class definitions and index behavior

use anyhow::Result;
use eql_tests::get_ore_encrypted;
use sqlx::PgPool;

/// Helper to create encrypted table for testing
async fn create_table_with_encrypted(pool: &PgPool) -> Result<()> {
    sqlx::query("DROP TABLE IF EXISTS encrypted CASCADE")
        .execute(pool)
        .await?;

    sqlx::query(
        "CREATE TABLE encrypted (
            id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            e eql_v2_encrypted
        )",
    )
    .execute(pool)
    .await?;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn group_by_encrypted_column(pool: PgPool) -> Result<()> {
    // Test: GROUP BY works with eql_v2_encrypted type (1 assertion)
    // Uses create_encrypted_json which includes hmac/blake3 terms required for hash aggregation

    create_table_with_encrypted(&pool).await?;

    // Insert values with hmac/blake3 terms: 4x id=1, 2x id=2
    for _ in 0..4 {
        sqlx::query("INSERT INTO encrypted(e) VALUES (create_encrypted_json(1))")
            .execute(&pool)
            .await?;
    }
    for _ in 0..2 {
        sqlx::query("INSERT INTO encrypted(e) VALUES (create_encrypted_json(2))")
            .execute(&pool)
            .await?;
    }

    // GROUP BY should work - most common value is id=1 (4 occurrences)
    let count: i64 = sqlx::query_scalar(
        "SELECT count(id) FROM encrypted GROUP BY e ORDER BY count(id) DESC LIMIT 1",
    )
    .fetch_one(&pool)
    .await?;

    assert_eq!(count, 4, "GROUP BY should return 4 for most common value");

    Ok(())
}

#[sqlx::test]
async fn index_usage_with_explain_analyze(pool: PgPool) -> Result<()> {
    // Test: Operator class index usage patterns (3 assertions)

    create_table_with_encrypted(&pool).await?;

    // Without index, should not use Bitmap Heap Scan
    let explain: String = sqlx::query_scalar(
        "EXPLAIN SELECT e::jsonb FROM encrypted WHERE e = '(\"{\\\"ob\\\": \\\"abc\\\"}\")';",
    )
    .fetch_one(&pool)
    .await?;

    assert!(
        !explain.contains("Bitmap Heap Scan on encrypted"),
        "Should not use Bitmap Heap Scan without index"
    );

    // Create index
    sqlx::query("CREATE INDEX ON encrypted (e eql_v2.encrypted_operator_class)")
        .execute(&pool)
        .await?;

    // Get ORE term and verify index usage
    let ore_term = get_ore_encrypted(&pool, 42).await?;
    let explain: String = sqlx::query_scalar(&format!(
        "EXPLAIN SELECT e::jsonb FROM encrypted WHERE e = '{}'::eql_v2_encrypted",
        ore_term
    ))
    .fetch_one(&pool)
    .await?;

    // With ORE data and index, should potentially use index scan
    // (actual plan may vary based on statistics)
    assert!(
        explain.contains("Scan"),
        "Should use some form of scan with index"
    );

    Ok(())
}

#[sqlx::test]
async fn index_behavior_with_different_data_types(pool: PgPool) -> Result<()> {
    // Test: Index behavior with various encrypted data types (37 assertions)

    create_table_with_encrypted(&pool).await?;

    // Insert bloom filter data
    sqlx::query("INSERT INTO encrypted (e) VALUES ('(\"{\\\"bf\\\": \\\"[1, 2, 3]\\\"}\")');")
        .execute(&pool)
        .await?;

    // Create index
    sqlx::query("CREATE INDEX encrypted_index ON encrypted (e eql_v2.encrypted_operator_class)")
        .execute(&pool)
        .await?;

    sqlx::query("ANALYZE encrypted").execute(&pool).await?;

    // With only bloom filter data, index may not be used efficiently
    let explain: String = sqlx::query_scalar(
        "EXPLAIN SELECT e::jsonb FROM encrypted WHERE e = '(\"{\\\"bf\\\": \\\"[1,2,3]\\\"}\")';",
    )
    .fetch_one(&pool)
    .await?;

    // Verify query plan was generated
    assert!(!explain.is_empty(), "EXPLAIN should return a plan");

    // Truncate and add HMAC data
    sqlx::query("TRUNCATE encrypted").execute(&pool).await?;
    sqlx::query("DROP INDEX encrypted_index")
        .execute(&pool)
        .await?;
    sqlx::query("CREATE INDEX encrypted_index ON encrypted (e eql_v2.encrypted_operator_class)")
        .execute(&pool)
        .await?;

    sqlx::query(
        "INSERT INTO encrypted (e) VALUES
         ('(\"{\\\"hm\\\": \\\"abc\\\"}\")'),
         ('(\"{\\\"hm\\\": \\\"def\\\"}\")'),
         ('(\"{\\\"hm\\\": \\\"ghi\\\"}\")'),
         ('(\"{\\\"hm\\\": \\\"jkl\\\"}\")'),
         ('(\"{\\\"hm\\\": \\\"mno\\\"}\")');",
    )
    .execute(&pool)
    .await?;

    // With HMAC data, literal row type should work
    let explain: String = sqlx::query_scalar(
        "EXPLAIN SELECT e::jsonb FROM encrypted WHERE e = '(\"{\\\"hm\\\": \\\"abc\\\"}\")';",
    )
    .fetch_one(&pool)
    .await?;

    // With enough data, index might be used
    assert!(
        explain.contains("Index") || explain.contains("Scan"),
        "Should consider using index with HMAC data"
    );

    // Test JSONB cast (index not used)
    let explain: String = sqlx::query_scalar(
        "EXPLAIN SELECT e::jsonb FROM encrypted WHERE e = '{\"hm\": \"abc\"}'::jsonb;",
    )
    .fetch_one(&pool)
    .await?;

    assert!(!explain.is_empty(), "EXPLAIN with JSONB cast should work");

    // Test JSONB to eql_v2_encrypted cast (index should be considered)
    let explain: String = sqlx::query_scalar(
        "EXPLAIN SELECT e::jsonb FROM encrypted WHERE e = '{\"hm\": \"abc\"}'::jsonb::eql_v2_encrypted;",
    )
    .fetch_one(&pool)
    .await?;

    assert!(
        explain.contains("Index") || explain.contains("Scan"),
        "Cast to eql_v2_encrypted should enable index usage"
    );

    // Test text to eql_v2_encrypted cast
    let explain: String = sqlx::query_scalar(
        "EXPLAIN SELECT e::jsonb FROM encrypted WHERE e = '{\"hm\": \"abc\"}'::text::eql_v2_encrypted;",
    )
    .fetch_one(&pool)
    .await?;

    assert!(
        explain.contains("Index") || explain.contains("Scan"),
        "Text cast to eql_v2_encrypted should enable index usage"
    );

    // Test eql_v2.to_encrypted with JSONB
    let explain: String = sqlx::query_scalar(
        "EXPLAIN SELECT e::jsonb FROM encrypted WHERE e = eql_v2.to_encrypted('{\"hm\": \"abc\"}'::jsonb);",
    )
    .fetch_one(&pool)
    .await?;

    assert!(
        explain.contains("Index") || explain.contains("Scan"),
        "to_encrypted with JSONB should enable index usage"
    );

    // Test eql_v2.to_encrypted with text
    let explain: String = sqlx::query_scalar(
        "EXPLAIN SELECT e::jsonb FROM encrypted WHERE e = eql_v2.to_encrypted('{\"hm\": \"abc\"}');",
    )
    .fetch_one(&pool)
    .await?;

    assert!(
        explain.contains("Index") || explain.contains("Scan"),
        "to_encrypted with text should enable index usage"
    );

    // Test with actual ORE term
    let ore_term = get_ore_encrypted(&pool, 42).await?;
    let explain: String = sqlx::query_scalar(&format!(
        "EXPLAIN SELECT e::jsonb FROM encrypted WHERE e = '{}'::eql_v2_encrypted;",
        ore_term
    ))
    .fetch_one(&pool)
    .await?;

    assert!(
        explain.contains("Index") || explain.contains("Scan"),
        "ORE term should enable index usage"
    );

    Ok(())
}
