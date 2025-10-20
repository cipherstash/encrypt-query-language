//! EQL Core - Trait definitions for multi-database SQL extension API

pub mod component;
pub mod config;
pub mod error;

pub use component::{Component, Dependencies};
pub use config::Config;
pub use error::{ComponentError, DatabaseError, EqlError};

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_component_trait_compiles() {
        // This test verifies the trait definition compiles
        // Actual implementations will be in eql-postgres
        struct TestComponent;

        impl Component for TestComponent {
            type Dependencies = ();

            fn sql_file() -> &'static str {
                "test.sql"
            }
        }

        assert_eq!(TestComponent::sql_file(), "test.sql");
    }

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
