# CipherStash Encrypt Query Language (EQL)


Encrypt Query Language (EQL) is a set of abstractions for transmitting, storing & interacting with encrypted data and indexes in PostgreSQL.

EQL provides:

- a data format for transmitting and storing encrypted data & indexes
- database types & functions to interact with the encrypted material

EQL relies on [Cipherstash Encrypt](https://cipherstash.com/docs/getting-started/cipherstash-encrypt) and [Cipherstash Proxy](https://cipherstash.com/docs/getting-started/cipherstash-proxy) for low-latency encryption & decryption.

As well as basic encryption of data, Cipherstash Proxy supports a variety of encrypted indexes that enable:

- matching (`a == b` or `a LIKE b`)
- comparison using order revealing encryption (`a < b`)
- enforcing unique constraints (`there is only a`)


Example SQL statements using EQL:
```SQL
-- select using an encrypted match comparison
SELECT cs_ciphertext_v1(name)
FROM users
WHERE cs_match_v1(name) @> $2;

-- insert using jsonb payload
INSERT INTO users (name) VALUES ({"p": "plaintext"});
```



## How EQL works with CipherStash Proxy

EQL uses **CipherStash Proxy** to mediate access to your PostgreSQL database and provide low-latency encryption & decryption.

At a high level:

- encrypted data is stored as `jsonb`
- references to the column in sql statements are wrapped in a helper function
- Cipherstash Proxy transparently encrypts and indexes data



### Writes

1. Database client sends `plaintext` data encoded as `jsonb`
2. CipherStash Proxy encrypts the `plaintext` and encodes the `ciphertext` value and associated indexes into the `jsonb` payload
3. The data is written to the encrypted column


![Insert](/diagrams/overview-insert.drawio.svg)



### Reads

1. Wrap references to the encrypted column in the appropriate EQL function
3. CipherStash Proxy encrypts the `plaintext`
4. PostgreSQL executes the SQL statement
5. CipherStash Proxy decrypts any returned `ciphertext` data and returns to client


![Select](/diagrams/overview-select.drawio.svg)


## Getting started


1. Setup
    1. Configure & run [Cipherstash Proxy](https://cipherstash.com/docs/getting-started/cipherstash-proxy)
    2. Install EQL
2. Add an index
3. Add an encrypted column
6. Run Cipherstash Proxy


### Add an index

Cipherstash Proxy supports three types of indexes:

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


```SQL
-- Alter tables from the configuration
cs_create_encrypted_columns_v1()

-- Explicit alter table
ALTER TABLE users ADD column name_encrypted cs_encrypted_v1;
```



## Components

### Encrypted columns

An encrypted column should be defined as the `cs_encrypted_v1` [Domain Type](https://www.postgresql.org/docs/current/domains.html).

The `cs_encrypted_v1` type is based on the PostgreSQL `jsonb` type and adds a check constraint to verify the schema (see below for details).

Example table definition:
```SQL
CREATE TABLE users
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    name_encrypted cs_encrypted_v1,
    PRIMARY KEY(id)
);
```



### Index Functions

Functions expect a `jsonb` value that conforms to the storage schema.


```SQL
cs_add_index(table_name text, column_name text, index_name text, cast_as text, opts jsonb)
```
| Parameter     | Description                                        | Notes
| ------------- | -------------------------------------------------- | ------------------------------------
| table_name    | Name of target table                               | Required
| column_name   | Name of target column                              | Required
| index_name    | The index kind                                     | Required.
| cast_as       | The PostgreSQL type decrypted data will be cast to | Optional. Defaults to `text`
| opts          | Index options                                      | Optional for `match` indexes (see below)


#### cast_as

Supported types:
  - text
  - int
  - small_int
  - big_int
  - boolean
  - date

#### match opts






```SQL
cs_modify_index(table_name text, column_name text, index_name text, cast_as text, opts jsonb)
```
Modifies an existing index configuration.
Accepts the same parameters as `cs_add_index`


```SQL
cs_remove_index(table_name text, column_name text, index_name text)
```
Removes an index configuration from the column.




### Query Functions

Functions expect a `jsonb` value that conforms to the storage schema.


```SQL
cs_ciphertext_v1(val jsonb)
```
Extracts the ciphertext from the `jsonb` value.
Ciphertext values are transparently decrypted in transit by Cipherstash Proxy.


```SQL
cs_match_v1(val jsonb)
```
Extracts a match index from the `jsonb` value.
Returns `null` if no match index is present.


```SQL
cs_unique_v1(val jsonb)
```
Extracts a unique index from the `jsonb` value.
Returns `null` if no unique index is present.


```SQL
cs_ore_v1(val jsonb)
```
Extracts an ore index from the `jsonb` value.
Returns `null` if no ore index is present.



### Data format

Encrypted columns should be defined as the `cs_encrypted_v1` Domain Type and encrypted data and index values are stored as `jsonb`.

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


```json
// Plaintext
// Sent by client
{
  "v": 1,
  "k": "pt",
  "p": "plaintext name",
  "i": {
    "t": "users",
    "c": "name_encrypted"
  }
}

// Ciphertext
// Encoded for storage by proxy
{
  "v": 1,
  "k": "ct",
  "c": "XvfWQUrSxKNhkOxiMXvgvkwxIYFfnYTb",
  "i": {
    "t": "users",
    "c": "name_encrypted"
  }
}

// Encryptindexing
// Includes both plaintext and ciphertext
// So original column is kept in sync during initial encryption & migration
{
  "v": 1,
  "k": "et",
  "p": "plaintext name",
  "c": "XvfWQUrSxKNhkOxiMXvgvkwxIYFfnYTb",
  "i": {
    "t": "users",
    "c": "name_encrypted"
  }
}
```


