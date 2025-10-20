//! Error types for EQL operations

use thiserror::Error;

/// Top-level error type for all EQL operations
#[derive(Error, Debug)]
pub enum EqlError {
    #[error("Component error: {0}")]
    Component(#[from] ComponentError),

    #[error("Database error: {0}")]
    Database(#[from] DatabaseError),
}

/// Errors related to SQL components and dependencies
#[derive(Error, Debug)]
pub enum ComponentError {
    #[error("SQL file not found: {path}")]
    SqlFileNotFound { path: String },

    #[error("Dependency cycle detected: {cycle}")]
    DependencyCycle { cycle: String },

    #[error("IO error reading SQL file {path}: {source}")]
    IoError {
        path: String,
        #[source]
        source: std::io::Error,
    },

    #[error("Missing dependency: {component} requires {missing}")]
    MissingDependency {
        component: String,
        missing: String,
    },
}

/// Errors related to database operations
#[derive(Error, Debug)]
pub enum DatabaseError {
    #[error("Connection failed: {0}")]
    Connection(#[source] tokio_postgres::Error),

    #[error("Transaction failed: {0}")]
    Transaction(String),

    #[error("Query failed: {query}: {source}")]
    Query {
        query: String,
        #[source]
        source: tokio_postgres::Error,
    },

    #[error("Expected JSONB value to have key '{key}', got: {actual}")]
    MissingJsonbKey {
        key: String,
        actual: serde_json::Value,
    },
}
