# CipherStash Encrypt Query Language (EQL)

[![Why we built EQL](https://img.shields.io/badge/Why%20we%20built%20EQL-8A2BE2)](https://github.com/cipherstash/encrypt-query-language/blob/main/WHYEQL.md)

Encrypt Query Language (EQL) is a set of abstractions for transmitting, storing & interacting with encrypted data and indexes in PostgreSQL.

EQL provides a data format for transmitting and storing encrypted data & indexes, and database types & functions to interact with the encrypted material.

## Table of Contents

- [Getting started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Add a table with encrypted columns](#add-a-table-with-encrypted-columns)
  - [Inserting data](#inserting-data)
  - [Querying data](#querying-data)
  - [Adding an index and enable encryption](#adding-an-index-and-enable-encryption)
  - [Removing an index and disabling encryption](#removing-an-index-and-disabling-encryption)
- [CipherStash Proxy](#cipherstash-proxy)
  - [How EQL works with CipherStash Proxy](#how-eql-works-with-cipherstash-proxy)
    - [Writes](#writes)
    - [Reads](#reads)
- [Encrypt Query Language (EQL)](#encrypt-query-language-eql)
  - [Encrypted columns](#encrypted-columns)
  - [EQL functions](#eql-functions)
  - [Index functions](#index-functions)
  - [Query Functions](#query-functions)
  - [Data Format](#data-format)
    - [Helper packages](#helper-packages)

## Getting started

The following guide assumes you have the prerequisites installed and running, and are running the SQL statements through your CipherStash Proxy instance.

### Prerequisites

- [PostgreSQL 14+](https://www.postgresql.org/download/)
- [Cipherstash Proxy](https://cipherstash.com/docs/getting-started/cipherstash-proxy)
- [Cipherstash Encrypt](https://cipherstash.com/docs/getting-started/cipherstash-encrypt)
  - You can use the empty `cipherstash/dataset.yml` file in the `cipherstash` directory, as EQL does not require a dataset to be configured but it does need to be initialized (we plan to fix this in the future).

EQL relies on [Cipherstash Proxy](https://cipherstash.com/docs/getting-started/cipherstash-proxy) and [Cipherstash Encrypt](https://cipherstash.com/docs/getting-started/cipherstash-encrypt) for low-latency encryption & decryption.
We plan to support direct language integration in the future.

> Note: You will need to copy the `cipherstash/cipherstash-proxy.toml.example` file to `cipherstash/cipherstash-proxy.toml` and update the values to match your environment before running the script.

### Installation

In order to use EQL, you must first install the EQL extension in your PostgreSQL database.
You can do this by running the following command, which will execute the SQL from the `src/install.sql` file:

Update the database credentials based on your environment.

```bash
psql -U postgres -d postgres -f src/install.sql
```

### Add a table with encrypted columns

Create a table with encrypted columns.
For this example, we'll use the `users` table, with a plaintext `email` column and an encrypted `email_encrypted` column.

```sql
CREATE TABLE IF NOT EXISTS "users" (
	"id" serial PRIMARY KEY NOT NULL,
	"email" varchar,
	"email_encrypted" "cs_encrypted_v1"
);
```

In some instances, especially when using langugage specific ORMs, EQL also supports `jsonb` columns rather than the `cs_encrypted_v1` domain type.

### Inserting data

When inserting data into the encrypted column, you must wrap the plaintext in the appropriate EQL payload.
These statements must be run through the CipherStash Proxy in order to **encrypt** the data.

```sql
INSERT INTO users (email_encrypted) VALUES ('{"v":1,"k":"pt","p":"test@test.com","i":{"t":"users","c":"email_encrypted"}}');
```

For reference, the EQL payload is defined as a `jsonb` with a specific schema:

```json
{
  "v": 1,
  "k": "pt",
  "p": "test@test.com",
  "i": {
    "t": "users",
    "c": "email_encrypted"
  }
}
```

### Querying data

When querying data, you must wrap the encrypted column in the appropriate EQL payload.
These statements must be run through the CipherStash Proxy in order to **decrypt** the data.

```sql
SELECT email_encrypted FROM users;
```

For reference, the EQL payload is defined as a `jsonb` with a specific schema:

```json
{
  "v": 1,
  "k": "ct",
  "c": "test@test.com",
  "i": {
    "t": "users",
    "c": "email_encrypted"
  }
}
```

### Adding an index and enable encryption

To add an index to the encrypted column, you must run the `cs_add_index_v1` function.
This function takes the following parameters:

- `table_name`: The name of the table containing the encrypted column.
- `column_name`: The name of the encrypted column.
- `index_name`: The name of the index.
- `cast_as`: The type of the index (text, int, small_int, big_int, real, double, boolean, date, jsonb).
- `opts`: An optional JSON object containing additional index options.

For the example above, and using a match index, the following statement would be used:

```sql
SELECT cs_add_index_v1('users', 'email_encrypted', 'match', 'text', '{"token_filters": [{"kind": "downcase"}], "tokenizer": { "kind": "ngram", "token_length": 3 }}');
```

Once you have added an index, you must enable encryption.
This will update the encryption configuration to include the new index.

```sql
SELECT cs_encrypt_v1();
SELECT cs_activate_v1();
```

In this example `cs_encrypt_v1` and `cs_activate_v1` are called to immediately set the new Encrypt config to **active** for demonstration purposes.
In a production environment, you will need to consider a migration strategy to ensure the encryption config is updated based on the current state of the database.

See the [reference guide on migrations](https://cipherstash.com/docs/getting-started/cipherstash-encrypt#migrations) for more information.

### Removing an index and disabling encryption

To remove an index from the encrypted column, you must run the `cs_remove_index_v1` function.
This function takes the following parameters:

- `table_name`: The name of the table containing the encrypted column.
- `column_name`: The name of the encrypted column.
- `index_name`: The name of the index.

For the example above, and using a match index, the following statement would be used:

```sql
SELECT cs_remove_index_v1('users', 'email_encrypted', 'match');
```

Once you have removed an index, you must disable encryption.
This will update the encryption configuration to exclude the removed index.

```sql
SELECT cs_encrypt_v1();
```

---

## CipherStash Proxy

Read more about CipherStash Proxy in the [WHYEQL.md](https://github.com/cipherstash/encrypt-query-language/blob/main/WHYEQL.md#cipherstash-proxy) file.

### How EQL works with CipherStash Proxy

EQL uses **CipherStash Proxy** to mediate access to your PostgreSQL database and provide low-latency encryption & decryption.

At a high level:

- encrypted data is stored as `jsonb`
- references to the column in sql statements are wrapped in a helper function
- Cipherstash Proxy transparently encrypts and indexes data

#### Writes

1. Database client sends `plaintext` data encoded as `jsonb`
1. CipherStash Proxy encrypts the `plaintext` and encodes the `ciphertext` value and associated indexes into the `jsonb` payload
1. The data is written to the encrypted column

![Insert](/diagrams/overview-insert.drawio.svg)

#### Reads

1. Wrap references to the encrypted column in the appropriate EQL function
1. CipherStash Proxy encrypts the `plaintext`
1. PostgreSQL executes the SQL statement
1. CipherStash Proxy decrypts any returned `ciphertext` data and returns to client

![Select](/diagrams/overview-select.drawio.svg)

---

## Encrypt Query Language (EQL)

Before you get started, it's important to understand some of the key components of EQL.

### Encrypted columns

Encrypted columns are defined using the `cs_encrypted_v1` [domain type](https://www.postgresql.org/docs/current/domains.html), which extends the `jsonb` type with additional constraints to ensure data integrity.

**Example table definition:**

```sql
CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email_encrypted cs_encrypted_v1
);
```

### EQL functions

EQL provides specialized functions to interact with encrypted data:

- **`cs_ciphertext_v1(val JSONB)`**: Extracts the ciphertext for decryption by CipherStash Proxy.
- **`cs_match_v1(val JSONB)`**: Enables basic full-text search.
- **`cs_unique_v1(val JSONB)`**: Retrieves the unique index for enforcing uniqueness.
- **`cs_ore_v1(val JSONB)`**: Retrieves the Order-Revealing Encryption index for range queries.

### Index functions

These Functions expect a `jsonb` value that conforms to the storage schema.

#### cs_add_index

```sql
cs_add_index(table_name text, column_name text, index_name text, cast_as text, opts jsonb)
```

| Parameter     | Description                                        | Notes
| ------------- | -------------------------------------------------- | ------------------------------------
| table_name    | Name of target table                               | Required
| column_name   | Name of target column                              | Required
| index_name    | The index kind                                     | Required.
| cast_as       | The PostgreSQL type decrypted data will be cast to | Optional. Defaults to `text`
| opts          | Index options                                      | Optional for `match` indexes (see below)

##### cast_as

Supported types:
  - text
  - int
  - small_int
  - big_int
  - boolean
  - date

##### match opts

A match index enables full text search across one or more text fields in queries.

The default Match index options are:

```json
  {
    "k": 6,
    "m": 2048,
    "include_original": true,
    "tokenizer": {
      "kind": "ngram",
      "token_length": 3
    }
    "token_filters": {
      "kind": "downcase"
    }
  }
```

#### cs_modify_index

```sql
_cs_modify_index_v1(table_name text, column_name text, index_name text, cast_as text, opts jsonb)
```

Modifies an existing index configuration.
Accepts the same parameters as `cs_add_index`

#### cs_remove_index

```sql
cs_remove_index_v1(table_name text, column_name text, index_name text)
```

Removes an index configuration from the column.

### Query Functions

These Functions expect a `jsonb` value that conforms to the storage schema, and are used to perform search operations.

#### cs_ciphertext_v1

```sql
cs_ciphertext_v1(val jsonb)
```

Extracts the ciphertext from the `jsonb` value.
Ciphertext values are transparently decrypted in transit by Cipherstash Proxy.

#### cs_match_v1

```sql
cs_match_v1(val jsonb)
```

Extracts a match index from the `jsonb` value.
Returns `null` if no match index is present.

#### cs_unique_v1

```sql
cs_unique_v1(val jsonb)
```

Extracts a unique index from the `jsonb` value.
Returns `null` if no unique index is present.

#### cs_ore_v1

```sql
cs_ore_v1(val jsonb)
```

Extracts an ore index from the `jsonb` value.
Returns `null` if no ore index is present.

### Data Format

Encrypted data is stored as `jsonb` with a specific schema:

- **Plaintext Payload (Client Side):**

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

- **Encrypted Payload (Database Side):**

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

The format is defined as a [JSON Schema](src/cs_encrypted_v1.schema.json).

It should never be necessary to directly interact with the stored `jsonb`.
Cipherstash proxy handles the encoding, and EQL provides the functions.

| Field    | Name               | Description
| -------- | ------------------ | ------------------------------------------------------------
| s        | Schema version     | JSON Schema version of this json document.
| v        | Version            | The configuration version that generated this stored value.
| k        | Kind               | The kind of the data (plaintext/pt, ciphertext/ct, encrypting/et).
| i.t      | Table identifier   | Name of the table containing encrypted column.
| i.c      | Column identifier  | Name of the encrypted column.
| p        | Plaintext          | Plaintext value sent by database client. Required if kind is plaintext/pt or encrypting/et.
| c        | Ciphertext         | Ciphertext value. Encrypted by proxy. Required if kind is plaintext/pt or encrypting/et.
| m.1      | Match index        | Ciphertext index value. Encrypted by proxy.
| o.1      | ORE index          | Ciphertext index value. Encrypted by proxy.
| u.1      | Uniqueindex        | Ciphertext index value. Encrypted by proxy.

#### Helper packages

We have created a few langague specific packages to help you interact with the payloads:

- [@cipherstash/eql](https://github.com/cipherstash/encrypt-query-language/tree/main/javascript/packages/eql): This is a TypeScript implementation of EQL.
