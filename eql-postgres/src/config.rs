//! PostgreSQL implementation of Config trait

use eql_core::{Component, Config};

// Base component: Configuration types
pub struct ConfigTypes;

impl Component for ConfigTypes {
    type Dependencies = ();

    fn sql_file() -> &'static str {
        concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/src/sql/config/types.sql"
        )
    }
}

// Configuration tables
pub struct ConfigTables;

impl Component for ConfigTables {
    type Dependencies = ConfigTypes;

    fn sql_file() -> &'static str {
        concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/src/sql/config/tables.sql"
        )
    }
}

// Configuration indexes
pub struct ConfigIndexes;

impl Component for ConfigIndexes {
    type Dependencies = ConfigTables;

    fn sql_file() -> &'static str {
        concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/src/sql/config/indexes.sql"
        )
    }
}

// Private helper functions
pub struct ConfigPrivateFunctions;

impl Component for ConfigPrivateFunctions {
    type Dependencies = ConfigTypes;

    fn sql_file() -> &'static str {
        concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/src/sql/config/functions_private.sql"
        )
    }
}

// Encrypted data validation stub
pub struct CheckEncrypted;

impl Component for CheckEncrypted {
    type Dependencies = ();

    fn sql_file() -> &'static str {
        concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/src/sql/encrypted/check_encrypted.sql"
        )
    }
}

// Add encrypted constraint helper
pub struct AddEncryptedConstraint;

impl Component for AddEncryptedConstraint {
    type Dependencies = CheckEncrypted;

    fn sql_file() -> &'static str {
        concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/src/sql/encrypted/add_encrypted_constraint.sql"
        )
    }
}

// Migration and activation functions
pub struct MigrateActivate;

impl Component for MigrateActivate {
    type Dependencies = ConfigIndexes;  // Depends on indexes (which depend on tables)

    fn sql_file() -> &'static str {
        concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/src/sql/config/migrate_activate.sql"
        )
    }
}

// Main add_column function
pub struct AddColumn;

impl Component for AddColumn {
    type Dependencies = (
        ConfigPrivateFunctions,
        MigrateActivate,
        AddEncryptedConstraint,
        ConfigTypes,  // Last to avoid conflicts
    );

    fn sql_file() -> &'static str {
        concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/src/sql/config/add_column.sql"
        )
    }
}

// Placeholder components for POC
pub struct RemoveColumn;
impl Component for RemoveColumn {
    type Dependencies = ();
    fn sql_file() -> &'static str { "not_implemented.sql" }
}

pub struct AddSearchConfig;
impl Component for AddSearchConfig {
    type Dependencies = ();
    fn sql_file() -> &'static str { "not_implemented.sql" }
}

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
