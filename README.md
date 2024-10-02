# CipherStash Encrypt Query Language (EQL)

Encrypt Query Language (EQL) is a set of abstractions for transmitting, storing & interacting with encrypted data and indexes in PostgreSQL.

EQL provides a data format for transmitting and storing encrypted data & indexes, and database types & functions to interact with the encrypted material.

## 1. Encryption in use

EQL enables encryption in use, without significant changes to your application code.
A variety of searchable encryption techniques are available, including:

- Matching (`a == b` or `a LIKE b`)
- Comparison using order revealing encryption (`a < b`)
- Enforcing unique constraints (`there is only a`)

### 1.1 What is encryption in use?

Encryption in use is the practice of keeping data encrypted even while it's being processed or queried in the database. 
Unlike traditional encryption methods that secure data only at rest (on disk) or in transit (over the network), encryption in use keeps the data encrypted while operations are being performed on the data.
This provides an additional layer of security against unauthorized access — an adversary needs access to the encrypted data _and_ encryption keys. 

### 1.2 Why use encryption in use?

While encryption at rest and in transit are essential, they don't protect data when the database server itself is compromised. 
Encryption in use mitigates this risk by ensuring that:

- **Data remains secure**: Even if the database server is breached, the data remains encrypted and unreadable without the proper keys.
- **Compliance controls are stronger**: When you need stronger data security controls than what SOC2/SOC3 or ISO27001 mandate, encryption in use helps you meet those stringent requirements.

## 2. CipherStash Proxy

### 2.1 Overview

CipherStash Proxy is a transparent proxy that sits between your application and your PostgreSQL database.
It intercepts SQL queries and handles the encryption and decryption of data on-the-fly.
This enables encryption in use without significant changes to your application code.

### 2.2 How it works

- **Intercepts queries**: CipherStash Proxy captures SQL statements from the client application.
- **Encrypts data**: For write operations, it encrypts the plaintext data before sending it to the database.
- **Decrypts data**: For read operations, it decrypts the encrypted data retrieved from the database before returning it to the client.
- **Maintains searchability**: Ensures that the encrypted data is searchable and retrievable without sacrificing performance or application functionality.
- **Manages encryption keys**: Securely handles encryption keys required for encrypting and decrypting data.

### 2.3 How EQL works with CipherStash Proxy

EQL uses **CipherStash Proxy** to mediate access to your PostgreSQL database and provide low-latency encryption & decryption.

At a high level:

- encrypted data is stored as `jsonb`
- references to the column in sql statements are wrapped in a helper function
- Cipherstash Proxy transparently encrypts and indexes data

#### 2.3.1 Writes

1. Database client sends `plaintext` data encoded as `jsonb`
2. CipherStash Proxy encrypts the `plaintext` and encodes the `ciphertext` value and associated indexes into the `jsonb` payload
3. The data is written to the encrypted column

![Insert](/diagrams/overview-insert.drawio.svg)

#### 2.3.2 Reads

1. Wrap references to the encrypted column in the appropriate EQL function
3. CipherStash Proxy encrypts the `plaintext`
4. PostgreSQL executes the SQL statement
5. CipherStash Proxy decrypts any returned `ciphertext` data and returns to client

![Select](/diagrams/overview-select.drawio.svg)

## 3. Encrypt Query Language (EQL)

Before you get started, it's important to understand some of the key components of EQL.

### 3.1 Encrypted columns

Encrypted columns are defined using the `cs_encrypted_v1` domain type, which extends the `jsonb` type with additional constraints to ensure data integrity.

**Example table definition:**

```sql
CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name_encrypted cs_encrypted_v1
);
```

### 3.2 EQL functions

EQL provides specialized functions to interact with encrypted data:

- **`cs_ciphertext_v1(val JSONB)`**: Extracts the ciphertext for decryption by CipherStash Proxy.
- **`cs_match_v1(val JSONB)`**: Retrieves the match index for equality comparisons.
- **`cs_unique_v1(val JSONB)`**: Retrieves the unique index for enforcing uniqueness.
- **`cs_ore_v1(val JSONB)`**: Retrieves the Order-Revealing Encryption index for range queries.

#### 3.2.1 Index functions

These Functions expect a `jsonb` value that conforms to the storage schema.

##### 3.2.1.1 cs_add_index

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


