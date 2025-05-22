# Encrypt Query Language (EQL)

[![Test EQL](https://github.com/cipherstash/encrypt-query-language/actions/workflows/test-eql.yml/badge.svg?branch=main)](https://github.com/cipherstash/encrypt-query-language/actions/workflows/test-eql.yml)
[![Release EQL](https://github.com/cipherstash/encrypt-query-language/actions/workflows/release-eql.yml/badge.svg?branch=main)](https://github.com/cipherstash/encrypt-query-language/actions/workflows/release-eql.yml)

Encrypt Query Language (EQL) is a set of abstractions for transmitting, storing, and interacting with encrypted data and indexes in PostgreSQL.

> [!TIP] > **New to EQL?** Start with the higher level helpers for EQL in [Python](https://github.com/cipherstash/eqlpy), [Go](https://github.com/cipherstash/goeql), or [JavaScript](https://github.com/cipherstash/jseql) and [TypeScript](https://github.com/cipherstash/jseql), or the [examples](#helper-packages-and-examples) for those languages.

Store encrypted data alongside your existing data:

- Encrypted data is stored using a `jsonb` column type
- Query encrypted data with specialized SQL functions
- Index encrypted columns to enable searchable encryption
- Integrate with [CipherStash Proxy](/docs/tutorials/PROXY.md) for transparent encryption/decryption.

## Table of Contents

- [Installation](#installation)
  - [CipherStash Proxy](#cipherstash-proxy)
- [Documentation](#documentation)
- [Getting started](#getting-started)
  - [Enable encrypted columns](#enable-encrypted-columns)
  - [Configuring the column](#configuring-the-column)
  - [Activating configuration](#activating-configuration)
    - [Refreshing CipherStash Proxy Configuration](#refreshing-cipherstash-proxy-configuration)
- [Storing data](#storing-data)
  - [Inserting Data](#inserting-data)
  - [Reading Data](#reading-data)
- [Configuring indexes for searching data](#configuring-indexes-for-searching-data)
  - [Adding an index](#adding-an-index)
- [Searching data with EQL](#searching-data-with-eql)
  - [Equality search](#equality-search)
  - [Full-text search](#full-text-search)
  - [Range queries](#range-queries)
  - [Array Operations](#array-operations)
  - [JSON Path Operations](#json-path-operations)
- [JSON and JSONB support](#json-and-jsonb-support)
- [Frequently Asked Questions](#frequently-asked-questions)
- [Helper packages](#helper-packages-and-examples)
- [Releasing](#releasing)
- [Developing](#developing)
- [Testing](#testing)

---

## Installation

The simplest way to get up and running with EQL is to execute the install SQL file directly in your PostgreSQL database.

1. Download the latest EQL install script:

   ```sh
   curl -sLo cipherstash-encrypt.sql https://github.com/cipherstash/encrypt-query-language/releases/latest/download/cipherstash-encrypt.sql
   ```

2. Run this command to install the custom types and functions:

   ```sh
   psql -f cipherstash-encrypt.sql
   ```

### CipherStash Proxy

EQL relies on [CipherStash Proxy](docs/tutorials/PROXY.md) for low-latency encryption & decryption.
We plan to support direct language integration in the future.

If you want to use CipherStash Proxy with the below examples or the [helper packages](#helper-packages-and-examples), you can use the [playground environment](playground/README.md).

## Documentation

You can read more about the EQL concepts and reference guides in the [documentation directory](docs/README.md).

## Getting started

Once the custom types and functions are installed in your PostgreSQL database, you can start using EQL in your queries.

### Enable encrypted columns

Define encrypted columns using the `eql_v2_encrypted` type, which extends the `jsonb` type with additional constraints to ensure data integrity.

**Example:**

```sql
CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    encrypted_email eql_v2_encrypted
);
```

### Configuring the column

Initialize the column using the `eql_v2.add_column` function to enable encryption and decryption via CipherStash Proxy.

```sql
SELECT eql_v2.add_column('users', 'encrypted_email');
```

**Note:** This function allows you to encrypt and decrypt data but does not enable searchable encryption. See [Searching data with EQL](#searching-data-with-eql) for enabling searchable encryption.

### Activating configuration

After modifying configurations, activate them by running:

```sql
SELECT eql_v2.encrypt();
SELECT eql_v2.activate();
```

**Important:** These functions must be run after any modifications to the configuration.

#### Refreshing CipherStash Proxy Configuration

CipherStash Proxy refreshes the configuration every 60 seconds. To force an immediate refresh, run:

```sql
SELECT eql_v2.reload_config();
```

> Note: This statement must be executed when connected to CipherStash Proxy.
> When connected to the database directly, it is a no-op.

## Storing data

Encrypted data is stored as `jsonb` values in the PostgreSQL database, regardless of the original data type.

You can read more about the data format [here](docs/reference/PAYLOAD.md).

### Inserting Data

When inserting data into the encrypted column, wrap the plaintext in the appropriate EQL payload. These statements must be run through the CipherStash Proxy to **encrypt** the data.

**Example:**

```sql
INSERT INTO users (encrypted_email) VALUES (
  '{"v":1,"k":"pt","p":"test@example.com","i":{"t":"users","c":"encrypted_email"}}'
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
  "v": 1
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
  "v": 1,
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
  'cast_as',          -- PostgreSQL type to cast decrypted data ('text', 'int', etc.)
  'opts'              -- Index options as JSONB (optional)
);
```

You can read more about the index configuration options [here](docs/reference/INDEX.md).

**Example (Unique index):**

```sql
SELECT eql_v2.add_search_config(
  'users',
  'encrypted_email',
  'unique',
  'text'
);
```

After adding an index, you have to activate the configuration:

```sql
SELECT eql_v2.encrypt();
SELECT eql_v2.activate();
```

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
  '{"v":1,"k":"pt","p":"test@example.com","i":{"t":"users","c":"encrypted_email"},"q":"hmac_256"}'
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
  '{"v":1,"k":"pt","p":"test","i":{"t":"users","c":"encrypted_email"},"q":"match"}'
);
```

Equivalent plaintext query:

```sql
SELECT * FROM users WHERE email LIKE '%test%';
```

### Range queries

Enable range queries on encrypted data using the `eql_v2.ore_block_u64_8_256`, `eql_v2.ore_cllw_u64_8`, or `eql_v2.ore_cllw_var_8` functions. Supports:

- `ORDER BY`
- `WHERE`

**Example (Filtering):**

```sql
SELECT * FROM users
WHERE eql_v2.ore_block_u64_8_256(encrypted_date) < eql_v2.ore_block_u64_8_256(
  '{"v":1,"k":"pt","p":"2023-10-05","i":{"t":"users","c":"encrypted_date"},"q":"ore"}'
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

## JSON and JSONB support

EQL supports encrypting entire JSON and JSONB data sets.
This warrants a separate section in the documentation.
You can read more about the JSONB support in the [JSONB reference guide](docs/reference/JSON.md).

## Frequently Asked Questions

### How do I integrate CipherStash EQL with my application?

Use CipherStash Proxy to intercept PostgreSQL queries and handle encryption and decryption automatically.
The proxy interacts with the database using the EQL functions and types defined in this documentation.

Use the [helper packages](#helper-packages) to integate EQL functions into your application.

### Can I use EQL without the CipherStash Proxy?

No, CipherStash Proxy is required to handle the encryption and decryption operations based on the configurations and indexes defined.

### How is data encrypted in the database?

Data is encrypted using CipherStash's cryptographic schemes and stored in the `eql_v2_encrypted` column as a JSONB payload.
Encryption and decryption are handled by CipherStash Proxy.

## Helper packages and examples

We've created a few langauge specific packages to help you interact with the payloads:

| Language   | ORM         | Example                                                          | Package                                       |
| ---------- | ----------- | ---------------------------------------------------------------- | --------------------------------------------- |
| Go         | Xorm        | [Go/Xorm examples](./examples/go/xorm/README.md)                 | [goeql](https://github.com/cipherstash/goeql) |
| TypeScript | Drizzle     | [Drizzle examples](./examples/javascript/apps/drizzle/README.md) | [jseql](https://github.com/cipherstash/jseql) |
| TypeScript | Prisma      | [Drizzle examples](./examples/javascript/apps/prisma/README.md)  | [jseql](https://github.com/cipherstash/jseql) |
| Python     | SQL Alchemy | [Python examples](./examples/python/jupyter_notebook/README.md)  | [eqlpy](https://github.com/cipherstash/eqlpy) |

### Language specific packages

- [Go](https://github.com/cipherstash/goeql)
- [JavaScript/TypeScript](https://github.com/cipherstash/jseql)
- [Python](https://github.com/cipherstash/eqlpy)

## Developing

See the [development guide](./DEVELOPMENT.md).
