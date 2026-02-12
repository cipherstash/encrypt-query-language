//! Hash operator tests
//!
//! Tests PostgreSQL hash operator class for encrypted values.
//! Verifies hash joins, GROUP BY, DISTINCT, and error handling.

use anyhow::{Context, Result};
use sqlx::PgPool;

/// Helper to create a fresh table for hash operator testing
async fn create_hash_test_table(pool: &PgPool, table: &str) -> Result<()> {
    sqlx::query(&format!("DROP TABLE IF EXISTS {} CASCADE", table))
        .execute(pool)
        .await?;

    sqlx::query(&format!(
        "CREATE TABLE {} (
            id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            e eql_v2_encrypted
        )",
        table
    ))
    .execute(pool)
    .await?;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn hash_join_between_two_tables(pool: PgPool) -> Result<()> {
    // Test: Hash join works between two tables with encrypted columns
    // This is the core bug scenario - cross-row joins that trigger hash join strategy

    create_hash_test_table(&pool, "hash_left").await?;
    create_hash_test_table(&pool, "hash_right").await?;

    // Insert matching encrypted values (same id -> same hmac/blake3)
    for id in 1..=3 {
        let sql = format!(
            "INSERT INTO hash_left(e) VALUES (create_encrypted_json({}))",
            id
        );
        sqlx::query(&sql).execute(&pool).await?;

        let sql = format!(
            "INSERT INTO hash_right(e) VALUES (create_encrypted_json({}))",
            id
        );
        sqlx::query(&sql).execute(&pool).await?;
    }

    // Join should find 3 matching rows (one per id)
    let count: i64 =
        sqlx::query_scalar("SELECT count(*) FROM hash_left l JOIN hash_right r ON l.e = r.e")
            .fetch_one(&pool)
            .await
            .context("hash join between two tables failed")?;

    assert_eq!(count, 3, "Hash join should find 3 matching rows");

    // Cleanup
    sqlx::query("DROP TABLE IF EXISTS hash_left, hash_right CASCADE")
        .execute(&pool)
        .await?;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn group_by_with_hash_aggregate(pool: PgPool) -> Result<()> {
    // Test: GROUP BY works with hash aggregation on encrypted columns

    create_hash_test_table(&pool, "hash_group").await?;

    // Insert duplicates: 4x id=1, 2x id=2, 1x id=3
    for _ in 0..4 {
        sqlx::query("INSERT INTO hash_group(e) VALUES (create_encrypted_json(1))")
            .execute(&pool)
            .await?;
    }
    for _ in 0..2 {
        sqlx::query("INSERT INTO hash_group(e) VALUES (create_encrypted_json(2))")
            .execute(&pool)
            .await?;
    }
    sqlx::query("INSERT INTO hash_group(e) VALUES (create_encrypted_json(3))")
        .execute(&pool)
        .await?;

    // GROUP BY should produce 3 groups
    let group_count: i64 =
        sqlx::query_scalar("SELECT count(*) FROM (SELECT e FROM hash_group GROUP BY e) sub")
            .fetch_one(&pool)
            .await
            .context("GROUP BY on encrypted column failed")?;

    assert_eq!(group_count, 3, "GROUP BY should produce 3 groups");

    // Verify the largest group has 4 members
    let max_count: i64 = sqlx::query_scalar(
        "SELECT count(*) as cnt FROM hash_group GROUP BY e ORDER BY cnt DESC LIMIT 1",
    )
    .fetch_one(&pool)
    .await?;

    assert_eq!(max_count, 4, "Largest group should have 4 members");

    // Cleanup
    sqlx::query("DROP TABLE IF EXISTS hash_group CASCADE")
        .execute(&pool)
        .await?;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn distinct_on_encrypted_column(pool: PgPool) -> Result<()> {
    // Test: DISTINCT works on encrypted columns using hash-based deduplication

    create_hash_test_table(&pool, "hash_distinct").await?;

    // Insert duplicates: 3x id=1, 2x id=2
    for _ in 0..3 {
        sqlx::query("INSERT INTO hash_distinct(e) VALUES (create_encrypted_json(1))")
            .execute(&pool)
            .await?;
    }
    for _ in 0..2 {
        sqlx::query("INSERT INTO hash_distinct(e) VALUES (create_encrypted_json(2))")
            .execute(&pool)
            .await?;
    }

    // DISTINCT should return 2 unique values
    let distinct_count: i64 =
        sqlx::query_scalar("SELECT count(*) FROM (SELECT DISTINCT e FROM hash_distinct) sub")
            .fetch_one(&pool)
            .await
            .context("DISTINCT on encrypted column failed")?;

    assert_eq!(distinct_count, 2, "DISTINCT should return 2 unique values");

    // Cleanup
    sqlx::query("DROP TABLE IF EXISTS hash_distinct CASCADE")
        .execute(&pool)
        .await?;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn self_join_with_encrypted_column(pool: PgPool) -> Result<()> {
    // Test: Self-join works on encrypted column

    create_hash_test_table(&pool, "hash_self").await?;

    // Insert 3 rows with different encrypted values
    for id in 1..=3 {
        sqlx::query(&format!(
            "INSERT INTO hash_self(e) VALUES (create_encrypted_json({}))",
            id
        ))
        .execute(&pool)
        .await?;
    }

    // Self-join should match each row with itself (3 matches on diagonal)
    let count: i64 =
        sqlx::query_scalar("SELECT count(*) FROM hash_self a JOIN hash_self b ON a.e = b.e")
            .fetch_one(&pool)
            .await
            .context("self-join on encrypted column failed")?;

    assert_eq!(count, 3, "Self-join should produce 3 matches");

    // Cleanup
    sqlx::query("DROP TABLE IF EXISTS hash_self CASCADE")
        .execute(&pool)
        .await?;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn hash_function_directly(pool: PgPool) -> Result<()> {
    // Test: eql_v2.hash_encrypted() returns consistent values

    // Same encrypted value should produce same hash
    let hash1: i32 = sqlx::query_scalar("SELECT eql_v2.hash_encrypted(create_encrypted_json(1))")
        .fetch_one(&pool)
        .await
        .context("hash_encrypted call 1 failed")?;

    let hash2: i32 = sqlx::query_scalar("SELECT eql_v2.hash_encrypted(create_encrypted_json(1))")
        .fetch_one(&pool)
        .await
        .context("hash_encrypted call 2 failed")?;

    assert_eq!(
        hash1, hash2,
        "Same encrypted value should produce same hash"
    );

    // Different encrypted values may produce different hashes (very likely but not guaranteed)
    let hash3: i32 = sqlx::query_scalar("SELECT eql_v2.hash_encrypted(create_encrypted_json(2))")
        .fetch_one(&pool)
        .await
        .context("hash_encrypted call 3 failed")?;

    // While hash collisions are theoretically possible, these test values should differ
    assert_ne!(
        hash1, hash3,
        "Different encrypted values should (almost certainly) produce different hashes"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn hash_function_uses_blake3_first(pool: PgPool) -> Result<()> {
    // Test: hash_encrypted prefers Blake3 over HMAC to maintain hash/equality contract.
    // compare() uses the first index term in BOTH operands (ORE > HMAC > Blake3).
    // If value A has hm+b3 and value B has only b3, compare uses Blake3.
    // hash_encrypted must also use Blake3 for A so hash(A) == hash(B).

    // Create value with only Blake3 index term
    let hash_b3: i32 =
        sqlx::query_scalar("SELECT eql_v2.hash_encrypted(create_encrypted_json(1, 'b3'))")
            .fetch_one(&pool)
            .await
            .context("hash with blake3-only failed")?;

    // Create value with both HMAC and Blake3 - should use Blake3 (same hash)
    let hash_both: i32 =
        sqlx::query_scalar("SELECT eql_v2.hash_encrypted(create_encrypted_json(1, 'hm', 'b3'))")
            .fetch_one(&pool)
            .await
            .context("hash with hmac+blake3 failed")?;

    assert_eq!(
        hash_b3, hash_both,
        "Hash with both indexes should use Blake3 (same as Blake3-only)"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn hash_function_falls_back_to_hmac(pool: PgPool) -> Result<()> {
    // Test: hash_encrypted uses HMAC when Blake3 is not available

    let hash: i32 =
        sqlx::query_scalar("SELECT eql_v2.hash_encrypted(create_encrypted_json(1, 'hm'))")
            .fetch_one(&pool)
            .await
            .context("hash with hmac-only failed")?;

    // Just verify it returns a value without error
    // The actual hash value is implementation-dependent
    let _ = hash;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn hash_function_errors_without_hash_index(pool: PgPool) -> Result<()> {
    // Test: hash_encrypted raises error when no HMAC or Blake3 index is present

    // Create value with only ORE index (no hmac, no blake3)
    let result = sqlx::query_scalar::<_, i32>(
        "SELECT eql_v2.hash_encrypted(create_encrypted_json(1, 'ob'))",
    )
    .fetch_one(&pool)
    .await;

    assert!(
        result.is_err(),
        "hash_encrypted should error with ORE-only value"
    );

    let err_msg = result.unwrap_err().to_string();
    assert!(
        err_msg.contains("hmac_256 or blake3"),
        "Error should mention missing index terms, got: {}",
        err_msg
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn union_on_encrypted_columns(pool: PgPool) -> Result<()> {
    // Test: UNION (which uses hash-based deduplication) works on encrypted columns

    create_hash_test_table(&pool, "hash_union_a").await?;
    create_hash_test_table(&pool, "hash_union_b").await?;

    // Table A has ids 1, 2
    sqlx::query("INSERT INTO hash_union_a(e) VALUES (create_encrypted_json(1))")
        .execute(&pool)
        .await?;
    sqlx::query("INSERT INTO hash_union_a(e) VALUES (create_encrypted_json(2))")
        .execute(&pool)
        .await?;

    // Table B has ids 2, 3 (id=2 overlaps)
    sqlx::query("INSERT INTO hash_union_b(e) VALUES (create_encrypted_json(2))")
        .execute(&pool)
        .await?;
    sqlx::query("INSERT INTO hash_union_b(e) VALUES (create_encrypted_json(3))")
        .execute(&pool)
        .await?;

    // UNION should deduplicate, returning 3 unique values
    let count: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM (
            SELECT e FROM hash_union_a
            UNION
            SELECT e FROM hash_union_b
        ) sub",
    )
    .fetch_one(&pool)
    .await
    .context("UNION on encrypted columns failed")?;

    assert_eq!(count, 3, "UNION should return 3 unique values (1, 2, 3)");

    // Cleanup
    sqlx::query("DROP TABLE IF EXISTS hash_union_a, hash_union_b CASCADE")
        .execute(&pool)
        .await?;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn in_subquery_with_encrypted_column(pool: PgPool) -> Result<()> {
    // Test: IN (subquery) works with encrypted columns

    create_hash_test_table(&pool, "hash_in_main").await?;
    create_hash_test_table(&pool, "hash_in_sub").await?;

    // Main table has ids 1, 2, 3
    for id in 1..=3 {
        sqlx::query(&format!(
            "INSERT INTO hash_in_main(e) VALUES (create_encrypted_json({}))",
            id
        ))
        .execute(&pool)
        .await?;
    }

    // Subquery table has only id 1, 3
    sqlx::query("INSERT INTO hash_in_sub(e) VALUES (create_encrypted_json(1))")
        .execute(&pool)
        .await?;
    sqlx::query("INSERT INTO hash_in_sub(e) VALUES (create_encrypted_json(3))")
        .execute(&pool)
        .await?;

    // IN subquery should return 2 rows
    let count: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM hash_in_main WHERE e IN (SELECT e FROM hash_in_sub)",
    )
    .fetch_one(&pool)
    .await
    .context("IN subquery on encrypted column failed")?;

    assert_eq!(count, 2, "IN subquery should return 2 matching rows");

    // Cleanup
    sqlx::query("DROP TABLE IF EXISTS hash_in_main, hash_in_sub CASCADE")
        .execute(&pool)
        .await?;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn hash_consistency_full_index_matches_blake3_only(pool: PgPool) -> Result<()> {
    // Test: hash of full-index value matches hash of Blake3-only value
    // The hash function uses Blake3 first, so full value (with b3) should produce same hash as b3-only

    let hash_full: i32 =
        sqlx::query_scalar("SELECT eql_v2.hash_encrypted(create_encrypted_json(1))")
            .fetch_one(&pool)
            .await
            .context("hash of full value failed")?;

    let hash_b3_only: i32 =
        sqlx::query_scalar("SELECT eql_v2.hash_encrypted(create_encrypted_json(1, 'b3'))")
            .fetch_one(&pool)
            .await
            .context("hash of blake3-only value failed")?;

    assert_eq!(
        hash_full, hash_b3_only,
        "Full-index hash should match Blake3-only hash (Blake3 priority)"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn hmac_and_blake3_produce_different_hashes(pool: PgPool) -> Result<()> {
    // Test: HMAC and Blake3 code paths produce different hashes for same id
    // Catches regression where the wrong branch is taken

    let hash_hmac: i32 =
        sqlx::query_scalar("SELECT eql_v2.hash_encrypted(create_encrypted_json(1, 'hm'))")
            .fetch_one(&pool)
            .await
            .context("hash with hmac-only failed")?;

    let hash_b3: i32 =
        sqlx::query_scalar("SELECT eql_v2.hash_encrypted(create_encrypted_json(1, 'b3'))")
            .fetch_one(&pool)
            .await
            .context("hash with blake3-only failed")?;

    assert_ne!(
        hash_hmac, hash_b3,
        "HMAC and Blake3 should produce different hashes for same id"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn ste_vec_wrapped_hashes_same_as_unwrapped(pool: PgPool) -> Result<()> {
    // Test: single-element STE vec wrapper produces same hash as inner value
    // The hash function calls to_ste_vec_value() which unwraps single-element vectors

    let hash_wrapped: i32 = sqlx::query_scalar(
        r#"SELECT eql_v2.hash_encrypted(
            ('{"sv": [{"b3": "blake3.1"}]}'::jsonb)::eql_v2_encrypted
        )"#,
    )
    .fetch_one(&pool)
    .await
    .context("hash of wrapped STE vec failed")?;

    let hash_unwrapped: i32 = sqlx::query_scalar(
        r#"SELECT eql_v2.hash_encrypted(
            ('{"b3": "blake3.1"}'::jsonb)::eql_v2_encrypted
        )"#,
    )
    .fetch_one(&pool)
    .await
    .context("hash of unwrapped value failed")?;

    assert_eq!(
        hash_wrapped, hash_unwrapped,
        "Single-element STE vec should hash same as unwrapped inner value"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn multi_element_ste_vec_raises_error(pool: PgPool) -> Result<()> {
    // Test: multi-element STE vec cannot be hashed (no top-level hm/b3 keys)

    let result = sqlx::query_scalar::<_, i32>(
        "SELECT eql_v2.hash_encrypted((get_array_ste_vec())::eql_v2_encrypted)",
    )
    .fetch_one(&pool)
    .await;

    assert!(
        result.is_err(),
        "hash_encrypted should error with multi-element STE vec"
    );

    let err_msg = result.unwrap_err().to_string();
    assert!(
        err_msg.contains("hmac_256 or blake3"),
        "Error should mention missing index terms, got: {}",
        err_msg
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn group_by_with_null_encrypted_values(pool: PgPool) -> Result<()> {
    // Test: GROUP BY correctly handles NULL encrypted values
    // PostgreSQL groups NULLs together; hash_encrypted is STRICT so NULL returns NULL

    create_hash_test_table(&pool, "hash_null_group").await?;

    // Insert: 2x id=1, 2x NULL -> should produce 2 groups (id=1, NULL)
    sqlx::query("INSERT INTO hash_null_group(e) VALUES (create_encrypted_json(1))")
        .execute(&pool)
        .await?;
    sqlx::query("INSERT INTO hash_null_group(e) VALUES (create_encrypted_json(1))")
        .execute(&pool)
        .await?;
    sqlx::query("INSERT INTO hash_null_group(e) VALUES (NULL)")
        .execute(&pool)
        .await?;
    sqlx::query("INSERT INTO hash_null_group(e) VALUES (NULL)")
        .execute(&pool)
        .await?;

    let group_count: i64 =
        sqlx::query_scalar("SELECT count(*) FROM (SELECT e FROM hash_null_group GROUP BY e) sub")
            .fetch_one(&pool)
            .await
            .context("GROUP BY with NULLs failed")?;

    assert_eq!(
        group_count, 2,
        "GROUP BY should produce 2 groups (id=1 and NULL)"
    );

    // Cleanup
    sqlx::query("DROP TABLE IF EXISTS hash_null_group CASCADE")
        .execute(&pool)
        .await?;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn distinct_with_null_encrypted_values(pool: PgPool) -> Result<()> {
    // Test: DISTINCT correctly handles NULL encrypted values

    create_hash_test_table(&pool, "hash_null_distinct").await?;

    // Insert: 2x id=1, 2x NULL -> DISTINCT should return 2
    sqlx::query("INSERT INTO hash_null_distinct(e) VALUES (create_encrypted_json(1))")
        .execute(&pool)
        .await?;
    sqlx::query("INSERT INTO hash_null_distinct(e) VALUES (create_encrypted_json(1))")
        .execute(&pool)
        .await?;
    sqlx::query("INSERT INTO hash_null_distinct(e) VALUES (NULL)")
        .execute(&pool)
        .await?;
    sqlx::query("INSERT INTO hash_null_distinct(e) VALUES (NULL)")
        .execute(&pool)
        .await?;

    let distinct_count: i64 =
        sqlx::query_scalar("SELECT count(*) FROM (SELECT DISTINCT e FROM hash_null_distinct) sub")
            .fetch_one(&pool)
            .await
            .context("DISTINCT with NULLs failed")?;

    assert_eq!(
        distinct_count, 2,
        "DISTINCT should return 2 values (id=1 and NULL)"
    );

    // Cleanup
    sqlx::query("DROP TABLE IF EXISTS hash_null_distinct CASCADE")
        .execute(&pool)
        .await?;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn forced_hash_join_via_planner_hints(pool: PgPool) -> Result<()> {
    // Test: Hash join works when forced by disabling other join strategies

    create_hash_test_table(&pool, "hash_forced_l").await?;
    create_hash_test_table(&pool, "hash_forced_r").await?;

    for id in 1..=3 {
        sqlx::query(&format!(
            "INSERT INTO hash_forced_l(e) VALUES (create_encrypted_json({}))",
            id
        ))
        .execute(&pool)
        .await?;

        sqlx::query(&format!(
            "INSERT INTO hash_forced_r(e) VALUES (create_encrypted_json({}))",
            id
        ))
        .execute(&pool)
        .await?;
    }

    // Disable nested loop and merge join to force hash join strategy
    sqlx::query("SET LOCAL enable_nestloop = off")
        .execute(&pool)
        .await?;
    sqlx::query("SET LOCAL enable_mergejoin = off")
        .execute(&pool)
        .await?;

    let count: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM hash_forced_l l JOIN hash_forced_r r ON l.e = r.e",
    )
    .fetch_one(&pool)
    .await
    .context("forced hash join failed")?;

    assert_eq!(count, 3, "Forced hash join should find 3 matching rows");

    // Cleanup
    sqlx::query("DROP TABLE IF EXISTS hash_forced_l, hash_forced_r CASCADE")
        .execute(&pool)
        .await?;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn not_in_with_encrypted_column(pool: PgPool) -> Result<()> {
    // Test: NOT IN returns correct exclusion count

    create_hash_test_table(&pool, "hash_not_in_main").await?;
    create_hash_test_table(&pool, "hash_not_in_sub").await?;

    // Main has ids 1, 2, 3
    for id in 1..=3 {
        sqlx::query(&format!(
            "INSERT INTO hash_not_in_main(e) VALUES (create_encrypted_json({}))",
            id
        ))
        .execute(&pool)
        .await?;
    }

    // Sub has ids 1, 3 (so id=2 should be excluded)
    sqlx::query("INSERT INTO hash_not_in_sub(e) VALUES (create_encrypted_json(1))")
        .execute(&pool)
        .await?;
    sqlx::query("INSERT INTO hash_not_in_sub(e) VALUES (create_encrypted_json(3))")
        .execute(&pool)
        .await?;

    let count: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM hash_not_in_main WHERE e NOT IN (SELECT e FROM hash_not_in_sub)",
    )
    .fetch_one(&pool)
    .await
    .context("NOT IN on encrypted column failed")?;

    assert_eq!(count, 1, "NOT IN should return 1 row (id=2 only)");

    // Cleanup
    sqlx::query("DROP TABLE IF EXISTS hash_not_in_main, hash_not_in_sub CASCADE")
        .execute(&pool)
        .await?;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn cross_type_equality_still_works(pool: PgPool) -> Result<()> {
    // Test: eql_v2_encrypted = jsonb and jsonb = eql_v2_encrypted work in WHERE clauses
    // Cross-type operators don't have HASHES, so planner uses merge join or nested loop

    create_hash_test_table(&pool, "hash_cross").await?;

    sqlx::query("INSERT INTO hash_cross(e) VALUES (create_encrypted_json(1))")
        .execute(&pool)
        .await?;
    sqlx::query("INSERT INTO hash_cross(e) VALUES (create_encrypted_json(2))")
        .execute(&pool)
        .await?;

    // encrypted = jsonb
    let count_ej: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM hash_cross WHERE e = (create_encrypted_json(1))::jsonb",
    )
    .fetch_one(&pool)
    .await
    .context("cross-type encrypted = jsonb failed")?;

    assert_eq!(count_ej, 1, "encrypted = jsonb should match 1 row");

    // jsonb = encrypted
    let count_je: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM hash_cross WHERE (create_encrypted_json(1))::jsonb = e",
    )
    .fetch_one(&pool)
    .await
    .context("cross-type jsonb = encrypted failed")?;

    assert_eq!(count_je, 1, "jsonb = encrypted should match 1 row");

    // Cleanup
    sqlx::query("DROP TABLE IF EXISTS hash_cross CASCADE")
        .execute(&pool)
        .await?;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn hash_join_non_matching_returns_zero(pool: PgPool) -> Result<()> {
    // Test: Hash join with no matching values returns zero rows

    create_hash_test_table(&pool, "hash_nomatch_l").await?;
    create_hash_test_table(&pool, "hash_nomatch_r").await?;

    // Left has id=1, Right has id=2 - no overlap
    sqlx::query("INSERT INTO hash_nomatch_l(e) VALUES (create_encrypted_json(1))")
        .execute(&pool)
        .await?;
    sqlx::query("INSERT INTO hash_nomatch_r(e) VALUES (create_encrypted_json(2))")
        .execute(&pool)
        .await?;

    let count: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM hash_nomatch_l l JOIN hash_nomatch_r r ON l.e = r.e",
    )
    .fetch_one(&pool)
    .await
    .context("non-matching hash join failed")?;

    assert_eq!(
        count, 0,
        "Join with no matching encrypted values should return 0 rows"
    );

    // Cleanup
    sqlx::query("DROP TABLE IF EXISTS hash_nomatch_l, hash_nomatch_r CASCADE")
        .execute(&pool)
        .await?;

    Ok(())
}

// ---------------------------------------------------------------------------
// Mixed-index regression tests (P1 hash/equality contract)
//
// These exercise real SQL query paths (hash join, GROUP BY, UNION) where one
// row has hm+b3 and the other has only b3. compare() falls back to Blake3 as
// the common term, so hash_encrypted must also use Blake3 for both rows.
// ---------------------------------------------------------------------------

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn mixed_index_hash_join(pool: PgPool) -> Result<()> {
    // Test: hash join finds match when left=hm+b3, right=b3-only (same logical value)

    create_hash_test_table(&pool, "mix_join_l").await?;
    create_hash_test_table(&pool, "mix_join_r").await?;

    // Left table: full hm+b3 for id 1
    sqlx::query("INSERT INTO mix_join_l(e) VALUES (create_encrypted_json(1, 'hm', 'b3'))")
        .execute(&pool)
        .await?;

    // Right table: b3-only for same id 1
    sqlx::query("INSERT INTO mix_join_r(e) VALUES (create_encrypted_json(1, 'b3'))")
        .execute(&pool)
        .await?;

    // Force hash join strategy
    sqlx::query("SET LOCAL enable_nestloop = off")
        .execute(&pool)
        .await?;
    sqlx::query("SET LOCAL enable_mergejoin = off")
        .execute(&pool)
        .await?;

    let count: i64 =
        sqlx::query_scalar("SELECT count(*) FROM mix_join_l l JOIN mix_join_r r ON l.e = r.e")
            .fetch_one(&pool)
            .await
            .context("mixed-index hash join failed")?;

    assert_eq!(
        count, 1,
        "Hash join should match hm+b3 row with b3-only row for same id"
    );

    // Cleanup
    sqlx::query("DROP TABLE IF EXISTS mix_join_l, mix_join_r CASCADE")
        .execute(&pool)
        .await?;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn mixed_index_group_by_dedup(pool: PgPool) -> Result<()> {
    // Test: GROUP BY deduplicates hm+b3 and b3-only rows for same logical value into one group

    create_hash_test_table(&pool, "mix_group").await?;

    // Two rows for the same id with different index term sets
    sqlx::query("INSERT INTO mix_group(e) VALUES (create_encrypted_json(1, 'hm', 'b3'))")
        .execute(&pool)
        .await?;
    sqlx::query("INSERT INTO mix_group(e) VALUES (create_encrypted_json(1, 'b3'))")
        .execute(&pool)
        .await?;

    // A different id to verify grouping still separates distinct values
    sqlx::query("INSERT INTO mix_group(e) VALUES (create_encrypted_json(2, 'hm', 'b3'))")
        .execute(&pool)
        .await?;

    let group_count: i64 =
        sqlx::query_scalar("SELECT count(*) FROM (SELECT e FROM mix_group GROUP BY e) sub")
            .fetch_one(&pool)
            .await
            .context("mixed-index GROUP BY failed")?;

    assert_eq!(
        group_count, 2,
        "GROUP BY should produce 2 groups: id=1 (hm+b3 and b3-only merged) and id=2"
    );

    // Cleanup
    sqlx::query("DROP TABLE IF EXISTS mix_group CASCADE")
        .execute(&pool)
        .await?;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn mixed_index_union_dedup(pool: PgPool) -> Result<()> {
    // Test: UNION deduplicates hm+b3 and b3-only rows for same logical value

    create_hash_test_table(&pool, "mix_union_a").await?;
    create_hash_test_table(&pool, "mix_union_b").await?;

    // Table A: hm+b3 for id 1
    sqlx::query("INSERT INTO mix_union_a(e) VALUES (create_encrypted_json(1, 'hm', 'b3'))")
        .execute(&pool)
        .await?;

    // Table B: b3-only for same id 1
    sqlx::query("INSERT INTO mix_union_b(e) VALUES (create_encrypted_json(1, 'b3'))")
        .execute(&pool)
        .await?;

    let count: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM (
            SELECT e FROM mix_union_a
            UNION
            SELECT e FROM mix_union_b
        ) sub",
    )
    .fetch_one(&pool)
    .await
    .context("mixed-index UNION failed")?;

    assert_eq!(
        count, 1,
        "UNION should deduplicate hm+b3 and b3-only into 1 unique row"
    );

    // Cleanup
    sqlx::query("DROP TABLE IF EXISTS mix_union_a, mix_union_b CASCADE")
        .execute(&pool)
        .await?;

    Ok(())
}
