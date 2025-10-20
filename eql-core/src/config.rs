//! Configuration management trait

use crate::Component;

/// Configuration management functions for encrypted columns
pub trait Config {
    /// Add a column for encryption/decryption.
    ///
    /// Initializes a column to work with CipherStash encryption. The column
    /// must be of type `eql_v2_encrypted`.
    ///
    /// # Parameters
    ///
    /// - `table_name` - Name of the table containing the column
    /// - `column_name` - Name of the column to configure
    /// - `cast_as` - PostgreSQL type for decrypted data (default: 'text')
    /// - `migrating` - Whether this is part of a migration (default: false)
    ///
    /// # Returns
    ///
    /// JSONB containing the updated configuration.
    ///
    /// # Examples
    ///
    /// ```sql
    /// -- Configure a text column for encryption
    /// SELECT eql_v2.add_column('users', 'encrypted_email', 'text');
    ///
    /// -- Configure a JSONB column
    /// SELECT eql_v2.add_column('users', 'encrypted_data', 'jsonb');
    /// ```
    type AddColumnComponent: Component;
    type RemoveColumnComponent: Component;
    type AddSearchConfigComponent: Component;

    /// Get the add_column component
    fn add_column() -> &'static Self::AddColumnComponent;

    /// Remove column configuration completely.
    ///
    /// # Examples
    ///
    /// ```sql
    /// SELECT eql_v2.remove_column('users', 'encrypted_email');
    /// ```
    fn remove_column() -> &'static Self::RemoveColumnComponent;

    /// Add a searchable index to an encrypted column.
    ///
    /// # Supported index types
    ///
    /// - `unique` - Exact equality (uses hmac_256 or blake3)
    /// - `match` - Full-text search (uses bloom_filter)
    /// - `ore` - Range queries and ordering (uses ore_block_u64_8_256)
    /// - `ste_vec` - JSONB containment queries (uses structured encryption)
    ///
    /// # Examples
    ///
    /// ```sql
    /// SELECT eql_v2.add_search_config('users', 'encrypted_email', 'unique', 'text');
    /// SELECT eql_v2.add_search_config('docs', 'encrypted_content', 'match', 'text');
    /// ```
    fn add_search_config() -> &'static Self::AddSearchConfigComponent;
}
