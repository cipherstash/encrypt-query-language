# CipherStash Encrypt Query Language (EQL)

[![Why we built EQL](https://img.shields.io/badge/concept-Why%20EQL-8A2BE2)](https://github.com/cipherstash/encrypt-query-language/blob/main/WHY.md)
[![Getting started](https://img.shields.io/badge/guide-Getting%20started-008000)](https://github.com/cipherstash/encrypt-query-language/blob/main/GETTINGSTARTED.md)
[![CipherStash Proxy](https://img.shields.io/badge/guide-CipherStash%20Proxy-A48CF3)](https://github.com/cipherstash/encrypt-query-language/blob/main/PROXY.md)
[![CipherStash Migrator](https://img.shields.io/badge/guide-CipherStash%20Migrator-A48CF3)](https://github.com/cipherstash/encrypt-query-language/blob/main/MIGRATOR.md)

Encrypt Query Language (EQL) is a set of abstractions for transmitting, storing, and interacting with encrypted data and indexes in PostgreSQL.

EQL provides a data format for transmitting and storing encrypted data and indexes, as well as database types and functions to interact with the encrypted material.

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
- [Releasing](#releasing)

---

## Installation

The simplest and fastest way to get up and running with EQL is to execute the install SQL file directly in your database.

1. Get the latest EQL install script:
   ```bash
    curl -sLo cipherstash-encrypt.sql https://github.com/cipherstash/encrypt-query-language/releases/latest/download/cipherstash-encrypt.sql
   ```
1. Run this command to install the custom types and functions:
   ```bash
   psql -f cipherstash-encrypt.sql
   ```

## Usage

Once the custom types and functions are installed, you can start using EQL in your queries.

1. Create a table with a column of type `cs_encrypted_v1` which will store your encrypted data.
2. Use EQL functions to add indexes for the columns you want to encrypt.
   - Indexes are used by CipherStash Proxy to understand what cryptography schemes are required for your use case.
3. Initialize CipherStash Proxy for cryptographic operations.
   - Proxy will dynamically encrypt data on the way in and decrypt data on the way out, based on the indexes you've defined.
4. Insert data into the defined columns using a specific payload format.
   - See [data format](#data-format) for the payload format.
5. Query the data using the EQL functions defined in [querying data with EQL](#querying-data-with-eql).
   - No modifications are required to simply `SELECT` data from your encrypted columns.
   - To perform `WHERE` and `ORDER BY` queries, wrap the queries in the EQL functions defined in [querying data with EQL](#querying-data-with-eql).
6. Integrate with your application via the [helper packages](#helper-packages) to interact with the encrypted data.

Read [GETTINGSTARTED.md](GETTINGSTARTED.md) for more detail.

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

So that CipherStash Proxy can encrypt and decrypt the data, initialize the column in the database using the `cs_add_column_v1` function.
This function takes the following parameters:

- `table_name`: the name of the table containing the encrypted column.
- `column_name`: the name of the encrypted column.

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

## How to example

These examples will show how EQL works using raw SQL.

We are in the process of building out packages to abstract the serializing/deserializing logic needed to handle EQL payloads.

#### EQL packages

We currently have packages for or examples of how to do this for the below languages/ORM's:

| Language   | ORM         | Example                                                           | Package                                                          |
| ---------- | ----------- | ----------------------------------------------------------------- | ---------------------------------------------------------------- |
| Go         | Xorm        | [Xorm examples](./languages/go/xorm/README.md)                    | [goeql](https://github.com/cipherstash/goeql)                    |
| Typescript | Drizzle     | [Drizzle examples](./languages/javascript/apps/drizzle/README.md) | [cipherstash/eql](./languages/javascript/packages/eql/README.md) |
| Typescript | Prisma      | [Drizzle examples](./languages/javascript/apps/prisma/README.md)  | [cipherstash/eql](./languages/javascript/packages/eql/README.md) |
| Python     | SQL Alchemy | [Python examples](./languages/python/jupyter_notebook/README.md)  |                                                                  |

Prerequisites:

- [EQL has been installed](./GETTINGSTARTED.md)
- [CipherStash proxy is setup](./PROXY.md)

Let's step through an example of how we go from a plaintext text field to an encrypted text field.

This guide will include:

- How to [setup your database](#setup-your-database)
- How to [add indexes](#adding-indexes)
- How to [encrypt existing plaintext data](#encrypting-existing-plaintext-data)
- How to [insert data](#inserting-data)
- How to [query data](#querying-data)

We will use a `users` table with an email field for this example.

Run:

```sql
CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR(100) NOT NULL
);
```

Our `users` schema looks like this:

| Column  | Type                     | Nullable |
| ------- | ------------------------ | -------- |
| `id`    | `bigint`                 | not null |
| `email` | `character varying(100)` | not null |

Seed plaintext data into the users table:

```sql
INSERT INTO users (email) VALUES
('adalovelace@example.com'),
('gracehopper@test.com'),
('edithclarke@email.com');
```

### Setup your database

In the previous step we:

- setup a basic users table with a plaintext email field.
- seeded the db with plaintext emails.

In this part we will add a new column to store our encrypted email data.

When we add the column we use a `Type` of `cs_encrypted_v1`.

This type will enforce constraints on the field to ensure that:

- the payload is in the [format EQL and CipherStash Proxy expects](./sql/schemas/cs_encrypted_v1.schema.json).
- the payload has been encrypted before inserting.

If there are issues with the payload being inserted into a field with a type of `cs_encrypted_v1`, an error will be returned describing what the issue with the payload is.

To add a new column called `email_encrypted` with a type of `cs_encrypted_v1`:

```sql
ALTER TABLE users ADD email_encrypted cs_encrypted_v1;
```

Our `users` schema now looks like this:

| Column            | Type                     | Nullable |
| ----------------- | ------------------------ | -------- |
| `id`              | `bigint`                 | not null |
| `email`           | `character varying(100)` | not null |
| `email_encrypted` | `cs_encrypted_v1`        |          |

### Adding indexes

We now have our database schema setup to store encrypted data.

In this part we will learn about why we need to add indexes and how to add them.

When you install EQL, a table called `cs_configuration_v1` is created in your database.

Adding indexes updates this table with the details and configuration needed for CipherStash Proxy to know how to encrypt your data, and what types of queries are able to be performed

We will also need to add the relevant native database indexes to be able to perform these queries.

<!-- Point to section describing the different types of indexes. Does this exist? -->

In this example, we want to be able to execute these types of queries on our `email_encrypted` field:

- free text search
- equality
- order by

This means that we need to add the below indexes for our new `email_encrypted` field.

For free text queries (e.g `LIKE`, `ILIKE`) we add a `match` index and a GIN index:

<!-- link to match index options/details -->

```sql
SELECT cs_add_index_v1('users', 'email_encrypted', 'match', 'text');
CREATE INDEX ON users USING GIN (cs_match_v1(email_encrypted));
```

For equality queries we add a `unique` index:

```sql
SELECT cs_add_index_v1('users', 'email_encrypted', 'unique', 'text', '{"token_filters": [{"kind": "downcase"}]}');
CREATE UNIQUE INDEX ON users(cs_unique_v1(email_encrypted));
```

For ordering or range queries we add an `ore` index:

```sql
SELECT cs_add_index_v1('users', 'email_encrypted', 'ore', 'text');
CREATE INDEX ON users (cs_ore_64_8_v1(email_encrypted));
```

After adding these indexes, our `cs_configuration_v1` table will look like this:

```bash
id         | 1
state      | pending
data       | {"v": 1, "tables": {"users": {"email_encrypted": {"cast_as": "text", "indexes": {"ore": {}, "match": {"k": 6, "m": 2048, "tokenizer": {"kind": "ngram", "token_length": 3}, "token_filters": [{"kind": "downcase"}], "include_original": true}, "unique": {"token_filters": [{"kind": "downcase"}]}}}}}}
```

The initial `state` will be set as pending.

To activate this configuration run:

```sql
SELECT cs_encrypt_v1();
SELECT cs_activate_v1();
```

The `cs_configuration_v1` table will now have a state of `active`.

```bash
id         | 1
state      | active
data       | {"v": 1, "tables": {"users": {"email_encrypted": {"cast_as": "text", "indexes": {"ore": {}, "match": {"k": 6, "m": 2048, "tokenizer": {"kind": "ngram", "token_length": 3}, "token_filters": [{"kind": "downcase"}], "include_original": true}, "unique": {"token_filters": [{"kind": "downcase"}]}}}}}}
```

### Encrypting existing plaintext data

Prerequisites:

- [Database is setup](#setup-your-database)
- [Indexes added](#adding-indexes)
- CipherStash Proxy has been setup and is running using the [getting started guide](PROXY.md).

Ensure CipherStash Proxy has the most up to date configuration from the `cs_configuration_v1` table.

CipherStash Proxy pings the database every 60 seconds to refresh the configuration but we can force the refresh by running:

```sql
SELECT cs_refresh_encrypt_config();
```

Bundled in with the CipherStash Proxy is a [migrator tool](./MIGRATOR.md).

This tool encrypts the plaintext data from the plaintext `email` field, and inserts it into the encrypted field, `email_encrypted`.

We access the migrator tool by requesting a shell inside the CipherStash Proxy container.

```bash
docker exec -it eql-cipherstash-proxy bash
```

In this example the container name for CipherStash Proxy is `eql-cipherstash-proxy`.

To copy plaintext data and encrypt into the enc :

```bash
cipherstash-migrator --columns email=email_encrypted --table users --database-name postres --username postgres --password postgres
```

We now have encrypted data in our `email_encrypted` fields that we can query.

### Inserting data

When inserting data into the encrypted column we need to wrap the plaintext in an EQL payload.

The reason for this is that the CipherStash Proxy expects the EQL payload to be able to encrypt the data, and to be able to decrypt the data.

These statements must be run through the CipherStash Proxy in order to **encrypt** the data.

For a plaintext of `test@test.com`.

An EQL payload will look like this:

```json
{
  "k": "pt", // The kind of EQL payload. The client will always send through plaintext "pt"
  "p": "test@test.com", // The plaintext data
  "i": {
    "t": "users", // The table
    "c": "encrypted_email" // The encrypted column
  },
  "v": 1,
  "q": null // Used in queries only.
}
```

A query to insert an email into the plaintext `email` field in the `users` table looks like this:

```sql
INSERT INTO users (email) VALUES ('test@test.com');
```

The equivalent of this query to insert a plaintext email and encrypt it into the `encrypted_email` column using EQL:

```sql
INSERT INTO users (encrypted_email) VALUES ('{"v":1,"k":"pt","p":"test@test.com","i":{"t":"users","c":"encrypted_email"}}');
```

**What is happening?**

The CipherStash Proxy takes this EQL payload from the client and encrypts the plaintext data.

It creates an EQL payload that looks similar to this and inserts this into the encrypted field in the database.

```json
{
  "k": "ct", // The kind of EQL payload. The Proxy will insert a json payload of a ciphertext or "ct".
  "c": "encrypted test@test.com", // The source ciphertext of the plaintext email.
  "e": {
    "t": "users", // Table
    "c": "email_encrypted" // Encrypted column
  },
  "m": [42], // The ciphertext used for free text queries i.e match index
  "u": "unique ciphertext", // The ciphertext used for unique queries. i.e unique index
  "o": ["a", "b", "c"], // The ciphertext used for order or range queries. i.e ore index
  "v": 1
}
```

This is what is stored in the `email_encrypted` column.

### Querying data

In this part we will step through how to read our encrypted data.

We will cover:

- simple queries
- free text search queries
- exact/unique queries
- order by and range queries

#### Simple query

If we don't need to execute any searchable operations (free text, exact) on the encrypted field.

The query will look similar to a plaintext query except we will use the encrypted column.

A plaintext query to select all emails from the users table would look like this:

```sql
SELECT email FROM users;
```

The EQL equivalent of this query is:

```sql
SELECT encrypted_email->>'p' FROM users;
```

**What is happening?**

We receive an EQL payload for all data returned from encrypted columns:

```json
{
  "k": "pt",
  "p": "test@test.com", // The returned plaintext data
  "i": {
    "t": "users",
    "c": "encrypted_email"
  },
  "v": 1,
  "q": null
}
```

We use the `->>` jsonb operator to extract the `"p"` value.

#### Advanced querying

EQL provides specialized functions to interact with encrypted data to support operations like equality checks, range queries, and unique constraints.

#### Full-text search

In this example we learn how to execute a full-text search on the `email_encrypted` field.

Prerequsite:

- A [match index](#adding-indexes) is needed on the encrypted column to support this operation.

EQL function to use: `cs_match_v1(val JSONB)`

EQL query payload for a match query:

```json
{
  "k": "pt",
  "p": "grace", // The text we want to use for search
  "i": {
    "t": "users",
    "c": "email_encrypted"
  },
  "v": 1,
  "q": "match" // This field is required on queries. This specifies the type of query we are executing.
}
```

A full-text search query on the plaintext email field would look like this:

```sql
SELECT * FROM users WHERE email LIKE '%grace%';
```

The equivalent of this query on the encrypted email field using EQL:

```sql
SELECT * FROM users WHERE cs_match_v1(email_encrypted) @> cs_match_v1('{"v":1,"k":"pt","p":"grace","i":{"t":"users","c":"email_encrypted"},"q":"match"}');
```

#### Unique or equality query

In this example we learn how to execute an equality query on the `email_encrypted` field.

Prerequsite:

- A [unique index](#adding-indexes) is needed on the encrypted column to support this operation.

EQL function to use: `cs_unique_v1(val JSONB)`

EQL query payload for a match query:

```json
{
  "k": "pt",
  "p": "gracehopper@test.com", // The text we want to use for the unique/equality query
  "i": {
    "t": "users",
    "c": "email_encrypted"
  },
  "v": 1,
  "q": "unique" // This field is required on queries. This specifies the type of query we are executing.
}
```

An equality query on the plaintext email field would look like this:

```sql
SELECT * FROM users WHERE email = 'gracehopper@test.com';
```

The equivalent of this query on the encrypted email field using EQL:

```sql
SELECT * FROM users WHERE cs_unique_v1(email_encrypted) = cs_unique_v1('{"v":1,"k":"pt","p":"gracehopper@test.com","i":{"t":"users","c":"email_encrypted"},"q":"unique"}');
```

#### Order by query

In this example we learn how to execute an order by query on the `email_encrypted` field.

Prerequsite:

- An [ore index](#adding-indexes) is needed on the encrypted column to support this operation.

EQL function to use: `cs_ore_64_8_v1(val JSONB))`

An order by query on the plaintext email field would look like this:

```sql
SELECT * FROM users WHERE ORDER BY email;
```

The EQL equivalent of this query on the encrypted email field:

```sql
SELECT * FROM users ORDER BY cs_ore_64_8_v1(email_encrypted);
```

#### Comparison query

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

**Grouping example:**

ORE indexes can be used along with the `cs_grouped_value_v1` aggregate function to group by an encrypted column:

```
SELECT cs_grouped_value_v1(encrypted_field) COUNT(*)
  FROM users
  GROUP BY cs_ore_64_8_v1(encrypted_field)
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

Which is the equivalent to the following SQL query:

```sql
SELECT attrs->'login_count' FROM users;
```

### Extraction (in WHERE, ORDER BY)

Select rows that match a field in a JSONB object:

```sql
SELECT * FROM users WHERE cs_ste_term_v1(attrs, 'DQ1rbhWJXmmqi/+niUG6qw') > 'QAJ3HezijfTHaKrhdKxUEg';
```

Which is the equivalent to the following SQL query:

```sql
SELECT * FROM users WHERE attrs->'login_count' > 10;
```

### Grouping

`cs_ste_vec_term_v1` can be used along with the `cs_grouped_value_v1` aggregate function to group by a field in an encrypted JSONB column:

```
-- $1 here is a param that containts the EQL payload for an ejson path.
-- Example EQL payload for the path `$.field_one`:
--  '{"k": "pt", "p": "$.field_one", "q": "ejson_path", "i": {"t": "users", "c": "attrs"}, "v": 1}'
SELECT cs_grouped_value_v1(cs_ste_vec_value_v1(attrs), $1) COUNT(*)
  FROM users
  GROUP BY cs_ste_vec_term_v1(attrs, $1);
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

- `tokenFilters`: a list of filters to apply to normalize tokens before indexing.
- `tokenizer`: determines how input text is split into tokens.
- `m`: The size of the backing [bloom filter](https://en.wikipedia.org/wiki/Bloom_filter) in bits. Defaults to `2048`.
- `k`: The maximum number of bits set in the bloom filter per term. Defaults to `6`.

**Token filters**

There are currently only two token filters available: `downcase` and `upcase`. These are used to normalise the text before indexing and are also applied to query terms. An empty array can also be passed to `tokenFilters` if no normalisation of terms is required.

**Tokenizer**

There are two `tokenizer`s provided: `standard` and `ngram`.
`standard` simply splits text into tokens using this regular expression: `/[ ,;:!]/`.
`ngram` splits the text into n-grams and accepts a configuration object that allows you to specify the `tokenLength`.

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

## Data format

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

| Field | Name              | Description                                                                                                                                                                                                                                                               |
| ----- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| s     | Schema version    | JSON Schema version of this json document.                                                                                                                                                                                                                                |
| v     | Version           | The configuration version that generated this stored value.                                                                                                                                                                                                               |
| k     | Kind              | The kind of the data (plaintext/pt, ciphertext/ct, encrypting/et).                                                                                                                                                                                                        |
| i.t   | Table identifier  | Name of the table containing encrypted column.                                                                                                                                                                                                                            |
| i.c   | Column identifier | Name of the encrypted column.                                                                                                                                                                                                                                             |
| p     | Plaintext         | Plaintext value sent by database client. Required if kind is plaintext/pt or encrypting/et.                                                                                                                                                                               |
| q     | For query         | Specifies that the plaintext should be encrypted for a specific query operation. If `null`, source encryption and encryption for all indexes will be performed. Valid values are `"match"`, `"ore"`, `"unique"`, `"ste_vec"`, `"ejson_path"`, and `"websearch_to_match"`. |
| c     | Ciphertext        | Ciphertext value. Encrypted by Proxy. Required if kind is plaintext/pt or encrypting/et.                                                                                                                                                                                  |
| m     | Match index       | Ciphertext index value. Encrypted by Proxy.                                                                                                                                                                                                                               |
| o     | ORE index         | Ciphertext index value. Encrypted by Proxy.                                                                                                                                                                                                                               |
| u     | Unique index      | Ciphertext index value. Encrypted by Proxy.                                                                                                                                                                                                                               |
| sv    | STE vector index  | Ciphertext index value. Encrypted by Proxy.                                                                                                                                                                                                                               |

## Helper packages

We've created a few langague specific packages to help you interact with the payloads:

- [@cipherstash/eql](https://github.com/cipherstash/encrypt-query-language/tree/main/languages/javascript/packages/eql): This is a TypeScript implementation of EQL.
- [github.com/cipherstash/goeql](https://github.com/cipherstash/goeql): This is a Go implementation of EQL

## Releasing

To cut a [release](https://github.com/cipherstash/encrypt-query-language/releases) of EQL:

1. Draft a [new release](https://github.com/cipherstash/encrypt-query-language/releases/new) on GitHub.
1. Choose a tag, and create a new one with the prefix `eql-` followed by a [semver](https://semver.org/) (for example, `eql-1.2.3`).
1. Generate the release notes.
1. Optionally set the release to be the latest (you can set a release to be latest later on if you are testing out a release first).
1. Click `Publish release`.

This will trigger the [Release EQL](https://github.com/cipherstash/encrypt-query-language/actions/workflows/release-eql.yml) workflow, which will build and attach artifacts to [the release](https://github.com/cipherstash/encrypt-query-language/releases/).
