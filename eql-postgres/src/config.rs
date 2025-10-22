//! PostgreSQL implementation of Config trait

use eql_core::{sql_component, Config};

// ============================================
// SQL Component Declarations
// ============================================

// Configuration components
sql_component!(config::ConfigTypes => "types.sql");
sql_component!(config::ConfigTables => "tables.sql", deps: [ConfigTypes]);
sql_component!(config::ConfigIndexes => "indexes.sql", deps: [ConfigTables]);
sql_component!(config::ConfigPrivateFunctions => "functions_private.sql", deps: [ConfigTypes]);
sql_component!(config::MigrateActivate, deps: [ConfigIndexes]);

// Encrypted components
sql_component!(encrypted::CheckEncrypted);
sql_component!(encrypted::AddEncryptedConstraint, deps: [CheckEncrypted]);

// Main configuration function
sql_component!(config::AddColumn, deps: [
    ConfigPrivateFunctions,
    MigrateActivate,
    AddEncryptedConstraint,
    ConfigTypes,
]);

// Placeholder components for POC
sql_component!(RemoveColumn => "not_implemented.sql");
sql_component!(AddSearchConfig => "not_implemented.sql");

// PostgreSQL implementation of Config trait
pub struct PostgresEQL;

impl Config for PostgresEQL {
    type AddColumnComponent = AddColumn;
    type RemoveColumnComponent = RemoveColumn;
    type AddSearchConfigComponent = AddSearchConfig;

    fn add_column() -> &'static Self::AddColumnComponent {
        &AddColumn
    }

    fn remove_column() -> &'static Self::RemoveColumnComponent {
        &RemoveColumn
    }

    fn add_search_config() -> &'static Self::AddSearchConfigComponent {
        &AddSearchConfig
    }
}
