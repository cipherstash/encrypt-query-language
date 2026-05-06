# SQL Documentation Standards

## Required Doxygen Tags

### Mandatory
- `@brief` - One sentence description
- `@param` - For each parameter (with type and description)
- `@return` - Return value description (include structure for JSONB)

### Encouraged
- `@example` - Usage examples (SQL code blocks)
- `@throws` - Exception conditions (when RAISE is used)
- `@internal` - Mark private functions (prefix with `_`)

### Optional
- `@see` - Cross-references
- `@note` - Additional warnings/notes
- `@deprecated` - Migration path for deprecated functions

## Format Examples

### Public Function
```sql
--! @brief Initialize a column for encryption/decryption
--!
--! This function configures the CipherStash Proxy to encrypt/decrypt
--! data in the specified column. Must be called before adding search indexes.
--!
--! @param table_name Text name of table containing the column
--! @param column_name Text name of column to encrypt
--! @param cast_as Text PostgreSQL type to cast decrypted value (default: 'text')
--! @param migrating Boolean whether this is migration operation (default: false)
--! @return JSONB Configuration object with encryption settings
--! @throws Exception if table or column does not exist
--!
--! @example
--! SELECT eql_v2.add_column('users', 'encrypted_email', 'text');
--!
--! @see eql_v2.add_search_config
CREATE FUNCTION eql_v2.add_column(
  table_name text,
  column_name text,
  cast_as text DEFAULT 'text',
  migrating boolean DEFAULT false
) RETURNS jsonb
AS $$ ... $$;
```

### Private Function
```sql
--! @brief Internal helper for encryption validation
--! @internal
--! @param config JSONB Configuration object to validate
--! @return Boolean True if configuration is valid
CREATE FUNCTION eql_v2._validate_config(config jsonb)
  RETURNS boolean
AS $$ ... $$;
```

### Operator
```sql
--! @brief Equality comparison for encrypted values
--!
--! Implements the = operator for encrypted column comparisons.
--! Uses encrypted index terms for comparison without decryption.
--!
--! @param a eql_v2_encrypted Left operand
--! @param b eql_v2_encrypted Right operand
--! @return Boolean True if values are equal via encrypted comparison
--!
--! @example
--! -- Using operator syntax:
--! SELECT * FROM users WHERE encrypted_email = encrypted_value;
--!
--! @see eql_v2.compare
CREATE FUNCTION eql_v2."="(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
AS $$ ... $$;

CREATE OPERATOR = (
  FUNCTION=eql_v2."=",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted
);
```

### Type
```sql
--! @brief Composite type for encrypted column data
--!
--! This is the core type used for all encrypted columns. Data is stored
--! as JSONB with the following structure:
--! - `c`: ciphertext (encrypted value)
--! - `i`: index terms (searchable metadata)
--! - `k`: key ID
--! - `m`: metadata
--!
--! @see eql_v2.ciphertext
--! @see eql_v2.meta_data
CREATE TYPE eql_v2_encrypted AS (
  data jsonb
);
```

### Aggregate
```sql
--! @brief State transition function for grouped_value aggregate
--! @internal
--! @param $1 JSONB Accumulated state
--! @param $2 JSONB New value
--! @return JSONB Updated state
CREATE FUNCTION eql_v2._first_grouped_value(jsonb, jsonb)
  RETURNS jsonb
AS $$ ... $$;

--! @brief Return first non-null value in a group
--!
--! Aggregate function that returns the first non-null encrypted value
--! encountered in a GROUP BY clause.
--!
--! @param input JSONB Encrypted values to aggregate
--! @return JSONB First non-null value in group
--!
--! @example
--! -- Get first email per user group
--! SELECT user_id, eql_v2.grouped_value(encrypted_email)
--! FROM user_emails
--! GROUP BY user_id;
--!
--! @see eql_v2._first_grouped_value
CREATE AGGREGATE eql_v2.grouped_value(jsonb) (
  SFUNC = eql_v2._first_grouped_value,
  STYPE = jsonb
);
```
