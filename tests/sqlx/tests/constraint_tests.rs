//! Constraint tests
//!
//! Converted from src/encrypted/constraints_test.sql
//! Tests UNIQUE, NOT NULL, CHECK constraints on encrypted columns

use anyhow::Result;
use sqlx::PgPool;

#[sqlx::test(fixtures(path = "../fixtures", scripts("constraint_tables")))]
async fn unique_constraint_on_encrypted_column(pool: PgPool) -> Result<()> {
    // Test: UNIQUE constraint enforced on encrypted column (3 assertions)
    // Original SQL lines 13-35 in src/encrypted/constraints_test.sql

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
    // Original SQL lines 37-52 in src/encrypted/constraints_test.sql

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
    // Original SQL lines 54-72 in src/encrypted/constraints_test.sql

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
    // Original SQL lines 74-139 in src/encrypted/constraints_test.sql

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

    Ok(())
}
