//! Constraint tests
//!
//! Tests UNIQUE, NOT NULL, CHECK constraints on encrypted columns

use anyhow::Result;
use sqlx::PgPool;

#[sqlx::test(fixtures(path = "../fixtures", scripts("constraint_tables")))]
async fn unique_constraint_on_encrypted_column(pool: PgPool) -> Result<()> {
    // Test: UNIQUE constraint enforced on encrypted column (3 assertions)

    // Insert first record (provide check_field to satisfy its constraint)
    sqlx::query(
        "INSERT INTO constrained (unique_field, not_null_field, check_field)
         VALUES (create_encrypted_json(1, 'hm'), create_encrypted_json(1, 'hm'), create_encrypted_json(1, 'hm'))"
    )
    .execute(&pool)
    .await?;

    // Verify record was inserted
    let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM constrained")
        .fetch_one(&pool)
        .await?;

    assert_eq!(count, 1, "Should have 1 record after insert");

    // Attempt duplicate insert
    let result = sqlx::query(
        "INSERT INTO constrained (unique_field, not_null_field, check_field)
         VALUES (create_encrypted_json(1, 'hm'), create_encrypted_json(2, 'hm'), create_encrypted_json(2, 'hm'))"
    )
    .execute(&pool)
    .await;

    assert!(
        result.is_err(),
        "UNIQUE constraint should prevent duplicate"
    );

    // Verify count unchanged after failed insert
    let count_after: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM constrained")
        .fetch_one(&pool)
        .await?;

    assert_eq!(count_after, 1, "Count should remain 1 after failed insert");

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("constraint_tables")))]
async fn not_null_constraint_on_encrypted_column(pool: PgPool) -> Result<()> {
    // Test: NOT NULL constraint enforced (2 assertions)

    let result = sqlx::query(
        "INSERT INTO constrained (unique_field)
         VALUES (create_encrypted_json(2, 'hm'))",
    )
    .execute(&pool)
    .await;

    assert!(result.is_err(), "NOT NULL constraint should prevent NULL");

    // Verify no records were inserted
    let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM constrained")
        .fetch_one(&pool)
        .await?;

    assert_eq!(count, 0, "Should have 0 records after failed insert");

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("constraint_tables")))]
async fn check_constraint_on_encrypted_column(pool: PgPool) -> Result<()> {
    // Test: CHECK constraint enforced (2 assertions)

    let result = sqlx::query(
        "INSERT INTO constrained (unique_field, not_null_field, check_field)
         VALUES (
             create_encrypted_json(3, 'hm'),
             create_encrypted_json(3, 'hm'),
             NULL
         )",
    )
    .execute(&pool)
    .await;

    assert!(result.is_err(), "CHECK constraint should prevent NULL");

    // Verify no records were inserted
    let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM constrained")
        .fetch_one(&pool)
        .await?;

    assert_eq!(count, 0, "Should have 0 records after failed insert");

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("constraint_tables")))]
async fn foreign_key_constraint_with_encrypted(pool: PgPool) -> Result<()> {
    // Test: Foreign key constraints can be defined on encrypted columns
    // but don't provide referential integrity since each encryption is unique

    // Create parent table
    sqlx::query(
        "CREATE TABLE parent (
            id eql_v2_encrypted PRIMARY KEY
        )",
    )
    .execute(&pool)
    .await?;

    // Verify parent table was created
    let parent_exists: bool = sqlx::query_scalar(
        "SELECT EXISTS (
            SELECT FROM information_schema.tables
            WHERE table_name = 'parent'
        )",
    )
    .fetch_one(&pool)
    .await?;

    assert!(parent_exists, "Parent table should exist");

    // Create child table with FK
    sqlx::query(
        "CREATE TABLE child (
            id bigint PRIMARY KEY,
            parent_id eql_v2_encrypted REFERENCES parent(id)
        )",
    )
    .execute(&pool)
    .await?;

    // Verify child table and FK were created
    let child_exists: bool = sqlx::query_scalar(
        "SELECT EXISTS (
            SELECT FROM information_schema.tables
            WHERE table_name = 'child'
        )",
    )
    .fetch_one(&pool)
    .await?;

    assert!(child_exists, "Child table should exist");

    // Verify FK constraint exists
    let fk_exists: bool = sqlx::query_scalar(
        "SELECT EXISTS (
            SELECT FROM information_schema.table_constraints
            WHERE table_name = 'child'
            AND constraint_type = 'FOREIGN KEY'
        )",
    )
    .fetch_one(&pool)
    .await?;

    assert!(fk_exists, "Foreign key constraint should exist");

    // TEST FK ENFORCEMENT BEHAVIOR:
    // With deterministic test data, FK constraints DO enforce referential integrity
    // because we can use the exact same encrypted bytes.
    //
    // PRODUCTION LIMITATION: In real-world usage with non-deterministic encryption,
    // FK constraints don't provide meaningful referential integrity because:
    // 1. Each encryption of the same plaintext produces different ciphertext
    // 2. The FK check compares encrypted bytes, not plaintext values
    // 3. Two encryptions of "1" will have different bytes and won't match
    //
    // This test uses deterministic test helpers, so FKs DO work here.

    // Insert a parent record with encrypted value for plaintext "1"
    sqlx::query("INSERT INTO parent (id) VALUES (create_encrypted_json(1, 'hm'))")
        .execute(&pool)
        .await?;

    // Verify parent record exists
    let parent_count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM parent")
        .fetch_one(&pool)
        .await?;

    assert_eq!(parent_count, 1, "Should have 1 parent record");

    // Successfully insert child record with FK to same deterministic value
    // This SUCCEEDS because create_encrypted_json(1, 'hm') returns identical bytes each time
    sqlx::query("INSERT INTO child (id, parent_id) VALUES (1, create_encrypted_json(1, 'hm'))")
        .execute(&pool)
        .await?;

    // Verify child record was inserted
    let child_count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM child")
        .fetch_one(&pool)
        .await?;

    assert_eq!(
        child_count, 1,
        "Child insert should succeed with matching deterministic encrypted value"
    );

    // Attempt to insert child with different encrypted value (should fail FK check)
    let different_insert_result =
        sqlx::query("INSERT INTO child (id, parent_id) VALUES (2, create_encrypted_json(2, 'hm'))")
            .execute(&pool)
            .await;

    assert!(
        different_insert_result.is_err(),
        "FK constraint should reject non-existent parent reference"
    );

    // Verify child count unchanged
    let final_count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM child")
        .fetch_one(&pool)
        .await?;

    assert_eq!(
        final_count, 1,
        "FK violation should prevent second child insert"
    );

    Ok(())
}
