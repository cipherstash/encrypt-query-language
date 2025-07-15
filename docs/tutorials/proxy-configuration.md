# CipherStash Proxy Configuration with EQL functions

Initialize the column using the `eql_v2.add_column` function to enable encryption and decryption via CipherStash Proxy.

```sql
SELECT eql_v2.add_column('users', 'encrypted_email', 'text'); -- where users is the table name and encrypted_email is the column name of type eql_v2_encrypted
```

**Full signature:**
```sql
SELECT eql_v2.add_column(
  'table_name',       -- Name of the table
  'column_name',      -- Name of the column (must be of type eql_v2_encrypted)
  'cast_as',          -- PostgreSQL type to cast decrypted data [optional, defaults to 'text']
  migrating           -- If true, stages changes without immediate activation [optional, defaults to false]
);
```

**Note:** This function allows you to encrypt and decrypt data but does not enable searchable encryption. See [Searching data with EQL](#searching-data-with-eql) for enabling searchable encryption.

## Refreshing CipherStash Proxy Configuration

CipherStash Proxy refreshes the configuration every 60 seconds. To force an immediate refresh, run:

```sql
SELECT eql_v2.reload_config();
```

> Note: This statement must be executed when connected to CipherStash Proxy.
> When connected to the database directly, it is a no-op.

## Storing data

Encrypted data is stored as `jsonb` values in the PostgreSQL database, regardless of the original data type.

You can read more about the data format [here](docs/reference/payload.md).

### Inserting Data

When inserting data into the encrypted column, wrap the plaintext in the appropriate EQL payload. These statements must be run through the CipherStash Proxy to **encrypt** the data.

**Example:**

```sql
INSERT INTO users (encrypted_email) VALUES (
  '{"v":2,"k":"pt","p":"test@example.com","i":{"t":"users","c":"encrypted_email"}}'
);
```

Data is stored in the PostgreSQL database as:

```json
{
  "c": "generated_ciphertext",
  "i": {
    "c": "encrypted_email",
    "t": "users"
  },
  "k": "ct",
  "bf": null,
  "ob": null,
  "u": null,
  "v": 2
}
```

### Reading Data

When querying data, select the encrypted column. CipherStash Proxy will **decrypt** the data automatically.

**Example:**

```sql
SELECT encrypted_email FROM users;
```

Data is returned as:

```json
{
  "k": "pt",
  "p": "test@example.com",
  "i": {
    "t": "users",
    "c": "encrypted_email"
  },
  "v": 2,
  "q": null
}
```

> Note: If you execute this query directly on the database, you will not see any plaintext data but rather the `jsonb` payload with the ciphertext.

## Configuring indexes for searching data

In order to perform searchable operations on encrypted data, you must configure indexes for the encrypted columns.

> **IMPORTANT:** If you have existing data that's encrypted and you add or modify an index, all the data will need to be re-encrypted.
> This is due to the way CipherStash Proxy handles searchable encryption operations.

### Adding an index

Add an index to an encrypted column using the `eql_v2.add_search_config` function:

```sql
SELECT eql_v2.add_search_config(
  'table_name',       -- Name of the table
  'column_name',      -- Name of the column
  'index_name',       -- Index kind ('unique', 'match', 'ore', 'ste_vec')
  'cast_as',          -- PostgreSQL type to cast decrypted data ('text', 'int', etc.) [optional, defaults to 'text']
  'opts',             -- Index options as JSONB [optional, defaults to '{}']
  migrating           -- If true, stages changes without immediate activation [optional, defaults to false]
);
```

You can read more about the index configuration options [here](docs/reference/index-config.md).

**Example (Unique index):**

```sql
SELECT eql_v2.add_search_config(
  'users',
  'encrypted_email',
  'unique',
  'text'
);
```

**Example (With custom options and staging):**

```sql
SELECT eql_v2.add_search_config(
  'users',
  'encrypted_name',
  'match',
  'text',
  '{"k": 6, "bf": 4096}',
  true  -- Stage changes without immediate activation
);
```

Configuration changes are automatically migrated and activated unless the `migrating` parameter is set to `true`.

## Searching data with EQL

EQL provides specialized functions to interact with encrypted data, supporting operations like equality checks, range queries, and unique constraints.

In order to use the specialized functions, you must first configure the corresponding indexes.

### Equality search

Enable equality search on encrypted data using the `eql_v2.hmac_256` function.

**Index configuration example:**

```sql
SELECT eql_v2.add_search_config(
  'users',
  'encrypted_email',
  'unique',
  'text'
);
```

**Example:**

```sql
SELECT * FROM users
WHERE eql_v2.hmac_256(encrypted_email) = eql_v2.hmac_256(
  '{"v":2,"k":"pt","p":"test@example.com","i":{"t":"users","c":"encrypted_email"},"q":"hmac_256"}'
);
```

Equivalent plaintext query:

```sql
SELECT * FROM users WHERE email = 'test@example.com';
```

### Full-text search

Enables basic full-text search on encrypted data using the `eql_v2.bloom_filter` function.

**Index configuration example:**

```sql
SELECT eql_v2.add_search_config(
  'users',
  'encrypted_email',
  'match',
  'text',
  '{"token_filters": [{"kind": "downcase"}], "tokenizer": { "kind": "ngram", "token_length": 3 }}'
);
```

**Example:**

```sql
SELECT * FROM users
WHERE eql_v2.bloom_filter(encrypted_email) @> eql_v2.bloom_filter(
  '{"v":2,"k":"pt","p":"test","i":{"t":"users","c":"encrypted_email"},"q":"match"}'
);
```

Equivalent plaintext query:

```sql
SELECT * FROM users WHERE email LIKE '%test%';
```

### Range queries

Enable range queries on encrypted data using the `eql_v2.ore_block_u64_8_256` function. Supports:

- `ORDER BY`
- `WHERE` with comparison operators (`<`, `<=`, `>`, `>=`, `=`, `<>`)

**Index configuration example:**

```sql
SELECT eql_v2.add_search_config(
  'users',
  'encrypted_date',
  'ore',
  'date'
);
```

**Example (Filtering):**

```sql
SELECT * FROM users
WHERE eql_v2.ore_block_u64_8_256(encrypted_date) < eql_v2.ore_block_u64_8_256(
  '{"v":2,"k":"pt","p":"2023-10-05","i":{"t":"users","c":"encrypted_date"},"q":"ore"}'
);
```

Equivalent plaintext query:

```sql
SELECT * FROM users WHERE date < '2023-10-05';
```

**Example (Ordering):**

```sql
SELECT id FROM users
ORDER BY eql_v2.ore_block_u64_8_256(encrypted_field) DESC;
```

Equivalent plaintext query:

```sql
SELECT id FROM users ORDER BY field DESC;
```

### Array Operations

EQL supports array operations on encrypted data:

```sql
-- Get array length
SELECT eql_v2.jsonb_array_length(encrypted_array) FROM users;

-- Get array elements
SELECT eql_v2.jsonb_array_elements(encrypted_array) FROM users;

-- Get array element ciphertexts
SELECT eql_v2.jsonb_array_elements_text(encrypted_array) FROM users;
```

### JSON Path Operations

EQL supports JSON path operations on encrypted data using the `->` and `->>` operators:

```sql
-- Get encrypted value at path
SELECT encrypted_data->'$.field' FROM users;

-- Get ciphertext at path
SELECT encrypted_data->>'$.field' FROM users;
```

### Containment Operations

For encrypted JSONB data, EQL provides containment operations using the `@>` and `<@` operators:

```sql
-- Check if encrypted_data contains specific structure
SELECT * FROM users
WHERE encrypted_data @> '{"v":2,"k":"pt","p":{"account":{"roles":["admin"]}},"i":{"t":"users","c":"encrypted_data"},"q":"ste_vec"}'::eql_v2_encrypted;

-- Check if structure is contained in encrypted_data
SELECT * FROM users
WHERE '{"v":2,"k":"pt","p":{"roles":["admin"]},"i":{"t":"users","c":"encrypted_data"},"q":"ste_vec"}'::eql_v2_encrypted <@ encrypted_data;
```

### Text Pattern Matching

EQL supports pattern matching with the `~~` (LIKE) operator:

```sql
-- Pattern matching (case-sensitive)
SELECT * FROM users
WHERE encrypted_name ~~ '{"v":2,"k":"pt","p":"Alice%","i":{"t":"users","c":"encrypted_name"},"q":"match"}'::eql_v2_encrypted;

-- Pattern matching (case-insensitive)
SELECT * FROM users
WHERE encrypted_name ~~* '{"v":2,"k":"pt","p":"alice%","i":{"t":"users","c":"encrypted_name"},"q":"match"}'::eql_v2_encrypted;
```

## JSON and JSONB support

EQL supports encrypting entire JSON and JSONB data sets.
This warrants a separate section in the documentation.
You can read more about the JSONB support in the [JSONB reference guide](docs/reference/json-support.md).

## Frequently Asked Questions

### How do I integrate CipherStash EQL with my application?

Use CipherStash Proxy to intercept PostgreSQL queries and handle encryption and decryption automatically.
The proxy interacts with the database using the EQL functions and types defined in this documentation.

Use the [helper packages](#helper-packages-and-examples) to integrate EQL functions into your application.

### Can I use EQL without the CipherStash Proxy?

No, CipherStash Proxy is required to handle the encryption and decryption operations based on the configurations and indexes defined.

### How is data encrypted in the database?

Data is encrypted using CipherStash's cryptographic schemes and stored in the `eql_v2_encrypted` column as a JSONB payload.
Encryption and decryption are handled by CipherStash Proxy.

### What index types are available?

EQL supports the following index types:

- `unique` - For exact equality searches using HMAC-256
- `match` - For full-text search using bloom filters
- `ore` - For range queries and ordering using Order-Revealing Encryption
- `ste_vec` - For JSON/JSONB containment operations using Structured Encryption

### How do I manage configurations?

Use these functions to manage your EQL configurations:

**Column Management:**
- `eql_v2.add_column(table_name, column_name, cast_as DEFAULT 'text', migrating DEFAULT false)` - Add a new encrypted column
- `eql_v2.remove_column(table_name, column_name, migrating DEFAULT false)` - Remove an encrypted column completely

**Index Management:**
- `eql_v2.add_search_config(table_name, column_name, index_name, cast_as DEFAULT 'text', opts DEFAULT '{}', migrating DEFAULT false)` - Add a search index to a column
- `eql_v2.remove_search_config(table_name, column_name, index_name, migrating DEFAULT false)` - Remove a specific search index (preserves column configuration)
- `eql_v2.modify_search_config(table_name, column_name, index_name, cast_as DEFAULT 'text', opts DEFAULT '{}', migrating DEFAULT false)` - Modify an existing search index

**Configuration Management:**
- `eql_v2.migrate_config()` - Manually migrate pending configuration to encrypting state
- `eql_v2.activate_config()` - Manually activate encrypting configuration
- `eql_v2.discard()` - Discard pending configuration changes
- `eql_v2.config()` - View current configuration in tabular format (returns a table with columns: state, relation, col_name, decrypts_as, indexes)

**Note:** All configuration functions automatically migrate and activate changes unless `migrating` is set to `true`. When `migrating` is `true`, changes are staged but not immediately applied, allowing for batch configuration updates.

**Important Behavior Differences:**
- `remove_search_config()` removes only the specified index but preserves the column configuration (including `cast_as` setting)
- `remove_column()` removes the entire column configuration including all its indexes
- Empty configurations (no tables/columns) are automatically maintained as active to reflect the current state