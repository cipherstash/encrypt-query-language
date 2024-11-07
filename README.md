# Encrypt Query Language (EQL)

[![Why we built EQL](https://img.shields.io/badge/concept-Why%20EQL-8A2BE2)](https://github.com/cipherstash/encrypt-query-language/blob/main/docs/concepts/WHY.md)
[![Getting started](https://img.shields.io/badge/guide-Getting%20started-008000)](https://github.com/cipherstash/encrypt-query-language/blob/main/docs/tutorials/GETTINGSTARTED.md)
[![CipherStash Proxy](https://img.shields.io/badge/guide-CipherStash%20Proxy-A48CF3)](https://github.com/cipherstash/encrypt-query-language/blob/main/docs/tutorials/PROXY.md)
[![CipherStash Migrator](https://img.shields.io/badge/guide-CipherStash%20Migrator-A48CF3)](https://github.com/cipherstash/encrypt-query-language/blob/main/docs/reference/MIGRATOR.md)

Encrypt Query Language (EQL) is a set of abstractions for transmitting, storing, and interacting with encrypted data and indexes in PostgreSQL.

Store encrypted data alongside your existing data.

- Encrypted data is stored using a `jsonb` column type
- Query encrypted data with specialized SQL functions
- Index encrypted columns to enable searchable encryption
- Integrate with [CipherStash Proxy](https://github.com/cipherstash/encrypt-query-language/blob/main/docs/tutorials/PROXY.md) for transparent encryption/decryption

## Table of Contents

- [Installation](#installation)
  - [CipherStash Proxy](#cipherstash-proxy)
- [Getting started](#getting-started)
  - [Enable encrypted columns](#enable-encrypted-columns)
  - [Configuring the column](#configuring-the-column)
  - [Activating configuration](#activating-configuration)
    - [Refreshing CipherStash Proxy Configuration](#refreshing-cipherstash-proxy-configuration)
- [Storing data](#storing-data)
  - [Inserting Data](#inserting-data)
  - [Reading Data](#reading-data)
- [Configuring indexes for searching data](#configuring-indexes-for-searching-data)
  - [Adding an index (`cs_add_index_v1`)](#adding-an-index-cs_add_index_v1)
- [Searching data with EQL](#searching-data-with-eql)
  - [Equality search (`cs_unique_v1`)](#equality-search-cs_unique_v1)
  - [Full-text search (`cs_match_v1`)](#full-text-search-cs_match_v1)
  - [Range queries (`cs_ore_64_8_v1`)](#range-queries-cs_ore_64_8_v1)
- [JSON and JSONB support](#json-and-jsonb-support)
  - [Configuring the index](#configuring-the-index)
  - [Inserting JSON data](#inserting-json-data)
  - [Reading JSON data](#reading-json-data)
  - [Advanced JSON queries](#advanced-json-queries)
- [EQL payload data format](#eql-payload-data-format)
- [Frequently Asked Questions](#frequently-asked-questions)
  - [How do I integrate CipherStash EQL with my application?](#how-do-i-integrate-cipherstash-eql-with-my-application)
  - [Can I use EQL without the CipherStash Proxy?](#can-i-use-eql-without-the-cipherstash-proxy)
  - [How is data encrypted in the database?](#how-is-data-encrypted-in-the-database)
- [Helper packages](#helper-packages)
- [Releasing](#releasing)

---

## Installation

The simplest way to get up and running with EQL is to execute the install SQL file directly in your database.

1. Download the latest EQL install script:

   ```sh
   curl -sLo cipherstash-encrypt.sql https://github.com/cipherstash/encrypt-query-language/releases/latest/download/cipherstash-encrypt.sql
   ```

2. Run this command to install the custom types and functions:

   ```sh
   psql -f cipherstash-encrypt.sql
   ```

### CipherStash Proxy

EQL relies on [CipherStash Proxy](https://github.com/cipherstash/encrypt-query-language/blob/main/PROXY.md) for low-latency encryption & decryption.
We plan to support direct language integration in the future.

## Getting started

Once the custom types and functions are installed, you can start using EQL in your queries.

### Enable encrypted columns

Define encrypted columns using the `cs_encrypted_v1` domain type, which extends the `jsonb` type with additional constraints to ensure data integrity.

**Example:**

```sql
CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    encrypted_email cs_encrypted_v1
);
```

### Configuring the column

Initialize the column using the `cs_add_column_v1` function to enable encryption and decryption via CipherStash Proxy.

```sql
SELECT cs_add_column_v1('users', 'encrypted_email');
```

**Note:** This function allows you to encrypt and decrypt data but does not enable searchable encryption. See [Querying Data with EQL](#querying-data-with-eql) for enabling searchable encryption.

### Activating configuration

After modifying configurations, activate them by running:

```sql
SELECT cs_encrypt_v1();
SELECT cs_activate_v1();
```

**Important:** These functions must be run after any modifications to the configuration.

#### Refreshing CipherStash Proxy Configuration

CipherStash Proxy refreshes the configuration every 60 seconds. To force an immediate refresh, run:

```sql
SELECT cs_refresh_encrypt_config();
```

>Note: This statement must be executed when connected to CipherStash Proxy.
When connected to the database directly, it is a no-op.

## Storing data

Encrypted data is stored as `jsonb` values in the database, regardless of the original data type.

You can read more about the data format [here][#data-format].

### Inserting Data

When inserting data into the encrypted column, wrap the plaintext in the appropriate EQL payload. These statements must be run through the CipherStash Proxy to **encrypt** the data.

**Example:**

```sql
INSERT INTO users (encrypted_email) VALUES (
  '{"v":1,"k":"pt","p":"test@example.com","i":{"t":"users","c":"encrypted_email"}}'
);
```

Data is stored in the database as:

```json
{
  "c": "generated_ciphertext",
  "i": {
    "c": "encrypted_email",
    "t": "users"
  },
  "k": "ct",
  "m": null,
  "o": null,
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

>Note: If you execute this query directly on the database, you will not see any plaintext data but rather the `jsonb` payload with the ciphertext.

## Configuring indexes for searching data

In order to perform searchable operations on encrypted data, you must configure indexes for the encrypted columns.

> **IMPORTANT:** If you have existing data that's encrypted and you add or modify an index, all the data will need to be re-encrypted.
This is due to the way CipherStash Proxy handles searchable encryption operations.

### Adding an index (`cs_add_index_v1`)

Add an index to an encrypted column.
This function also behaves the same as `cs_add_column_v1` but with the additional index configuration.

```sql
SELECT cs_add_index_v1(
  'table_name',       -- Name of the table
  'column_name',      -- Name of the column
  'index_name',       -- Index kind ('unique', 'match', 'ore', 'ste_vec')
  'cast_as',          -- PostgreSQL type to cast decrypted data ('text', 'int', etc.)
  'opts'              -- Index options as JSONB (optional)
);
```

You can read more about the index configuration options [here][https://github.com/cipherstash/encrypt-query-language/blob/main/docs/reference/INDEX.md].

**Example (Unique index):**

```sql
SELECT cs_add_index_v1(
  'users', 
  'encrypted_email', 
  'unique', 
  'text'
);
```

After adding an index, you have to activate the configuration.

```sql
SELECT cs_encrypt_v1();
SELECT cs_activate_v1();
```

## Searching data with EQL

EQL provides specialized functions to interact with encrypted data, supporting operations like equality checks, range queries, and unique constraints.

In order to use the specialized functions, you must first configure the corresponding indexes.

### Equality search (`cs_unique_v1`)

Enable equality search on encrypted data.

**Index configuration example:**

```sql
SELECT cs_add_index_v1(
  'users', 
  'encrypted_email', 
  'unique', 
  'text'
);
```

**Example:**

```sql
SELECT * FROM users
WHERE cs_unique_v1(encrypted_email) = cs_unique_v1(
  '{"v":1,"k":"pt","p":"test@example.com","i":{"t":"users","c":"encrypted_email"},"q":"unique"}'
);
```

Equivalent plaintext query:

```sql
SELECT * FROM users WHERE email = 'test@example.com';
```

### Full-text search (`cs_match_v1`)

Enables basic full-text search on encrypted data.

**Index configuration example:**

```sql
SELECT cs_add_index_v1(
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
WHERE cs_match_v1(encrypted_email) @> cs_match_v1(
  '{"v":1,"k":"pt","p":"test","i":{"t":"users","c":"encrypted_email"},"q":"match"}'
);
```

Equivalent plaintext query:

```sql
SELECT * FROM users WHERE email LIKE '%test%';
```

### Range queries (`cs_ore_64_8_v1`)

Enable range queries on encrypted data. Supports:

- `ORDER BY`
- `WHERE`

**Example (Filtering):**

```sql
SELECT * FROM users
WHERE cs_ore_64_8_v1(encrypted_date) < cs_ore_64_8_v1(
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
ORDER BY cs_ore_64_8_v1(encrypted_field) DESC;
```

Equivalent plaintext query:

```sql
SELECT id FROM users ORDER BY field DESC;
```

**Example (Grouping):**

```sql
SELECT cs_grouped_value_v1(encrypted_field) COUNT(*)
  FROM users
  GROUP BY cs_ore_64_8_v1(encrypted_field)
```

Equivalent plaintext query:

```sql
SELECT field, COUNT(*) FROM users GROUP BY field;
```

## JSON and JSONB support

EQL supports encrypting, decrypting, and searching JSON and JSONB objects.

### Configuring the index

Similar to how you configure indexes for text data, you can configure indexes for JSON and JSONB data.
The only difference is that you need to specify the `cast_as` parameter as `json` or `jsonb`.

```sql
SELECT cs_add_index_v1(
  'users', 
  'encrypted_json', 
  'ste_vec',
  'jsonb',
  '{"prefix": "users/encrypted_json"}' -- The prefix is in the form of "table/column"
);
```

You can read more about the index configuration options [here](https://github.com/cipherstash/encrypt-query-language/blob/main/docs/reference/INDEX.md).

### Inserting JSON data

When inserting JSON data, this works the same as inserting text data. 
You need to wrap the JSON data in the appropriate EQL payload.
CipherStash Proxy will **encrypt** the data automatically.

**Example:**

Assuming you want to store the following JSON data:

```json
{
  "name": "John Doe",
  "metadata": {
    "age": 42,
  }
}
```

The EQL payload would be:

```sql
INSERT INTO users (encrypted_json) VALUES (
  '{"v":1,"k":"pt","p":"{\"name\":\"John Doe\",\"metadata\":{\"age\":42}}","i":{"t":"users","c":"encrypted_json"}}'
);
```

Data is stored in the database as:

```json
{
  "i": {
    "c": "encrypted_json",
    "t": "users"
  },
  "k": "sv",
  "v": 1,
  "sv": [
    ...ciphertext...
  ]
}
```

### Reading JSON data

When querying data, select the encrypted column. CipherStash Proxy will **decrypt** the data automatically.

**Example:**

```sql
SELECT encrypted_json FROM users;
```

Data is returned as:

```json
{
  "k": "pt",
  "p": "{\"metadata\":{\"age\":42},\"name\":\"John Doe\"}",
  "i": {
    "t": "users",
    "c": "encrypted_json"
  },
  "v": 1,
  "q": null
}
```

### Advanced JSON queries

We support a wide range of JSON/JSONB functions and operators.
You can read more about the JSONB support in the [JSONB reference guide](https://github.com/cipherstash/encrypt-query-language/blob/main/docs/reference/JSON.md).

## EQL payload data format

Encrypted data is stored as `jsonb` with a specific schema:

- **Plaintext payload (client side):**

  ```json
  {
    "v": 1,
    "k": "pt",
    "p": "plaintext value",
    "e": {
      "t": "table_name",
      "c": "column_name"
    }
  }
  ```

- **Encrypted payload (database side):**

  ```json
  {
    "v": 1,
    "k": "ct",
    "c": "ciphertext value",
    "e": {
      "t": "table_name",
      "c": "column_name"
    }
  }
  ```

The format is defined as a [JSON Schema](./cs_encrypted_v1.schema.json).

It should never be necessary to directly interact with the stored `jsonb`.
CipherStash Proxy handles the encoding, and EQL provides the functions.

| Field | Name              | Description                                                                                                                                                                                                                                       |
| ----- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| s     | Schema version    | JSON Schema version of this json document.                                                                                                                                                                                                        |
| v     | Version           | The configuration version that generated this stored value.                                                                                                                                                                                       |
| k     | Kind              | The kind of the data (plaintext/pt, ciphertext/ct, encrypting/et).                                                                                                                                                                                |
| i.t   | Table identifier  | Name of the table containing encrypted column.                                                                                                                                                                                                    |
| i.c   | Column identifier | Name of the encrypted column.                                                                                                                                                                                                                     |
| p     | Plaintext         | Plaintext value sent by database client. Required if kind is plaintext/pt or encrypting/et.                                                                                                                                                       |
| q     | For query         | Specifies that the plaintext should be encrypted for a specific query operation. If `null`, source encryption and encryption for all indexes will be performed. Valid values are `"match"`, `"ore"`, `"unique"`, `"ste_vec"`, and `"ejson_path"`. |
| c     | Ciphertext        | Ciphertext value. Encrypted by Proxy. Required if kind is plaintext/pt or encrypting/et.                                                                                                                                                          |
| m     | Match index       | Ciphertext index value. Encrypted by Proxy.                                                                                                                                                                                                       |
| o     | ORE index         | Ciphertext index value. Encrypted by Proxy.                                                                                                                                                                                                       |
| u     | Unique index      | Ciphertext index value. Encrypted by Proxy.                                                                                                                                                                                                       |
| sv    | STE vector index  | Ciphertext index value. Encrypted by Proxy.                                                                                                                                                                                                       |

## Frequently Asked Questions

### How do I integrate CipherStash EQL with my application?

Use CipherStash Proxy to intercept database queries and handle encryption and decryption automatically. 
The proxy interacts with the database using the EQL functions and types defined in this documentation.

Use the [helper packages](#helper-packages) to integate EQL functions into your application.

### Can I use EQL without the CipherStash Proxy?

No, CipherStash Proxy is required to handle the encryption and decryption operations based on the configurations and indexes defined.

### How is data encrypted in the database?

Data is encrypted using CipherStash's cryptographic schemes and stored in the `cs_encrypted_v1` column as a JSONB payload.
Encryption and decryption are handled by CipherStash Proxy.

## Helper packages

We've created a few langague specific packages to help you interact with the payloads:

- **JavaScript/TypeScript**: [@cipherstash/eql](https://github.com/cipherstash/encrypt-query-language/tree/main/languages/javascript/packages/eql)
- **Go**: [github.com/cipherstash/goeql](https://github.com/cipherstash/goeql)

## Releasing

To cut a [release](https://github.com/cipherstash/encrypt-query-language/releases) of EQL:

1. Draft a [new release](https://github.com/cipherstash/encrypt-query-language/releases/new) on GitHub.
1. Choose a tag, and create a new one with the prefix `eql-` followed by a [semver](https://semver.org/) (for example, `eql-1.2.3`).
1. Generate the release notes.
1. Optionally set the release to be the latest (you can set a release to be latest later on if you are testing out a release first).
1. Click `Publish release`.

This will trigger the [Release EQL](https://github.com/cipherstash/encrypt-query-language/actions/workflows/release-eql.yml) workflow, which will build and attach artifacts to [the release](https://github.com/cipherstash/encrypt-query-language/releases/).
