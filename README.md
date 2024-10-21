# CipherStash Encrypt Query Language (EQL)

[![Why we built EQL](https://img.shields.io/badge/concept-Why%20EQL-8A2BE2)](https://github.com/cipherstash/encrypt-query-language/blob/main/WHY.md)
[![CipherStash Proxy](https://img.shields.io/badge/guide-CipherStash%20Proxy-A48CF3)](https://github.com/cipherstash/encrypt-query-language/blob/main/PROXY.md)
[![Getting started](https://img.shields.io/badge/guide-Getting%20started-008000)](https://github.com/cipherstash/encrypt-query-language/blob/main/GETTINGSTARTED.md)

Encrypt Query Language (EQL) is a set of abstractions for transmitting, storing & interacting with encrypted data and indexes in PostgreSQL.

EQL provides a data format for transmitting and storing encrypted data & indexes, and database types & functions to interact with the encrypted material.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Encrypted columns](#encrypted-columns)
  - [Inserting data](#inserting-data)
  - [Reading data](#reading-data)
- [Querying data with EQL](#querying-data-with-eql)
- [Querying JSONB data with EQL](#querying-jsonb-data-with-eql)
- [Managing indexes with EQL](#managing-indexes-with-eql)
- [Data Format](#data-format)
- [Helper packages](#helper-packages)

---

## Installation

The simplest and fastest way to get up and running with EQL from scratch is to execute the install SQL file directly in your database.

1. Download the [cipherstash-encrypt-dsl.sql](./release/cipherstash-encrypt-dsl.sql) file
2. Run the following command to install the custom types and functions:

```bash
psql -f cipherstash-encrypt-dsl.sql
```

## Usage

Once the custom types and functions are installed, you can start using EQL in your queries.

1. Create a table with a column of type `cs_encrypted_v1` which will store your encrypted data.
1. Use EQL functions to add indexes for the columns you want to encrypt.
   - Indexes are used by Cipherstash Proxy to understand what cryptography schemes are required for your use case.
1. Initialize Cipherstash Proxy for cryptographic operations.
   - The Proxy will dynamically encrypt data on the way in and decrypt data on the way out based on the indexes you have defined.
1. Insert data into the defined columns using a specific payload format.
   - The payload format is defined in the [data format](#data-format) section.
1. Query the data using the EQL functions defined in the [querying data with EQL](#querying-data-with-eql) section.
   - No modifications are required to simply `SELECT` data from your encrypted columns.
   - In order to perform `WHERE` and `ORDER BY` queries, you must wrap the queries in the EQL functions defined in the [querying data with EQL](#querying-data-with-eql) section.
1. Integrate with your application via the [helper packages](#helper-packages) to interact with the encrypted data.

You can find a full getting started guide in the [GETTINGSTARTED.md](GETTINGSTARTED.md) file.

## Encrypted columns

EQL relies on your database schema to define encrypted columns.

Encrypted columns are defined using the `cs_encrypted_v1` [domain type](https://www.postgresql.org/docs/current/domains.html), which extends the `jsonb` type with additional constraints to ensure data integrity.

**Example table definition:**

```sql
CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    encrypted_email cs_encrypted_v1
);
```

In some instances, especially when using langugage specific ORMs, EQL also supports `jsonb` columns rather than the `cs_encrypted_v1` domain type.

### Configuring the column

In order for CipherStash Proxy to encrypt and decrypt the data, you can initialize the column in the database using the `cs_add_column_v1` function.
This function takes the following parameters:

- `table_name`: The name of the table containing the encrypted column.
- `column_name`: The name of the encrypted column.

This function will **not** enable searchable encryption, but will allow you to encrypt and decrypt data.
See [querying data with EQL](#querying-data-with-eql) for more information on how to enable searchable encryption.

```sql
SELECT cs_add_column_v1('table', 'column');
```

### Activate configuration

By default, the state of the configuration is `pending` after any modifications.
You can activate the configuration by running the `cs_encrypt_v1` and `cs_activate_v1` function.

```sql
SELECT cs_encrypt_v1();
SELECT cs_activate_v1();
```

> **Important:** These functions must be run after any modifications to the configuration.

#### Refresh CipherStash Proxy configuration

CipherStash Proxy pings the database every 60 seconds to refresh the configuration.
You can force CipherStash Proxy to refresh the configuration by running the `cs_refresh_encrypt_config` function.

```sql
SELECT cs_refresh_encrypt_config();
```

### Inserting data

When inserting data into the encrypted column, you must wrap the plaintext in the appropriate EQL payload.
These statements must be run through the CipherStash Proxy in order to **encrypt** the data.

**Example:**

```rb
# Create the EQL payload using helper functions
payload = eqlPayload("users", "encrypted_email", "test@test.com")

Users.create(encrypted_email: payload)
```

Which will execute on the server as:

```sql
INSERT INTO users (encrypted_email) VALUES ('{"v":1,"k":"pt","p":"test@test.com","i":{"t":"users","c":"encrypted_email"}}');
```

And is the EQL equivalent of the following plaintext query.

```sql
INSERT INTO users (email) VALUES ('test@test.com');
```

All the data stored in the database is fully encrypted and secure.

### Reading data

When querying data, you must wrap the encrypted column in the appropriate EQL payload.
These statements must be run through the CipherStash Proxy in order to **decrypt** the data.

**Example:**

```rb
Users.findAll(&:encrypted_email)
```

Which will execute on the server as:

```sql
SELECT encrypted_email FROM users;
```

And is the EQL equivalent of the following plaintext query:

```sql
SELECT email FROM users;
```

All the data returned from the database is fully decrypted.

## Querying data with EQL

EQL provides specialized functions to interact with encrypted data to support operations like equality checks, range queries, and unique constraints.

### `cs_match_v1(val JSONB)`

Enables basic full-text search.

**Example**

```rb
# Create the EQL payload using helper functions
payload = EQL.for_match("users", "encrypted_field", "plaintext value")

Users.where("cs_match_v1(field) @> cs_match_v1(?)", payload)
```

Which will execute on the server as:

```sql
SELECT * FROM users WHERE cs_match_v1(field) @> cs_match_v1('{"v":1,"k":"pt","p":"plaintext value","i":{"t":"users","c":"encrypted_field"},"q":"match"}');
```

And is the EQL equivalent of the following plaintext query.

```sql
SELECT * FROM users WHERE field LIKE '%plaintext value%';
```

### `cs_unique_v1(val JSONB)`

Retrieves the unique index for enforcing uniqueness.

**Example:**

```rb
# Create the EQL payload using helper functions
payload = EQL.for_unique("users", "encrypted_field", "plaintext value")

Users.where("cs_unique_v1(field) = cs_unique_v1(?)", payload)
```

Which will execute on the server as:

```sql
SELECT * FROM users WHERE cs_unique_v1(field) = cs_unique_v1('{"v":1,"k":"pt","p":"plaintext value","i":{"t":"users","c":"encrypted_field"},"q":"unique"}');
```

And is the EQL equivalent of the following plaintext query.

```sql
SELECT * FROM users WHERE field = 'plaintext value';
```

### `cs_ore_64_8_v1(val JSONB)`

Retrieves the Order-Revealing Encryption index for range queries.

**Sorting example:**

```rb
# Create the EQL payload using helper functions
date = EQL.for_ore("users", "encrypted_date", Time.now)

User.where("cs_ore_64_8_v1(encrypted_date) < cs_ore_64_8_v1(?)", date)
```

Which will execute on the server as:

```sql
SELECT * FROM examples WHERE cs_ore_64_8_v1(encrypted_date) < cs_ore_64_8_v1($1)
```

And is the EQL equivalent of the following plaintext query:

```sql
SELECT * FROM examples WHERE date < $1;
```

**Ordering example:**

```rb
User.order("cs_ore_64_8_v1(encrypted_field)").all().map(&:id)
```

Which will execute on the server as:

```sql
SELECT id FROM examples ORDER BY cs_ore_64_8_v1(encrypted_field) DESC;
```

And is the EQL equivalent of the following plaintext query.

```sql
SELECT id FROM examples ORDER BY field DESC;
```

## Querying JSONB data with EQL

### `cs_ste_term_v1(val JSONB, epath TEXT)`

Retrieves the encrypted _term_ associated with the encrypted JSON path, `epath`.

### `cs_ste_vec_v1(val JSONB)`

Retrieves the Structured Encryption Vector for containment queries.

**Example:**

```rb
# Serialize a JSONB value bound to the users table column
term = EQL.for_ste_vec("users", "attrs", {field: "value"})
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

### `cs_ste_term_v1(val JSONB, epath TEXT)`

Retrieves the encrypted index term associated with the encrypted JSON path, `epath`.

This is useful for sorting or filtering on integers in encrypted JSON objects.

**Example:**

```rb
# Serialize a JSONB value bound to the users table column
path = EQL.for_ejson_path("users", "attrs", "$.login_count")
term = EQL.for_ore("users", "attrs", 100)
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

### `cs_ste_value_v1(val JSONB, epath TEXT)`

Retrieves the encrypted _value_ associated with the encrypted JSON path, `epath`.

**Example:**

```rb
# Serialize a JSONB value bound to the users table column
path = EQL.for_ejson_path("users", "attrs", "$.login_count")
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

### Field extraction

Extract a field from a JSONB object in a `SELECT` statement:

```sql
SELECT cs_ste_value_v1(attrs, 'DQ1rbhWJXmmqi/+niUG6qw') FROM users;
```

The above is the equivalent to this SQL query:

```sql
SELECT attrs->'login_count' FROM users;
```


### Extraction (in WHERE, ORDER BY)

Select rows that match a field in a JSONB object:

```sql
SELECT * FROM users WHERE cs_ste_term_v1(attrs, 'DQ1rbhWJXmmqi/+niUG6qw') > 'QAJ3HezijfTHaKrhdKxUEg';
```

The above is the equivalent to this SQL query:

```sql
SELECT * FROM users WHERE attrs->'login_count' > 10; 
```

## Managing indexes with EQL

These functions expect a `jsonb` value that conforms to the storage schema.

### `cs_add_index`

```sql
cs_add_index(table_name text, column_name text, index_name text, cast_as text, opts jsonb)
```

| Parameter     | Description                                        | Notes                                                                    |
| ------------- | -------------------------------------------------- | ------------------------------------------------------------------------ |
| `table_name`  | Name of target table                               | Required                                                                 |
| `column_name` | Name of target column                              | Required                                                                 |
| `index_name`  | The index kind                                     | Required.                                                                |
| `cast_as`     | The PostgreSQL type decrypted data will be cast to | Optional. Defaults to `text`                                             |
| `opts`        | Index options                                      | Optional for `match` indexes, required for `ste_vec` indexes (see below) |

#### cast_as

Supported types:

- `text`
- `int`
- `small_int`
- `big_int`
- `boolean`
- `date`
- `jsonb`

#### match opts

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

#### ste_vec opts

An ste_vec index on a encrypted JSONB column enables the use of PostgreSQL's `@>` and `<@` [containment operators](https://www.postgresql.org/docs/16/functions-json.html#FUNCTIONS-JSONB-OP-TABLE).

An ste_vec index requires one piece of configuration: the `context` (a string) which is passed as an info string to a MAC (Message Authenticated Code).
This ensures that all of the encrypted values are unique to that context.
It is generally recommended to use the table and column name as a the context (e.g. `users/name`).

Within a dataset, encrypted columns indexed using an `ste_vec` that use different contexts cannot be compared.
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
      "last_name": "McCrypto"
    },
    "roles": ["admin", "owner"]
  }
}
```

Hashes would be produced from the following list of entries:

```js
[
  [Obj, Key("account"), Obj, Key("email"), String("alice@example.com")],
  [
    Obj,
    Key("account"),
    Obj,
    Key("name"),
    Obj,
    Key("first_name"),
    String("Alice"),
  ],
  [
    Obj,
    Key("account"),
    Obj,
    Key("name"),
    Obj,
    Key("last_name"),
    String("McCrypto"),
  ],
  [Obj, Key("account"), Obj, Key("roles"), Array, String("admin")],
  [Obj, Key("account"), Obj, Key("roles"), Array, String("owner")],
];
```

Using the first entry to illustrate how an entry is converted to hashes:

```js
[Obj, Key("account"), Obj, Key("email"), String("alice@example.com")];
```

The hashes would be generated for all prefixes of the full path to the leaf node.

```js
[
  [Obj],
  [Obj, Key("account")],
  [Obj, Key("account"), Obj],
  [Obj, Key("account"), Obj, Key("email")],
  [Obj, Key("account"), Obj, Key("email"), String("alice@example.com")],
  // (remaining leaf nodes omitted)
];
```

Query terms are processed in the same manner as the input document.

A query prior to encrypting & indexing looks like a structurally similar subset of the encrypted document, for example:

```json
{ "account": { "email": "alice@example.com", "roles": "admin" } }
```

The expression `cs_ste_vec_v1(encrypted_account) @> cs_ste_vec_v1($query)` would match all records where the `encrypted_account` column contains a JSONB object with an "account" key containing an object with an "email" key where the value is the string "alice@example.com".

When reduced to a prefix list, it would look like this:

```js
[
  [Obj],
  [Obj, Key("account")],
  [Obj, Key("account"), Obj],
  [Obj, Key("account"), Obj, Key("email")],
  [Obj, Key("account"), Obj, Key("email"), String("alice@example.com")][
    (Obj, Key("account"), Obj, Key("roles"))
  ],
  [Obj, Key("account"), Obj, Key("roles"), Array],
  [Obj, Key("account"), Obj, Key("roles"), Array, String("admin")],
];
```

Which is then turned into an ste_vec of hashes which can be directly queries against the index.

### `cs_modify_index`

```sql
_cs_modify_index_v1(table_name text, column_name text, index_name text, cast_as text, opts jsonb)
```

Modifies an existing index configuration.
Accepts the same parameters as `cs_add_index`

### `cs_remove_index`

```sql
cs_remove_index_v1(table_name text, column_name text, index_name text)
```

Removes an index configuration from the column.

## Data Format

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

The format is defined as a [JSON Schema](./cs_encrypted_v1.schema.json).

It should never be necessary to directly interact with the stored `jsonb`.
Cipherstash proxy handles the encoding, and EQL provides the functions.

| Field | Name              | Description                                                                                                                                                                                                                                                               |
| ----- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| s     | Schema version    | JSON Schema version of this json document.                                                                                                                                                                                                                                |
| v     | Version           | The configuration version that generated this stored value.                                                                                                                                                                                                               |
| k     | Kind              | The kind of the data (plaintext/pt, ciphertext/ct, encrypting/et).                                                                                                                                                                                                        |
| i.t   | Table identifier  | Name of the table containing encrypted column.                                                                                                                                                                                                                            |
| i.c   | Column identifier | Name of the encrypted column.                                                                                                                                                                                                                                             |
| p     | Plaintext         | Plaintext value sent by database client. Required if kind is plaintext/pt or encrypting/et.                                                                                                                                                                               |
| q     | For query         | Specifies that the plaintext should be encrypted for a specific query operation. If `null`, source encryption and encryption for all indexes will be performed. Valid values are `"match"`, `"ore"`, `"unique"`, `"ste_vec"`, `"ejson_path"`, and `"websearch_to_match"`. |
| c     | Ciphertext        | Ciphertext value. Encrypted by proxy. Required if kind is plaintext/pt or encrypting/et.                                                                                                                                                                                  |
| m     | Match index       | Ciphertext index value. Encrypted by proxy.                                                                                                                                                                                                                               |
| o     | ORE index         | Ciphertext index value. Encrypted by proxy.                                                                                                                                                                                                                               |
| u     | Unique index      | Ciphertext index value. Encrypted by proxy.                                                                                                                                                                                                                               |
| sv    | STE vector index  | Ciphertext index value. Encrypted by proxy.                                                                                                                                                                                                                               |

## Helper packages

We have created a few langague specific packages to help you interact with the payloads:

- [@cipherstash/eql](https://github.com/cipherstash/encrypt-query-language/tree/main/languages/javascript/packages/eql): This is a TypeScript implementation of EQL.
- [github.com/cipherstash/goeql](https://github.com/cipherstash/goeql): This is a Go implementation of EQL.
