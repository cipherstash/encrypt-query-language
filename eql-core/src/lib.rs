//! EQL Core - Trait definitions for multi-database SQL extension API

pub mod error;

pub use error::{ComponentError, DatabaseError, EqlError};

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_error_types_display() {
        let err = ComponentError::SqlFileNotFound {
            path: "test.sql".to_string(),
        };
        assert!(err.to_string().contains("SQL file not found"));
        assert!(err.to_string().contains("test.sql"));
    }

    #[test]
    fn test_database_error_context() {
        let err = DatabaseError::MissingJsonbKey {
            key: "tables".to_string(),
            actual: serde_json::json!({"wrong": "value"}),
        };
        let err_string = err.to_string();
        assert!(err_string.contains("tables"));
        assert!(err_string.contains("wrong"));
    }
}
