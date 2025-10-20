//! Test harness providing transaction isolation for SQL tests

use eql_core::error::DatabaseError;
use tokio_postgres::{Client, NoTls, Row};

pub struct TestDb {
    client: Client,
    in_transaction: bool,
}

impl TestDb {
    /// Create new test database with transaction isolation
    pub async fn new() -> Result<Self, DatabaseError> {
        let (client, connection) = tokio_postgres::connect(
            &Self::connection_string(),
            NoTls,
        )
        .await
        .map_err(DatabaseError::Connection)?;

        // Spawn connection handler
        tokio::spawn(async move {
            if let Err(e) = connection.await {
                eprintln!("Connection error: {}", e);
            }
        });

        // Begin transaction for isolation
        client.execute("BEGIN", &[])
            .await
            .map_err(|e| DatabaseError::Query {
                query: "BEGIN".to_string(),
                source: e,
            })?;

        Ok(Self {
            client,
            in_transaction: true,
        })
    }

    fn connection_string() -> String {
        std::env::var("TEST_DATABASE_URL")
            .unwrap_or_else(|_| "host=localhost port=7432 user=cipherstash password=password dbname=postgres".to_string())
    }

    /// Execute SQL (for setup/implementation loading)
    pub async fn execute(&self, sql: &str) -> Result<u64, DatabaseError> {
        self.client.execute(sql, &[])
            .await
            .map_err(|e| DatabaseError::Query {
                query: sql.to_string(),
                source: e,
            })
    }

    /// Query with single result
    pub async fn query_one(&self, sql: &str) -> Result<Row, DatabaseError> {
        self.client.query_one(sql, &[])
            .await
            .map_err(|e| DatabaseError::Query {
                query: sql.to_string(),
                source: e,
            })
    }

    /// Assert JSONB result has key
    pub fn assert_jsonb_has_key(&self, result: &Row, column_index: usize, key: &str) -> Result<(), DatabaseError> {
        let json: serde_json::Value = result.get(column_index);
        if json.get(key).is_none() {
            return Err(DatabaseError::MissingJsonbKey {
                key: key.to_string(),
                actual: json,
            });
        }
        Ok(())
    }
}

impl Drop for TestDb {
    fn drop(&mut self) {
        if self.in_transaction {
            // Auto-rollback on drop
            // Note: Can't use async in Drop, but connection will rollback anyway
            // when client drops
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_testdb_transaction_isolation() {
        let db = TestDb::new().await.expect("Failed to create TestDb");

        // Create a temporary table
        db.execute("CREATE TEMPORARY TABLE test_table (id int, value text)")
            .await
            .expect("Failed to create table");

        // Insert data
        db.execute("INSERT INTO test_table VALUES (1, 'test')")
            .await
            .expect("Failed to insert");

        // Query data
        let row = db.query_one("SELECT value FROM test_table WHERE id = 1")
            .await
            .expect("Failed to query");

        let value: String = row.get(0);
        assert_eq!(value, "test");

        // Transaction will rollback on drop - table won't exist in next test
    }

    #[tokio::test]
    async fn test_database_error_includes_query() {
        let db = TestDb::new().await.expect("Failed to create TestDb");

        let result = db.execute("INVALID SQL SYNTAX").await;
        assert!(result.is_err());

        let err = result.unwrap_err();
        let err_string = err.to_string();
        assert!(err_string.contains("Query failed"));
        assert!(err_string.contains("INVALID SQL SYNTAX"));
    }
}
