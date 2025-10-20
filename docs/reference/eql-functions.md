# EQL Functions Reference

This document provides a comprehensive reference for all EQL (Encrypt Query Language) functions available for querying encrypted data in PostgreSQL.

## Table of Contents

- [Configuration Functions](#configuration-functions)
- [Query Functions](#query-functions)
  - [Operators (Recommended)](#operators-recommended)
  - [Function Equivalents](#function-equivalents)
- [Index Term Extraction Functions](#index-term-extraction-functions)
- [JSONB Path Functions](#jsonb-path-functions)
- [Array Functions](#array-functions)
- [Helper Functions](#helper-functions)
- [Aggregate Functions](#aggregate-functions)
- [Utility Functions](#utility-functions)

---

## Configuration Functions

These functions manage encrypted column configurations. See [Configuration Tutorial](../tutorials/proxy-configuration.md) for detailed usage.

### `eql_v2.add_column()`

Initialize a column for encryption/decryption.

```sql
eql_v2.add_column(
  table_name text,
  column_name text,
  cast_as text DEFAULT 'text',
  migrating boolean DEFAULT false
) RETURNS jsonb
```

**Example:**
```sql
SELECT eql_v2.add_column('users', 'encrypted_email', 'text');
```

### `eql_v2.add_search_config()`

Add a searchable index to an encrypted column.

```sql
eql_v2.add_search_config(
  table_name text,
  column_name text,
  index_name text,              -- 'unique', 'match', 'ore', 'ste_vec'
  cast_as text DEFAULT 'text',
  opts jsonb DEFAULT '{}',
  migrating boolean DEFAULT false
) RETURNS jsonb
```

**Supported index types:**
- `unique` - Exact equality (uses hmac_256 or blake3)
- `match` - Full-text search (uses bloom_filter)
- `ore` - Range queries and ordering (uses ore_block_u64_8_256)
- `ste_vec` - JSONB containment queries (uses structured encryption)

**Example:**
```sql
SELECT eql_v2.add_search_config('users', 'encrypted_email', 'unique', 'text');
SELECT eql_v2.add_search_config('docs', 'encrypted_content', 'match', 'text');
SELECT eql_v2.add_search_config('events', 'encrypted_data', 'ste_vec', 'jsonb', '{"prefix": "events/encrypted_data"}');
```

### `eql_v2.remove_column()`

Remove column configuration completely.

```sql
eql_v2.remove_column(
  table_name text,
  column_name text,
  migrating boolean DEFAULT false
) RETURNS jsonb
```

### `eql_v2.remove_search_config()`

Remove a specific search index (preserves column configuration).

```sql
eql_v2.remove_search_config(
  table_name text,
  column_name text,
  index_name text,
  migrating boolean DEFAULT false
) RETURNS jsonb
```

### `eql_v2.modify_search_config()`

Modify an existing search index configuration.

```sql
eql_v2.modify_search_config(
  table_name text,
  column_name text,
  index_name text,
  cast_as text DEFAULT 'text',
  opts jsonb DEFAULT '{}',
  migrating boolean DEFAULT false
) RETURNS jsonb
```

### `eql_v2.config()`

View current configuration in tabular format.

```sql
eql_v2.config() RETURNS TABLE (
  state eql_v2_configuration_state,
  relation text,
  col_name text,
  decrypts_as text,
  indexes jsonb
)
```

**Example:**
```sql
SELECT * FROM eql_v2.config();
```

### `eql_v2.migrate_config()`

Transition pending configuration to encrypting state.

```sql
eql_v2.migrate_config() RETURNS boolean
```

**Description:**
- Validates that all configured columns exist with `eql_v2_encrypted` type
- Marks the pending configuration as 'encrypting'
- Required before activating a new configuration

**Raises exception if:**
- An encryption is already in progress
- No pending configuration exists
- Some pending columns don't have encrypted targets

**Example:**
```sql
-- Add configuration changes
SELECT eql_v2.add_search_config('users', 'email', 'unique', 'text', migrating => true);

-- Validate and migrate
SELECT eql_v2.migrate_config();

-- After re-encrypting data, activate
SELECT eql_v2.activate_config();
```

### `eql_v2.activate_config()`

Activate an encrypting configuration.

```sql
eql_v2.activate_config() RETURNS boolean
```

**Description:**
- Moves 'encrypting' configuration to 'active' state
- Marks previous 'active' configuration as 'inactive'
- Should be called after data has been re-encrypted with new index terms

**Raises exception if:**
- No encrypting configuration exists

**Example:**
```sql
SELECT eql_v2.activate_config();
```

### `eql_v2.discard()`

Discard pending configuration without activating.

```sql
eql_v2.discard() RETURNS boolean
```

**Description:**
- Deletes the pending configuration
- Use when you want to abandon configuration changes

**Raises exception if:**
- No pending configuration exists

**Example:**
```sql
SELECT eql_v2.discard();
```

### `eql_v2.reload_config()`

Reload active configuration (no-op for compatibility).

```sql
eql_v2.reload_config() RETURNS void
```

**Description:**
- Placeholder function for configuration reload
- Currently has no effect (configuration is loaded automatically)

---

## Query Functions

### Operators (Recommended)

EQL overloads standard PostgreSQL operators to work directly on `eql_v2_encrypted` columns. **Use these whenever possible.**

#### Equality

```sql
-- Exact match (uses 'unique' index: hmac_256 or blake3)
SELECT * FROM users WHERE encrypted_email = $1::eql_v2_encrypted;
SELECT * FROM users WHERE encrypted_email = $1::jsonb;

-- Not equal
SELECT * FROM users WHERE encrypted_email <> $1::eql_v2_encrypted;
```

#### Full-Text Match

```sql
-- Case-sensitive LIKE (uses 'match' index: bloom_filter)
SELECT * FROM docs WHERE encrypted_content ~~ $1::eql_v2_encrypted;
SELECT * FROM docs WHERE encrypted_content LIKE $1::eql_v2_encrypted;

-- Case-insensitive ILIKE
SELECT * FROM docs WHERE encrypted_content ~~* $1::eql_v2_encrypted;
SELECT * FROM docs WHERE encrypted_content ILIKE $1::eql_v2_encrypted;
```

#### Range Comparisons

```sql
-- Uses 'ore' index: ore_block_u64_8_256
SELECT * FROM events WHERE encrypted_date < $1::eql_v2_encrypted;
SELECT * FROM events WHERE encrypted_date <= $1::eql_v2_encrypted;
SELECT * FROM events WHERE encrypted_date > $1::eql_v2_encrypted;
SELECT * FROM events WHERE encrypted_date >= $1::eql_v2_encrypted;

-- Ordering
SELECT * FROM events ORDER BY encrypted_date DESC;
SELECT * FROM events ORDER BY encrypted_date ASC;
```

#### JSONB Containment

```sql
-- Uses 'ste_vec' index
SELECT * FROM users WHERE encrypted_data @> $1::eql_v2_encrypted;
SELECT * FROM users WHERE encrypted_data <@ $1::eql_v2_encrypted;
```

#### JSON Path Access

```sql
-- Extract field by selector hash (returns eql_v2_encrypted)
SELECT encrypted_json->'abc123...' FROM users;
SELECT encrypted_json->encrypted_selector FROM users;

-- Extract field by array index (returns eql_v2_encrypted)
SELECT encrypted_json->0 FROM users;

-- Extract field as ciphertext (returns text)
SELECT encrypted_json->>'abc123...' FROM users;
SELECT encrypted_json->>encrypted_selector FROM users;
```

### Function Equivalents

For environments that don't support custom operators (like Supabase), use these function versions:

#### `eql_v2.eq()`

Equality comparison.

```sql
eql_v2.eq(a eql_v2_encrypted, b eql_v2_encrypted) RETURNS boolean
```

**Example:**
```sql
SELECT * FROM users WHERE eql_v2.eq(encrypted_email, $1::eql_v2_encrypted);
```

#### `eql_v2.neq()`

Not-equal comparison.

```sql
eql_v2.neq(a eql_v2_encrypted, b eql_v2_encrypted) RETURNS boolean
```

#### `eql_v2.like()`

Pattern matching (case-sensitive).

```sql
eql_v2.like(a eql_v2_encrypted, b eql_v2_encrypted) RETURNS boolean
```

**Example:**
```sql
SELECT * FROM docs WHERE eql_v2.like(encrypted_content, $1::eql_v2_encrypted);
```

#### `eql_v2.ilike()`

Pattern matching (case-insensitive).

```sql
eql_v2.ilike(a eql_v2_encrypted, b eql_v2_encrypted) RETURNS boolean
```

**Example:**
```sql
SELECT * FROM docs WHERE eql_v2.ilike(encrypted_content, $1::eql_v2_encrypted);
```

#### `eql_v2.lt()`

Less than comparison.

```sql
eql_v2.lt(a eql_v2_encrypted, b eql_v2_encrypted) RETURNS boolean
```

**Example:**
```sql
SELECT * FROM events WHERE eql_v2.lt(encrypted_date, $1::eql_v2_encrypted);
```

#### `eql_v2.lte()`

Less than or equal comparison.

```sql
eql_v2.lte(a eql_v2_encrypted, b eql_v2_encrypted) RETURNS boolean
```

**Example:**
```sql
SELECT * FROM events WHERE eql_v2.lte(encrypted_date, $1::eql_v2_encrypted);
```

#### `eql_v2.gt()`

Greater than comparison.

```sql
eql_v2.gt(a eql_v2_encrypted, b eql_v2_encrypted) RETURNS boolean
```

**Example:**
```sql
SELECT * FROM events WHERE eql_v2.gt(encrypted_date, $1::eql_v2_encrypted);
```

#### `eql_v2.gte()`

Greater than or equal comparison.

```sql
eql_v2.gte(a eql_v2_encrypted, b eql_v2_encrypted) RETURNS boolean
```

**Example:**
```sql
SELECT * FROM events WHERE eql_v2.gte(encrypted_date, $1::eql_v2_encrypted);
```

---

## Index Term Extraction Functions

These functions extract specific index terms from encrypted values. Typically used internally by operators, but available for advanced use cases.

### `eql_v2.hmac_256()`

Extract HMAC-256 unique index term.

```sql
eql_v2.hmac_256(val eql_v2_encrypted) RETURNS eql_v2.hmac_256
eql_v2.hmac_256(val jsonb) RETURNS eql_v2.hmac_256
```

### `eql_v2.blake3()`

Extract Blake3 unique index term.

```sql
eql_v2.blake3(val eql_v2_encrypted) RETURNS eql_v2.blake3
eql_v2.blake3(val jsonb) RETURNS eql_v2.blake3
```

### `eql_v2.bloom_filter()`

Extract bloom filter match index term.

```sql
eql_v2.bloom_filter(val eql_v2_encrypted) RETURNS eql_v2.bloom_filter
eql_v2.bloom_filter(val jsonb) RETURNS eql_v2.bloom_filter
```

### `eql_v2.ore_block_u64_8_256()`

Extract ORE (Order-Revealing Encryption) index term.

```sql
eql_v2.ore_block_u64_8_256(val eql_v2_encrypted) RETURNS eql_v2.ore_block_u64_8_256
eql_v2.ore_block_u64_8_256(val jsonb) RETURNS eql_v2.ore_block_u64_8_256
```

### `eql_v2.ste_vec()`

Extract structured encryption vector array.

```sql
eql_v2.ste_vec(val eql_v2_encrypted) RETURNS eql_v2_encrypted[]
eql_v2.ste_vec(val jsonb) RETURNS eql_v2_encrypted[]
```

---

## JSONB Path Functions

Functions for querying encrypted JSONB data using selector hashes.

### `eql_v2.jsonb_path_query()`

Returns all encrypted elements matching a selector.

```sql
eql_v2.jsonb_path_query(val eql_v2_encrypted, selector text) RETURNS SETOF eql_v2_encrypted
eql_v2.jsonb_path_query(val eql_v2_encrypted, selector eql_v2_encrypted) RETURNS SETOF eql_v2_encrypted
eql_v2.jsonb_path_query(val jsonb, selector text) RETURNS SETOF eql_v2_encrypted
```

**Example:**
```sql
SELECT eql_v2.jsonb_path_query(encrypted_json, 'abc123...') FROM users;
```

### `eql_v2.jsonb_path_query_first()`

Returns the first encrypted element matching a selector.

```sql
eql_v2.jsonb_path_query_first(val eql_v2_encrypted, selector text) RETURNS eql_v2_encrypted
eql_v2.jsonb_path_query_first(val eql_v2_encrypted, selector eql_v2_encrypted) RETURNS eql_v2_encrypted
eql_v2.jsonb_path_query_first(val jsonb, selector text) RETURNS eql_v2_encrypted
```

### `eql_v2.jsonb_path_exists()`

Checks if any element matches a selector.

```sql
eql_v2.jsonb_path_exists(val eql_v2_encrypted, selector text) RETURNS boolean
eql_v2.jsonb_path_exists(val eql_v2_encrypted, selector eql_v2_encrypted) RETURNS boolean
eql_v2.jsonb_path_exists(val jsonb, selector text) RETURNS boolean
```

**Example:**
```sql
SELECT * FROM users
WHERE eql_v2.jsonb_path_exists(encrypted_json, 'email_selector');
```

---

## Array Functions

Functions for working with encrypted arrays.

### `eql_v2.jsonb_array_length()`

Returns the length of an encrypted array.

```sql
eql_v2.jsonb_array_length(val eql_v2_encrypted) RETURNS integer
eql_v2.jsonb_array_length(val jsonb) RETURNS integer
```

**Example:**
```sql
SELECT eql_v2.jsonb_array_length(encrypted_array) FROM users;
```

### `eql_v2.jsonb_array_elements()`

Returns each array element as an encrypted value.

```sql
eql_v2.jsonb_array_elements(val eql_v2_encrypted) RETURNS SETOF eql_v2_encrypted
eql_v2.jsonb_array_elements(val jsonb) RETURNS SETOF eql_v2_encrypted
```

**Example:**
```sql
SELECT eql_v2.jsonb_array_elements(
  eql_v2.jsonb_path_query(encrypted_json, 'array_selector')
) FROM users;
```

### `eql_v2.jsonb_array_elements_text()`

Returns each array element's ciphertext as text.

```sql
eql_v2.jsonb_array_elements_text(val eql_v2_encrypted) RETURNS SETOF text
eql_v2.jsonb_array_elements_text(val jsonb) RETURNS SETOF text
```

---

## Helper Functions

Utility functions for working with encrypted data.

### `eql_v2.ciphertext()`

Extract ciphertext from encrypted value.

```sql
eql_v2.ciphertext(val eql_v2_encrypted) RETURNS text
eql_v2.ciphertext(val jsonb) RETURNS text
```

### `eql_v2.meta_data()`

Extract metadata (table/column identifiers and version).

```sql
eql_v2.meta_data(val eql_v2_encrypted) RETURNS jsonb
eql_v2.meta_data(val jsonb) RETURNS jsonb
```

### `eql_v2.selector()`

Extract selector hash from encrypted value.

```sql
eql_v2.selector(val eql_v2_encrypted) RETURNS text
```

### `eql_v2.is_ste_vec_array()`

Check if value represents an encrypted array.

```sql
eql_v2.is_ste_vec_array(val eql_v2_encrypted) RETURNS boolean
```

### `eql_v2.is_ste_vec_value()`

Check if value is a single ste_vec element.

```sql
eql_v2.is_ste_vec_value(val eql_v2_encrypted) RETURNS boolean
```

### `eql_v2.to_ste_vec_value()`

Convert ste_vec array with single element to regular encrypted value.

```sql
eql_v2.to_ste_vec_value(val eql_v2_encrypted) RETURNS eql_v2_encrypted
```

### `eql_v2.ste_vec_contains()`

Check if all ste_vec terms in b exist in a (backs the `@>` operator).

```sql
eql_v2.ste_vec_contains(a eql_v2_encrypted, b eql_v2_encrypted) RETURNS boolean
```

### `eql_v2.has_hmac_256()`

Check if value contains hmac_256 index term.

```sql
eql_v2.has_hmac_256(val eql_v2_encrypted) RETURNS boolean
```

### `eql_v2.has_blake3()`

Check if value contains blake3 index term.

```sql
eql_v2.has_blake3(val eql_v2_encrypted) RETURNS boolean
```

### `eql_v2.has_bloom_filter()`

Check if value contains bloom_filter index term.

```sql
eql_v2.has_bloom_filter(val eql_v2_encrypted) RETURNS boolean
```

### `eql_v2.has_ore_block_u64_8_256()`

Check if value contains ore index term.

```sql
eql_v2.has_ore_block_u64_8_256(val eql_v2_encrypted) RETURNS boolean
```

---

## Aggregate Functions

### `eql_v2.grouped_value()`

Aggregate function for grouping encrypted values (returns first non-null value in group).

```sql
eql_v2.grouped_value(jsonb) RETURNS jsonb
```

**Example:**
```sql
SELECT eql_v2.grouped_value(
  eql_v2.jsonb_path_query_first(encrypted_json, 'color_selector')::jsonb
) AS color,
COUNT(*)
FROM products
GROUP BY eql_v2.jsonb_path_query_first(encrypted_json, 'color_selector');
```

### `eql_v2.min()`

Returns the minimum encrypted value in a set (requires `ore` index for ordering).

```sql
eql_v2.min(eql_v2_encrypted) RETURNS eql_v2_encrypted
```

**Example:**
```sql
SELECT eql_v2.min(encrypted_date) FROM events;
SELECT eql_v2.min(encrypted_price) FROM products WHERE category = 'electronics';
```

### `eql_v2.max()`

Returns the maximum encrypted value in a set (requires `ore` index for ordering).

```sql
eql_v2.max(eql_v2_encrypted) RETURNS eql_v2_encrypted
```

**Example:**
```sql
SELECT eql_v2.max(encrypted_date) FROM events;
SELECT eql_v2.max(encrypted_price) FROM products WHERE category = 'electronics';
```

---

## Utility Functions

### `eql_v2.version()`

Get the installed EQL version.

```sql
eql_v2.version() RETURNS text
```

**Example:**
```sql
SELECT eql_v2.version();
-- Returns version string (e.g., '2.1.8')
```

### `eql_v2.to_encrypted()`

Convert jsonb or text to eql_v2_encrypted type.

```sql
eql_v2.to_encrypted(data jsonb) RETURNS eql_v2_encrypted
eql_v2.to_encrypted(data text) RETURNS eql_v2_encrypted
```

**Example:**
```sql
-- Convert jsonb payload to encrypted type
SELECT eql_v2.to_encrypted('{"v":2,"k":"pt","p":"plaintext"}'::jsonb);

-- Convert text payload to encrypted type
SELECT eql_v2.to_encrypted('{"v":2,"k":"pt","p":"plaintext"}');
```

### `eql_v2.to_jsonb()`

Convert eql_v2_encrypted to jsonb.

```sql
eql_v2.to_jsonb(e eql_v2_encrypted) RETURNS jsonb
```

**Example:**
```sql
SELECT eql_v2.to_jsonb(encrypted_column) FROM users;
```

### `eql_v2.check_encrypted()`

Validate encrypted payload structure (used in constraints).

```sql
eql_v2.check_encrypted(val jsonb) RETURNS boolean
eql_v2.check_encrypted(val eql_v2_encrypted) RETURNS boolean
```

**Description:**
- Validates that encrypted value has required fields (`v`, `c`, `i`)
- Checks that version is `2` and identifier contains table (`t`) and column (`c`) fields
- Returns true if valid, raises exception if invalid
- Automatically added as constraint when using `eql_v2.add_column()`

**Example:**
```sql
SELECT eql_v2.check_encrypted('{"v":2,"c":"ciphertext","i":{"t":"users","c":"email"}}'::jsonb);
-- Returns: true

SELECT eql_v2.check_encrypted('{"invalid":"structure"}'::jsonb);
-- Raises exception: 'Encrypted column missing version (v) field'
```

---

## See Also

- [EQL Configuration Guide](../tutorials/proxy-configuration.md) - How to set up encrypted columns
- [Database Indexes](./database-indexes.md) - PostgreSQL B-tree index creation and usage
- [JSON/JSONB Support](./json-support.md) - Working with encrypted JSON data
- [Index Configuration](./index-config.md) - Index types and configuration options
- [Payload Format](./PAYLOAD.md) - EQL data format specification

---

### Didn't find what you wanted?

[Click here to let us know what was missing from our docs.](https://github.com/cipherstash/encrypt-query-language/issues/new?template=docs-feedback.yml&title=[Docs:]%20Feedback%20on%20eql-functions.md)
