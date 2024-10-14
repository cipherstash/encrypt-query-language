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

EQL provides specialized functions to interact with encrypted data.
These Functions expect an encrypted domain type (which is effectively just JSONB).

- **`cs_ciphertext_v1(val JSONB)`**: Extracts the ciphertext for decryption by CipherStash Proxy.
- **`cs_match_v1(val JSONB)`**: Enables basic full-text search.
- **`cs_unique_v1(val JSONB)`**: Retrieves the unique index for enforcing uniqueness.
- **`cs_ore_v1(val JSONB)`**: Retrieves the Order-Revealing Encryption index for range queries.


#### `cs_ste_vec_v1(val JSONB)`

Retrieves the Structured Encryption Vector for containment queries.

**Example:**

```rb
# Serialize a JSONB value bound to the users table column
term = User::ENCRYPTED_JSONB.serialize({field: "value"})
User.where("cs_ste_vec_v1(attrs) @> cs_ste_vec_v1(?)", term)
```

Which will execute on the server as:

```sql
SELECT * FROM users WHERE cs_ste_vec_v1(attrs) @> '53T8dtvW4HhofDp9BJnUkw';
```

And is the EQL equivalent of the following plaintext query.

```sql
SELECT * FROM users WHERE attrs @> '{"field": "value"}`;
```

#### `cs_ste_term_v1(val JSONB, epath TEXT)`

Retrieves the encrypted index term associated with the encrypted JSON path, `epath`.

This is useful for sorting or filtering on integers in encrypted JSON objects.

**Example:**

```rb
# Serialize a JSONB value bound to the users table column
path = EJSON_PATH.serialize("$.login_count")
term = User::ENCRYPTED_INT.serialize(100)
User.where("cs_ste_term_v1(attrs, ?) > cs_ore_64_8_v1(?)", path, term)
```

Which will execute on the server as:

```sql
SELECT * FROM users WHERE cs_ste_term_v1(attrs, 'DQ1rbhWJXmmqi/+niUG6qw') > 'QAJ3HezijfTHaKrhdKxUEg';
```

And is the EQL equivalent of the following plaintext query.

```sql
SELECT * FROM users WHERE attrs->'login_count' > 10; 
```

#### `cs_ste_value_v1(val JSONB, epath TEXT)`

Retrieves the encrypted *value* associated with the encrypted JSON path, `epath`.

**Example:**

```rb
# Serialize a JSONB value bound to the users table column
path = EJSON_PATH.serialize("$.login_count")
User.find_by_sql(["SELECT cs_ste_value_v1(attrs, ?) FROM users", path])
```

Which will execute on the server as:

```sql
SELECT cs_ste_value_v1(attrs, 'DQ1rbhWJXmmqi/+niUG6qw') FROM users;
```

And is the EQL equivalent of the following plaintext query.

```sql
SELECT attrs->'login_count' FROM users; 
```


### Index functions

These functions expect a `jsonb` value that conforms to the storage schema.

#### cs_add_index

```sql
cs_add_index(table_name text, column_name text, index_name text, cast_as text, opts jsonb)
```

| Parameter     | Description                                        | Notes
| ------------- | -------------------------------------------------- | ------------------------------------
| `table_name`    | Name of target table                               | Required
| `column_name`   | Name of target column                              | Required
| `index_name`    | The index kind                                     | Required.
| `cast_as`       | The PostgreSQL type decrypted data will be cast to | Optional. Defaults to `text`
| `opts`          | Index options                                      | Optional for `match` indexes, required for `ste_vec` indexes (see below)

##### cast_as

Supported types:
  - `text`
  - `int`
  - `small_int`
  - `big_int`
  - `boolean`
  - `date`
  - `jsonb`

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

- `tokenFilters`: a list of filters to apply to normalise tokens before indexing.
- `tokenizer`: determines how input text is split into tokens.
- `m`: The size of the backing [bloom filter](https://en.wikipedia.org/wiki/Bloom_filter) in bits. Defaults to `2048`.
- `k`: The maximum number of bits set in the bloom filter per term. Defaults to `6`.

**Token Filters**

There are currently only two token filters available `downcase` and `upcase`. These are used to normalise the text before indexing and are also applied to query terms. An empty array can also be passed to `tokenFilters` if no normalisation of terms is required.

**Tokenizer**

There are two `tokenizer`s provided: `standard` and `ngram`.
The `standard` simply splits text into tokens using this regular expression: `/[ ,;:!]/`.
The `ngram` tokenizer splits the text into n-grams and accepts a configuration object that allows you to specify the `tokenLength`.

**m** and **k**

`k` and `m` are optional fields for configuring [bloom filters](https://en.wikipedia.org/wiki/Bloom_filter) that back full text search.

`m` is the size of the bloom filter in bits. `filterSize` must be a power of 2 between `32` and `65536` and defaults to `2048`.

`k` is the number of hash functions to use per term.
This determines the maximum number of bits that will be set in the bloom filter per term.
`k` must be an integer from `3` to `16` and defaults to `6`.

**Caveats around n-gram tokenization**

While using n-grams as a tokenization method allows greater flexibility when doing arbitrary substring matches, it is important to bear in mind the limitations of this approach.
Specifically, searching for strings _shorter_ than the `tokenLength` parameter will not _generally_ work.

If you're using n-gram as a token filter, then a token that is already shorter than the `tokenLength` parameter will be kept as-is when indexed, and so a search for that short token will match that record.
However, if that same short string only appears as a part of a larger token, then it will not match that record.
In general, therefore, you should try to ensure that the string you search for is at least as long as the `tokenLength` of the index, except in the specific case where you know that there are shorter tokens to match, _and_ you are explicitly OK with not returning records that have that short string as part of a larger token.

##### ste_vec opts

An ste_vec index on a encrypted JSONB column enables the use of PostgreSQL's `@>` and `<@` [containment operators](https://www.postgresql.org/docs/16/functions-json.html#FUNCTIONS-JSONB-OP-TABLE).

An ste_vec index requires one piece of configuration: the `prefix` (a string) which is functionally similar to a salt for the hashing process.

Within a dataset, encrypted columns indexed using an ste_vec that use different prefixes can never compare as equal. 
Containment queries that manage to mix index terms from multiple columns will never return a positive result. 
This is by design.

The index is generated from a JSONB document by first flattening the structure of the document such that a hash can be generated for each unique path prefix to a node.

The complete set of JSON types is supported by the indexer. 
Null values are ignored by the indexer.

- Object `{ ... }`
- Array `[ ... ]`
- String `"abc"`
- Boolean `true`
- Number `123.45`

For a document like this:

```json
{
  "account": {
    "email": "alice@example.com",
    "name": {
      "first_name": "Alice",
      "last_name": "McCrypto",
    },
    "roles": [
      "admin",
      "owner",
    ]
  }
}
```

Hashes would be produced from the following list of entries:

```json
[
  [Obj, Key("account"), Obj, Key("email"), String("alice@example.com")],
  [Obj, Key("account"), Obj, Key("name"), Obj, Key("first_name"), String("Alice")],
  [Obj, Key("account"), Obj, Key("name"), Obj, Key("last_name"), String("McCrypto")],
  [Obj, Key("account"), Obj, Key("roles"), Array, String("admin")],
  [Obj, Key("account"), Obj, Key("roles"), Array, String("owner")],
]
```

Using the first entry to illustrate how an entry is converted to hashes:

```json
[Obj, Key("account"), Obj, Key("email"), String("alice@example.com")]
```

The hashes would be generated for all prefixes of the full path to the leaf node.

```json
[
  [Obj],
  [Obj, Key("account")],
  [Obj, Key("account"), Obj],
  [Obj, Key("account"), Obj, Key("email")],
  [Obj, Key("account"), Obj, Key("email"), String("alice@example.com")],
  // (remaining leaf nodes omitted)
]
```

Query terms are processed in the same manner as the input document.

A query prior to encrypting & indexing looks like a structurally similar subset of the encrypted document, for example:

```json
{ "account": { "email": "alice@example.com", "roles": "admin" }}
```

The expression `cs_ste_vec_v1(encrypted_account) @> cs_ste_vec_v1($query)` would match all records where the `encrypted_account` column contains a JSONB object with an "account" key containing an object with an "email" key where the value is the string "alice@example.com".

When reduced to a prefix list, it would look like this:

```json
[
  [Obj],
  [Obj, Key("account")],
  [Obj, Key("account"), Obj],
  [Obj, Key("account"), Obj, Key("email")],
  [Obj, Key("account"), Obj, Key("email"), String("alice@example.com")]
  [Obj, Key("account"), Obj, Key("roles")],
  [Obj, Key("account"), Obj, Key("roles"), Array],
  [Obj, Key("account"), Obj, Key("roles"), Array, String("admin")]
]
```

Which is then turned into an ste_vec of hashes which can be directly queries against the index.

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

#### cs_ste_vec_v1

```sql
cs_ste_vec_v1(val jsonb)
```

Extracts an ste_vec index from the `jsonb` value.
Returns `null` if no ste_vec index is present.

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
| u.1      | Unique index       | Ciphertext index value. Encrypted by proxy.
| sv.1     | STE vector index   | Ciphertext index value. Encrypted by proxy.

#### Helper packages

We have created a few langague specific packages to help you interact with the payloads:

- [@cipherstash/eql](https://github.com/cipherstash/encrypt-query-language/tree/main/javascript/packages/eql): This is a TypeScript implementation of EQL.
