use eql_postgres::config::AddColumn;
use eql_core::Component;
use eql_test::TestDb;

#[tokio::test]
async fn test_add_column_creates_config() {
    let db = TestDb::new().await.expect("Failed to create TestDb");

    // Create schema
    db.execute("CREATE SCHEMA IF NOT EXISTS eql_v2;")
        .await.expect("Failed to create schema");

    // Create minimal encrypted type stub for POC
    db.execute(
        "CREATE TYPE eql_v2_encrypted AS (data jsonb);"
    ).await.expect("Failed to create encrypted type");

    // Load all dependencies in order
    let deps = AddColumn::collect_dependencies();
    for sql_file in deps {
        let sql = std::fs::read_to_string(sql_file)
            .unwrap_or_else(|e| panic!("Failed to read {}: {}", sql_file, e));

        db.batch_execute(&sql)
            .await
            .unwrap_or_else(|e| panic!("Failed to load {}: {}", sql_file, e));
    }

    // Setup: Create test table with encrypted column
    db.execute(
        "CREATE TABLE users (
            id int,
            email eql_v2_encrypted
        )"
    ).await.expect("Failed to create table");

    // Execute: Call add_column
    let result = db.query_one(
        "SELECT eql_v2.add_column('users', 'email', 'text')"
    )
    .await
    .expect("Failed to call add_column");

    // Assert: Result has expected structure
    db.assert_jsonb_has_key(&result, 0, "tables")
        .expect("Expected 'tables' key in config");

    db.assert_jsonb_has_key(&result, 0, "v")
        .expect("Expected 'v' (version) key in config");

    // Assert: Configuration was stored
    let config_row = db.query_one(
        "SELECT data FROM public.eql_v2_configuration WHERE state = 'active'"
    )
    .await
    .expect("Should have active config");

    db.assert_jsonb_has_key(&config_row, 0, "tables")
        .expect("Stored config should have 'tables' key");

    // Assert: Constraint was added
    let constraint_exists = db.query_one(
        "SELECT EXISTS (
            SELECT 1 FROM pg_constraint
            WHERE conname = 'eql_v2_encrypted_check_email'
        )"
    ).await.expect("Failed to check constraint");

    let exists: bool = constraint_exists.get(0);
    assert!(exists, "Encrypted constraint should exist");
}

#[tokio::test]
async fn test_add_column_rejects_duplicate() {
    let db = TestDb::new().await.expect("Failed to create TestDb");

    // Load schema and dependencies (same as above)
    db.execute("CREATE SCHEMA IF NOT EXISTS eql_v2;")
        .await.expect("Failed to create schema");

    db.execute("CREATE TYPE eql_v2_encrypted AS (data jsonb);")
        .await.expect("Failed to create encrypted type");

    let deps = AddColumn::collect_dependencies();
    for sql_file in deps {
        let sql = std::fs::read_to_string(sql_file).unwrap();
        db.batch_execute(&sql).await.unwrap();
    }

    db.execute("CREATE TABLE users (id int, email eql_v2_encrypted)")
        .await.expect("Failed to create table");

    // First call succeeds
    db.query_one("SELECT eql_v2.add_column('users', 'email', 'text')")
        .await
        .expect("First add_column should succeed");

    // Second call should fail
    let result = db.query_one("SELECT eql_v2.add_column('users', 'email', 'text')").await;
    assert!(result.is_err(), "Duplicate add_column should fail");

    // Test passes - duplicate prevention working (error raised by SQL function)
}
