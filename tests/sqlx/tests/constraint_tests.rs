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

// ========================================================================
// EQL-Specific Constraint Tests
// ========================================================================

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn add_encrypted_constraint_prevents_invalid_data(pool: PgPool) -> Result<()> {
    // Test: eql_v2.add_encrypted_constraint() adds validation to encrypted column

    // First, verify that insert without constraint works (even with invalid empty JSONB)
    sqlx::query("INSERT INTO encrypted (e) VALUES ('{}'::jsonb::eql_v2_encrypted)")
        .execute(&pool)
        .await?;

    let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM encrypted")
        .fetch_one(&pool)
        .await?;

    assert_eq!(
        count, 4,
        "Should have 4 records (3 from fixture + 1 invalid)"
    );

    // Delete the invalid data and reset
    sqlx::query("DELETE FROM encrypted WHERE e = '{}'::jsonb::eql_v2_encrypted")
        .execute(&pool)
        .await?;

    // Add the encrypted constraint
    sqlx::query("SELECT eql_v2.add_encrypted_constraint('encrypted', 'e')")
        .execute(&pool)
        .await?;

    // Now attempt to insert invalid data - should fail
    let result = sqlx::query("INSERT INTO encrypted (e) VALUES ('{}'::jsonb::eql_v2_encrypted)")
        .execute(&pool)
        .await;

    assert!(
        result.is_err(),
        "Constraint should prevent insert of invalid eql_v2_encrypted (empty JSONB)"
    );

    // Verify count unchanged after failed insert
    let final_count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM encrypted")
        .fetch_one(&pool)
        .await?;

    assert_eq!(
        final_count, 3,
        "Should still have 3 records after constraint prevented invalid insert"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn remove_encrypted_constraint_allows_invalid_data(pool: PgPool) -> Result<()> {
    // Test: eql_v2.remove_encrypted_constraint() removes validation from encrypted column

    // Add the encrypted constraint first
    sqlx::query("SELECT eql_v2.add_encrypted_constraint('encrypted', 'e')")
        .execute(&pool)
        .await?;

    // Verify constraint is working - invalid data should be rejected
    let result = sqlx::query("INSERT INTO encrypted (e) VALUES ('{}'::jsonb::eql_v2_encrypted)")
        .execute(&pool)
        .await;

    assert!(
        result.is_err(),
        "Constraint should prevent insert of invalid eql_v2_encrypted"
    );

    // Remove the constraint
    sqlx::query("SELECT eql_v2.remove_encrypted_constraint('encrypted', 'e')")
        .execute(&pool)
        .await?;

    // Now invalid data should be allowed
    sqlx::query("INSERT INTO encrypted (e) VALUES ('{}'::jsonb::eql_v2_encrypted)")
        .execute(&pool)
        .await?;

    let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM encrypted")
        .fetch_one(&pool)
        .await?;

    assert_eq!(
        count, 4,
        "Should have 4 records (3 valid + 1 invalid after constraint removed)"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn version_metadata_validation_on_insert(pool: PgPool) -> Result<()> {
    // Test: EQL version metadata (v field) is enforced on insert
    //
    // Note: The SQL test doesn't explicitly add a constraint, which suggests
    // version validation is built into the eql_v2_encrypted type itself or
    // is enforced automatically. However, for this test we need to ensure
    // the constraint exists to validate version fields.

    // Add encrypted constraint to enable version validation
    sqlx::query("SELECT eql_v2.add_encrypted_constraint('encrypted', 'e')")
        .execute(&pool)
        .await?;

    // Create a valid encrypted value with version removed
    // We'll get a valid encrypted JSON and remove the 'v' field
    let encrypted_without_version: String =
        sqlx::query_scalar("SELECT (create_encrypted_json(1)::jsonb - 'v')::text")
            .fetch_one(&pool)
            .await?;

    // Attempt to insert without version field - should fail
    let result = sqlx::query(&format!(
        "INSERT INTO encrypted (e) VALUES ('{}'::jsonb::eql_v2_encrypted)",
        encrypted_without_version
    ))
    .execute(&pool)
    .await;

    assert!(
        result.is_err(),
        "Insert should fail when version field is missing"
    );

    // Create encrypted value with invalid version (v=1 instead of v=2)
    let encrypted_invalid_version: String =
        sqlx::query_scalar("SELECT (create_encrypted_json(1)::jsonb || '{\"v\": 1}')::text")
            .fetch_one(&pool)
            .await?;

    // Attempt to insert with invalid version - should fail
    let result = sqlx::query(&format!(
        "INSERT INTO encrypted (e) VALUES ('{}'::jsonb::eql_v2_encrypted)",
        encrypted_invalid_version
    ))
    .execute(&pool)
    .await;

    assert!(
        result.is_err(),
        "Insert should fail when version field is invalid (v=1)"
    );

    // Insert with valid version (v=2) should succeed
    sqlx::query("INSERT INTO encrypted (e) VALUES (create_encrypted_json(1))")
        .execute(&pool)
        .await?;

    let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM encrypted")
        .fetch_one(&pool)
        .await?;

    assert_eq!(
        count, 4,
        "Should have 4 records after successful insert with valid version"
    );

    Ok(())
}