###### cast_as

Supported types:
  - text
  - int
  - small_int
  - big_int
  - boolean
  - date


###### match opts

Default Match index options:

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

##### 3.2.1.2 cs_modify_index

```sql
cs_modify_index(table_name text, column_name text, index_name text, cast_as text, opts jsonb)
```

Modifies an existing index configuration.
Accepts the same parameters as `cs_add_index`

##### 3.2.1.3 cs_remove_index

```sql
cs_remove_index(table_name text, column_name text, index_name text)
```

Removes an index configuration from the column.

### 3.3 Query Functions

These Functions expect a `jsonb` value that conforms to the storage schema, and are used to perform search operations.

#### 3.3.1 cs_ciphertext_v1

```sql
cs_ciphertext_v1(val jsonb)
```

Extracts the ciphertext from the `jsonb` value.
Ciphertext values are transparently decrypted in transit by Cipherstash Proxy.

#### 3.3.2 cs_match_v1

```sql
cs_match_v1(val jsonb)
```

Extracts a match index from the `jsonb` value.
Returns `null` if no match index is present.

#### 3.3.3 cs_unique_v1

```sql
cs_unique_v1(val jsonb)
```

Extracts a unique index from the `jsonb` value.
Returns `null` if no unique index is present.

#### 3.3.4 cs_ore_v1

```sql
cs_ore_v1(val jsonb)
```

Extracts an ore index from the `jsonb` value.
Returns `null` if no ore index is present.

### 3.4 Data Format

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

#### 3.4.1 Helper packages

We have created a few langague specific packages to help you interact with the payloads:

- [@cipherstash/eql](https://github.com/cipherstash/encrypt-query-language/tree/main/javascript/packages/eql): This is a TypeScript implementation of EQL.

## 4. Getting started

### 4.1 Prerequisites

- [PostgreSQL 14+](https://www.postgresql.org/download/)
- [Cipherstash Proxy](https://cipherstash.com/docs/getting-started/cipherstash-proxy)
- [Cipherstash Encrypt](https://cipherstash.com/docs/getting-started/cipherstash-encrypt)

EQL relies on [Cipherstash Proxy](https://cipherstash.com/docs/getting-started/cipherstash-proxy) and [Cipherstash Encrypt](https://cipherstash.com/docs/getting-started/cipherstash-encrypt) for low-latency encryption & decryption.
We plan to support direct language integration in the future.

> Note: An example `dataset.yml` file is provided in the `cipherstash` directory for Encrypt configuration, along with a `start.sh` script to run Cipherstash Proxy locally.
You will need to modify the `dataset.yml` file to match your environment, and copy the `cipherstash/cipherstash-proxy.toml.example` file to `cipherstash/cipherstash-proxy.toml` before running the script.

### 4.2 Installation

In order to use EQL, you must first install the EQL extension in your PostgreSQL database.
You can do this by running the following command, which will execute the SQL from the `src/install.sql` file:

Update the database credentials based on your environment.

```bash
psql -U postgres -d postgres -f src/install.sql
```

### 4.3 Add a table with encrypted columns

Create a table with encrypted columns.
For this example, we'll use the `users` table, with a plaintext `email` column and an encrypted `email_encrypted` column.

```sql
CREATE TABLE IF NOT EXISTS "users" (
	"id" serial PRIMARY KEY NOT NULL,
	"email" varchar,
	"email_encrypted" "cs_encrypted_v1"
);
```

### 4.4 Add an index for searchability

EQL supports three types of indexes:

- match
- ore (order revealing encryption)
- unique

Indexes are managed using EQL functions and can be baked into an existing database migration process.

```sql
-- Add an ore index to users.name
cs_add_index('users', 'name', 'ore');

-- Remove an ore index from users.name
cs_remove_index('users', 'name', 'ore');
```

Adding the index to your configuration does not *encrypt* the data.

The encryption process needs to update every row in the target table.
Depending on the size of the target table, this process can be long-running.

{{LINK TO MIGRATOR DETAILS HERE}}

### Add an encrypted column

TODO: Do we need this? 

```SQL
-- Alter tables from the configuration
cs_create_encrypted_columns_v1()

-- Explicit alter table
ALTER TABLE users ADD column name_encrypted cs_encrypted_v1;
```

.... more to come