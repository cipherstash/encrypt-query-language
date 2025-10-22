use sqlx::PgPool;
use eql_sqlx_tests::setup_test_db;

#[tokio::test]
async fn test_add_column_creates_configuration() {
    // Setup: Load EQL from built release file
    let pool = setup_test_db()
        .await
        .expect("Failed to setup test database");

    // Create a test table with encrypted column
    sqlx::query(
        "CREATE TABLE users (
            id INTEGER,
            email eql_v2_encrypted
        )"
    )
    .execute(&pool)
    .await
    .expect("Failed to create table");

    // Execute: Call add_column function
    let result = sqlx::query_scalar::<_, serde_json::Value>(
        "SELECT eql_v2.add_column('users', 'email', 'text')"
    )
    .fetch_one(&pool)
    .await
    .expect("Failed to call add_column");

    // Assert: Configuration has expected structure
    assert!(result.get("tables").is_some(), "Config should have 'tables' key");
    assert!(result.get("v").is_some(), "Config should have 'v' (version) key");

    // Assert: Configuration was persisted
    let stored_config = sqlx::query_scalar::<_, serde_json::Value>(
        "SELECT data FROM public.eql_v2_configuration WHERE state = 'active'"
    )
    .fetch_one(&pool)
    .await
    .expect("Should have active configuration");

    assert!(stored_config.get("tables").is_some(), "Stored config should have 'tables'");

    // Assert: Encrypted constraint was added
    let constraint_exists = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS (
            SELECT 1 FROM pg_constraint
            WHERE conname = 'eql_v2_encrypted_check_email'
        )"
    )
    .fetch_one(&pool)
    .await
    .expect("Failed to check constraint");

    assert!(constraint_exists, "Encrypted constraint should exist");
}

#[tokio::test]
async fn test_add_column_rejects_duplicate() {
    let pool = setup_test_db()
        .await
        .expect("Failed to setup test database");

    // Setup table
    sqlx::query("CREATE TABLE users (id INTEGER, email eql_v2_encrypted)")
        .execute(&pool)
        .await
        .expect("Failed to create table");

    // First call succeeds
    sqlx::query_scalar::<_, serde_json::Value>(
        "SELECT eql_v2.add_column('users', 'email', 'text')"
    )
    .fetch_one(&pool)
    .await
    .expect("First add_column should succeed");

    // Second call should fail
    let result = sqlx::query_scalar::<_, serde_json::Value>(
        "SELECT eql_v2.add_column('users', 'email', 'text')"
    )
    .fetch_one(&pool)
    .await;

    assert!(result.is_err(), "Duplicate add_column should fail");
}

#[tokio::test]
async fn test_multiple_encrypted_columns() {
    let pool = setup_test_db()
        .await
        .expect("Failed to setup test database");

    // Create table with multiple encrypted columns
    sqlx::query(
        "CREATE TABLE users (
            id INTEGER,
            email eql_v2_encrypted,
            phone eql_v2_encrypted,
            ssn eql_v2_encrypted
        )"
    )
    .execute(&pool)
    .await
    .expect("Failed to create table");

    // Configure all three columns
    for (column, cast_type) in [("email", "text"), ("phone", "text"), ("ssn", "text")] {
        sqlx::query_scalar::<_, serde_json::Value>(
            &format!("SELECT eql_v2.add_column('users', '{}', '{}')", column, cast_type)
        )
        .fetch_one(&pool)
        .await
        .expect(&format!("Failed to add_column for {}", column));
    }

    // Verify all constraints exist
    for column in ["email", "phone", "ssn"] {
        let constraint_name = format!("eql_v2_encrypted_check_{}", column);
        let exists = sqlx::query_scalar::<_, bool>(
            &format!(
                "SELECT EXISTS (
                    SELECT 1 FROM pg_constraint
                    WHERE conname = '{}'
                )",
                constraint_name
            )
        )
        .fetch_one(&pool)
        .await
        .expect("Failed to check constraint");

        assert!(exists, "Constraint for {} should exist", column);
    }

    // Verify configuration has all three columns
    let config = sqlx::query_scalar::<_, serde_json::Value>(
        "SELECT data FROM public.eql_v2_configuration WHERE state = 'active'"
    )
    .fetch_one(&pool)
    .await
    .expect("Should have active configuration");

    let tables = config.get("tables")
        .and_then(|t| t.get("users"))
        .and_then(|u| u.get("columns"))
        .expect("Config should have users.columns");

    assert!(tables.get("email").is_some(), "Config should have email column");
    assert!(tables.get("phone").is_some(), "Config should have phone column");
    assert!(tables.get("ssn").is_some(), "Config should have ssn column");
}
