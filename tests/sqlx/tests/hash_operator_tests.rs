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

    Ok(())
}

// hash_function_uses_blake3_first removed: post-discipline, hash_encrypted
// is hmac-only at the root. There is no Blake3 path to prefer.

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
async fn hash_function_returns_null_when_hmac_absent(pool: PgPool) -> Result<()> {
    // U-002 contract: equality on `eql_v2_encrypted` is hm-only at the root,
    // and `hash_encrypted` mirrors that. On a column without `hm` (e.g. an
    // ore-only payload), the inlined body reduces to
    // `hashtext(hmac_256(val)::text)` — `hmac_256(val)` returns NULL, and
    // `hashtext(NULL)` propagates NULL. Misconfiguration surfaces as the
    // hash opclass machinery erroring on the NULL return, not as a silent
    // wrong-grouping. This test pins the NULL return at the function level.

    let h: Option<i32> =
        sqlx::query_scalar("SELECT eql_v2.hash_encrypted(create_encrypted_json(1, 'ob'))")
            .fetch_one(&pool)
            .await
            .context("hash_encrypted on ore-only value")?;

    assert!(
        h.is_none(),
        "hash_encrypted on a column without `hm` must return NULL (caller responsibility to configure a `unique` index)"
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

// hash_consistency_full_index_matches_blake3_only,
// hmac_and_blake3_produce_different_hashes,
// ste_vec_wrapped_hashes_same_as_unwrapped — removed. They asserted
// the Blake3-first hash priority that was the previous implementation.
// Post-discipline, hash_encrypted is hmac-only at the root; there is
// no Blake3 root path to test. ste_vec single-element unwrapping
// still works but the inner element must carry hm to be hashable.

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn multi_element_ste_vec_returns_null(pool: PgPool) -> Result<()> {
    // A multi-element STE vec (`{i, v, sv: [...]}`) has no root `hm` — `hm`
    // lives on sv elements, not at the root. `hash_encrypted` is documented
    // as operating on the root payload only; for grouping by an extracted
    // field, callers use `GROUP BY eql_v2.hmac_256(col, '<selector>')`
    // directly (or the ste_vec_entry recipe). At the root, this returns NULL
    // — surfacing as a clear hash-machinery error if someone tries to
    // `GROUP BY` the column itself without configuring `hm`.

    let h: Option<i32> =
        sqlx::query_scalar("SELECT eql_v2.hash_encrypted((get_array_ste_vec())::eql_v2_encrypted)")
            .fetch_one(&pool)
            .await
            .context("hash_encrypted on multi-element ste_vec")?;

    assert!(
        h.is_none(),
        "hash_encrypted on a multi-element ste_vec (no root `hm`) must return NULL"
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

    // Disable nested loop and merge join to force hash join strategy.
    // SET LOCAL is scoped to the current transaction, so we need an explicit one.
    let mut tx = pool.begin().await?;
    sqlx::query("SET LOCAL enable_nestloop = off")
        .execute(&mut *tx)
        .await?;
    sqlx::query("SET LOCAL enable_mergejoin = off")
        .execute(&mut *tx)
        .await?;

    let count: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM hash_forced_l l JOIN hash_forced_r r ON l.e = r.e",
    )
    .fetch_one(&mut *tx)
    .await
    .context("forced hash join failed")?;

    tx.commit().await?;

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

// Mixed-index regression tests (`mixed_index_hash_join`,
// `mixed_index_group_by_dedup`, `mixed_index_union_dedup`) were removed
// as part of the v2 payload scheme discipline (see RFC). They asserted
// the "P1 hash/equality contract" — that an `hm+b3` row equals a
// `b3-only` row via `=` / hash join / GROUP BY / UNION because compare
// fell back to Blake3 across rows. That contract has no production
// analogue: protect.js does not emit a root-level `b3` term, so the
// "hm+b3 vs b3-only" mixed shape is fixture-only.

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn hash_encrypted_is_inlinable(pool: PgPool) -> Result<()> {
    // The hash operator class FUNCTION 1 is called once per row by
    // HashAggregate / hash joins / DISTINCT. For the per-row cost to drop
    // out of the plpgsql interpreter, `eql_v2.hash_encrypted(eql_v2_encrypted)`
    // must be (a) LANGUAGE sql and (b) without a pinned search_path.
    // Either condition alone is enough to disable PG's SQL function inlining
    // (see PostgreSQL's inline_function in clauses.c), so the splinter
    // allowlist and tasks/pin_search_path.sql carve-out are load-bearing.
    let (lang, proconfig): (String, Option<Vec<String>>) = sqlx::query_as(
        r#"
        SELECT l.lanname::text, p.proconfig
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        JOIN pg_language l ON l.oid = p.prolang
        WHERE n.nspname = 'eql_v2'
          AND p.proname = 'hash_encrypted'
          AND p.pronargs = 1
        "#,
    )
    .fetch_one(&pool)
    .await
    .context("could not look up hash_encrypted in pg_proc")?;

    assert_eq!(
        lang, "sql",
        "hash_encrypted must be LANGUAGE sql for the planner to inline it (got {})",
        lang
    );

    let has_search_path = proconfig
        .as_ref()
        .map(|cfg| cfg.iter().any(|c| c.starts_with("search_path=")))
        .unwrap_or(false);
    assert!(
        !has_search_path,
        "hash_encrypted must NOT have a pinned search_path — pin_search_path.sql allowlists it; \
         pinning disables SQL inlining (got proconfig={:?})",
        proconfig
    );

    Ok(())
}
