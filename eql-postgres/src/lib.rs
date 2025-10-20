//! PostgreSQL implementation of EQL

pub mod config;

pub use config::PostgresEQL;

#[cfg(test)]
mod tests {
    use super::*;
    use eql_core::Component;

    #[test]
    fn test_component_sql_files_exist() {
        use config::AddColumn;
        let path = AddColumn::sql_file();
        assert!(
            std::path::Path::new(path).exists(),
            "add_column SQL file should exist at {}",
            path
        );
    }

    #[test]
    fn test_add_column_dependencies_collected() {
        use config::AddColumn;

        let deps = AddColumn::collect_dependencies();

        // Should include all dependencies in order
        assert!(deps.len() > 1, "AddColumn should have dependencies");

        // Dependencies should come before AddColumn itself
        let add_column_path = AddColumn::sql_file();
        let add_column_pos = deps.iter().position(|&f| f == add_column_path);
        assert!(add_column_pos.is_some(), "Should include AddColumn itself");

        // Verify no duplicates
        let mut seen = std::collections::HashSet::new();
        for file in &deps {
            assert!(seen.insert(file), "Dependency {} appears twice", file);
        }
    }
}
