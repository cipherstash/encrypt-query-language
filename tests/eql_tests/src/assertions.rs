//! Fluent assertion builder for database queries
//!
//! Provides chainable assertions for common test patterns:
//! - Query returns rows
//! - Query returns specific count
//! - Query returns specific value
//! - Query throws exception

use sqlx::{PgPool, Row};

/// Fluent assertion builder for SQL queries
pub struct QueryAssertion<'a> {
    pool: &'a PgPool,
    sql: String,
}

impl<'a> QueryAssertion<'a> {
    /// Create new query assertion
    ///
    /// # Example
    /// ```ignore
    /// QueryAssertion::new(&pool, "SELECT * FROM encrypted")
    ///     .returns_rows()
    ///     .await;
    /// ```
    pub fn new(pool: &'a PgPool, sql: impl Into<String>) -> Self {
        Self {
            pool,
            sql: sql.into(),
        }
    }

    /// Assert that query returns at least one row
    ///
    /// # Panics
    /// Panics if query returns no rows or fails to execute
    pub async fn returns_rows(self) -> Self {
        let rows = sqlx::query(&self.sql)
            .fetch_all(self.pool)
            .await
            .expect(&format!("Query failed: {}", self.sql));

        assert!(
            !rows.is_empty(),
            "Expected query to return rows but got none: {}",
            self.sql
        );

        self
    }

    /// Assert that query returns exactly N rows
    ///
    /// # Panics
    /// Panics if query returns different number of rows
    pub async fn count(self, expected: usize) -> Self {
        let rows = sqlx::query(&self.sql)
            .fetch_all(self.pool)
            .await
            .expect(&format!("Query failed: {}", self.sql));

        assert_eq!(
            rows.len(),
            expected,
            "Expected {} rows but got {}: {}",
            expected,
            rows.len(),
            self.sql
        );

        self
    }

    /// Assert that query returns a specific value in first row, first column
    ///
    /// # Panics
    /// Panics if value doesn't match or query fails
    pub async fn returns_value(self, expected: &str) -> Self {
        let row = sqlx::query(&self.sql)
            .fetch_one(self.pool)
            .await
            .expect(&format!("Query failed: {}", self.sql));

        let value: String = row.try_get(0)
            .expect("Failed to get column 0");

        assert_eq!(
            value,
            expected,
            "Expected '{}' but got '{}': {}",
            expected,
            value,
            self.sql
        );

        self
    }

    /// Assert that query throws an exception
    ///
    /// # Panics
    /// Panics if query succeeds instead of failing
    pub async fn throws_exception(self) {
        let result = sqlx::query(&self.sql)
            .fetch_all(self.pool)
            .await;

        assert!(
            result.is_err(),
            "Expected query to throw exception but it succeeded: {}",
            self.sql
        );
    }
}
