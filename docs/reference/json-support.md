# EQL with JSON and JSONB

EQL supports encrypting, decrypting, and searching JSON and JSONB objects using structured encryption (ste_vec).

## On this page

- [Configuring the index](#configuring-the-index)
  - [Inserting JSON data](#inserting-json-data)
  - [Reading JSON data](#reading-json-data)
- [Querying JSONB data with EQL](#querying-jsonb-data-with-eql)
  - [Containment queries (`@>`, `<@`)](#containment-queries---)
  - [Field extraction (`jsonb_path_query`)](#field-extraction-jsonb_path_query)
  - [JSON path operators (`->`, `->>`)](#json-path-operators---)
  - [Array operations](#array-operations)
  - [Grouping data](#grouping-data)
- [EQL functions for JSONB and `ste_vec`](#eql-functions-for-jsonb-and-ste_vec)
- [How ste_vec indexing works](#how-ste_vec-indexing-works)

## Configuring the index

To enable searchable operations on encrypted JSONB data, configure an `ste_vec` index with the `jsonb` cast type.

```sql
SELECT eql_v2.add_search_config(
  'users',
  'encrypted_json',
  'ste_vec',
  'jsonb',
  '{"prefix": "users/encrypted_json"}'
);
```

The `prefix` option is required and should be unique per table/column combination (typically `"table/column"`).

You can read more about the index configuration options [here](./index-config.md).

### Inserting JSON data

When inserting JSON data through CipherStash Proxy or Protect.js, wrap the data in the EQL payload format:

```sql
INSERT INTO users (encrypted_json) VALUES (
  '{"v":2,"k":"pt","p":"{\"name\":\"John Doe\",\"metadata\":{\"age\":42}}","i":{"t":"users","c":"encrypted_json"}}'
);
```

Data is stored in the database with encrypted ste_vec indexes:

```json
{
  "i": {
    "c": "encrypted_json",
    "t": "users"
  },
  "k": "sv",
  "v": 2,
  "sv": [["encrypted_term_1"], ["encrypted_term_2"], ...]
}
```

### Reading JSON data

When querying through CipherStash Proxy or Protect.js, the encrypted column is automatically decrypted:

```sql
SELECT encrypted_json FROM users;
```

## Querying JSONB data with EQL

EQL provides specialized functions and operators to work with encrypted JSONB data.

### Containment queries (`@>`, `<@`)

Use PostgreSQL's containment operators directly on `eql_v2_encrypted` columns to check if one JSONB structure contains another.

**Example: Check if column contains structure**

Suppose we have encrypted JSONB data:

```json
{
  "top": {
    "nested": ["a", "b", "c"]
  }
}
```

Query records that contain a specific structure:

```sql
SELECT * FROM examples
WHERE encrypted_json @> '{"v":2,"k":"pt","p":"{\"top\":{\"nested\":[\"a\"]}}","i":{"t":"examples","c":"encrypted_json"},"q":"ste_vec"}'::eql_v2_encrypted;
```

Equivalent plaintext query:

```sql
SELECT * FROM examples
WHERE jsonb_column @> '{"top":{"nested":["a"]}}';
```

**Note:** The `@>` operator checks if the left value contains the right value. The `<@` operator checks the reverse (if left is contained in right).

#### Indexed Containment Queries

For better performance on large tables, create a GIN index and use the `jsonb_array()` function:

```sql
-- Create GIN index
CREATE INDEX idx_encrypted_jsonb_gin
ON examples USING GIN (eql_v2.jsonb_array(encrypted_json));
ANALYZE examples;

-- Query using the GIN index
SELECT * FROM examples
WHERE eql_v2.jsonb_array(encrypted_json) @>
      eql_v2.jsonb_array($1::eql_v2_encrypted);
```

See [GIN Indexes for JSONB Containment](./database-indexes.md#gin-indexes-for-jsonb-containment) for complete setup instructions.

### Field extraction (`jsonb_path_query`)

Extract fields from encrypted JSONB using selector hashes. Selectors are generated during encryption and identify specific JSON paths.

**Function signature:**

```sql
eql_v2.jsonb_path_query(val eql_v2_encrypted, selector text) RETURNS SETOF eql_v2_encrypted
```

**Example:**

```sql
-- Extract all records where selector 'abc123...' exists
SELECT eql_v2.jsonb_path_query(encrypted_json, 'abc123def456...')
FROM examples;

-- Get first match only
SELECT eql_v2.jsonb_path_query_first(encrypted_json, 'abc123def456...')
FROM examples;

-- Check if selector exists
SELECT eql_v2.jsonb_path_exists(encrypted_json, 'abc123def456...')
FROM examples;
```

**Note:** Selectors are hash-based identifiers for JSON paths, not the actual path strings like `$.field`. They are generated during encryption by CipherStash Proxy/Protect.js.

### JSON path operators (`->`, `->>`)

Use standard PostgreSQL JSON operators on encrypted columns:

```sql
-- Extract field by selector (returns eql_v2_encrypted)
SELECT encrypted_json->'selector_hash' FROM examples;

-- Extract field as text (returns encrypted value as text)
SELECT encrypted_json->>'selector_hash' FROM examples;

-- Extract array element by index (0-based, returns eql_v2_encrypted)
SELECT encrypted_array->0 FROM examples;
```

**Note:** The `->` operator supports integer array indexing (e.g., `encrypted_array->0`), but the `->>` operator does not. Use `->` to access array elements by index.

### Array operations

EQL supports array operations on encrypted JSONB arrays:

**Get array length:**

```sql
SELECT eql_v2.jsonb_array_length(encrypted_array_field)
FROM examples;
```

**Get array elements:**

```sql
-- Returns SETOF eql_v2_encrypted
SELECT eql_v2.jsonb_array_elements(encrypted_array_field)
FROM examples;

-- Returns SETOF text (ciphertext)
SELECT eql_v2.jsonb_array_elements_text(encrypted_array_field)
FROM examples;
```

**Example with jsonb_path_query:**

```sql
-- First query the array field, then get its elements
SELECT eql_v2.jsonb_array_elements(
  eql_v2.jsonb_path_query(encrypted_json, 'array_selector_hash')
)
FROM examples;
```

### Grouping data

Use `eql_v2.grouped_value()` aggregate function to group encrypted JSONB results:

```sql
SELECT eql_v2.grouped_value(
  eql_v2.jsonb_path_query_first(encrypted_json, 'color_selector')::jsonb
) AS color,
COUNT(*)
FROM examples
GROUP BY eql_v2.jsonb_path_query_first(encrypted_json, 'color_selector');
```

**Result:**

| color | count |
| ----- | ----- |
| {"k":"pt","p":"blue",...} | 3     |
| {"k":"pt","p":"green",...} | 2     |
| {"k":"pt","p":"red",...} | 1     |

## EQL functions for JSONB and `ste_vec`

### Core Functions

- **`eql_v2.ste_vec(val jsonb) RETURNS eql_v2_encrypted[]`**
  - Extracts the ste_vec index array from a JSONB payload

- **`eql_v2.ste_vec(val eql_v2_encrypted) RETURNS eql_v2_encrypted[]`**
  - Extracts the ste_vec index array from an encrypted value

- **`eql_v2.ste_vec_contains(a eql_v2_encrypted, b eql_v2_encrypted) RETURNS boolean`**
  - Returns true if all ste_vec terms in b exist in a
  - This is the function backing the `@>` operator

### Path Query Functions

- **`eql_v2.jsonb_path_query(val eql_v2_encrypted, selector text) RETURNS SETOF eql_v2_encrypted`**
  - Returns all encrypted elements matching the selector

- **`eql_v2.jsonb_path_query_first(val eql_v2_encrypted, selector text) RETURNS eql_v2_encrypted`**
  - Returns the first encrypted element matching the selector

- **`eql_v2.jsonb_path_exists(val eql_v2_encrypted, selector text) RETURNS boolean`**
  - Returns true if any element matches the selector

### Array Functions

- **`eql_v2.jsonb_array_length(val eql_v2_encrypted) RETURNS integer`**
  - Returns the length of an encrypted array

- **`eql_v2.jsonb_array_elements(val eql_v2_encrypted) RETURNS SETOF eql_v2_encrypted`**
  - Returns each array element as an encrypted value

- **`eql_v2.jsonb_array_elements_text(val eql_v2_encrypted) RETURNS SETOF text`**
  - Returns each array element's ciphertext as text

### Helper Functions

- **`eql_v2.is_ste_vec_array(val eql_v2_encrypted) RETURNS boolean`**
  - Returns true if the value represents an encrypted array

- **`eql_v2.is_ste_vec_value(val eql_v2_encrypted) RETURNS boolean`**
  - Returns true if the value is a single ste_vec element

- **`eql_v2.to_ste_vec_value(val eql_v2_encrypted) RETURNS eql_v2_encrypted`**
  - Converts a ste_vec array with a single element to a regular encrypted value

- **`eql_v2.selector(val eql_v2_encrypted) RETURNS text`**
  - Extracts the selector hash from an encrypted value

### GIN-Indexable Functions

These functions enable efficient GIN-indexed containment queries. See [GIN Indexes for JSONB Containment](./database-indexes.md#gin-indexes-for-jsonb-containment) for index setup.

- **`eql_v2.jsonb_array(val eql_v2_encrypted) RETURNS jsonb[]`**
  - Extracts encrypted JSONB as native PostgreSQL jsonb array for GIN indexing
  - Create GIN indexes on this function for indexed containment queries

- **`eql_v2.jsonb_contains(a eql_v2_encrypted, b eql_v2_encrypted) RETURNS boolean`**
  - GIN-indexed containment check: returns true if a contains b
  - Alternative to `jsonb_array(a) @> jsonb_array(b)`

- **`eql_v2.jsonb_contained_by(a eql_v2_encrypted, b eql_v2_encrypted) RETURNS boolean`**
  - GIN-indexed reverse containment: returns true if a is contained by b
  - Alternative to `jsonb_array(a) <@ jsonb_array(b)`

### Aggregate Functions

- **`eql_v2.grouped_value(jsonb) RETURNS jsonb`**
  - Aggregate function for grouping encrypted values (returns first non-null value in group)

## How ste_vec indexing works

Structured Encryption (ste_vec) creates searchable indexes for JSONB by:

1. **Flattening the JSON structure** - Each unique path to a leaf value gets a selector (hash)
2. **Creating encrypted terms** - Each path prefix and value is encrypted separately
3. **Storing as array** - All encrypted terms are stored in the `sv` (ste_vec) array

**Example document:**

```json
{
  "account": {
    "email": "alice@example.com",
    "roles": ["admin", "owner"]
  }
}
```

**Creates selectors for:**
- `$` (root object)
- `$.account` (account object)
- `$.account.email` (email field)
- `$.account.email` with value "alice@example.com"
- `$.account.roles` (roles array)
- `$.account.roles[]` (each role value)

**Querying:**

Containment queries (`@>`) check if all required encrypted terms exist in the target's ste_vec array. This enables queries like:

```sql
-- Find records where account.email = "alice@example.com"
WHERE encrypted_data @> '<encrypted_query_payload>'::eql_v2_encrypted

-- Find records where account.roles contains "admin"
WHERE encrypted_data @> '<encrypted_query_payload>'::eql_v2_encrypted
```

The actual encryption and selector generation is handled by CipherStash Proxy or Protect.js, not by EQL directly.

---

### Didn't find what you wanted?

[Click here to let us know what was missing from our docs.](https://github.com/cipherstash/encrypt-query-language/issues/new?template=docs-feedback.yml&title=[Docs:]%20Feedback%20on%20json-support.md)
