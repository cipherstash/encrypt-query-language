## Getting started

## Setup

Before we begin using EQL and the Proxy, we'll need to do some setup to get the necessary keys and configuration.

1. Create an [account](https://cipherstash.com/signup).

2. Install the CLI:

```shell
brew install cipherstash/tap/stash
```

3. Login:

```shell
stash login
```

4. Create a [dataset](https://cipherstash.com/docs/how-to/creating-datasets) and [client](https://cipherstash.com/docs/how-to/creating-clients), and record them as `CS_CLIENT_ID` and `CS_CLIENT_KEY`.

```shell
stash datasets create eql-test
# grab dataset ID and export CS_DATASET_ID=

stash clients create eql-test --dataset-id $CS_DATASET_ID
```

5. Create an [access key](https://cipherstash.com/docs/how-to/creating-access-keys) for CipherStash Proxy:

```shell
stash workspaces
# grab the workspace ID and export CS_WORKSPACE_ID=
stash access-keys create --workspace-id $CS_WORKSPACE_ID eql-test
```

6. Go to the [EQL playground](../../playground\) and copy over the example `.envrc` file:

```shell
cd playground
cp .envrc.example .envrc
```

Update the `.envrc` file with these environment variables `CS_WORKSPACE_ID`, `CS_CLIENT_ACCESS_KEY`, `CS_ENCRYPTION__CLIENT_ID`, `CS_ENCRYPTION__CLIENT_KEY` and `CS_DATASET_ID`:

```shell
source .envrc
```

7. Start PostgreSQL and CipherStash Proxy and install EQL:

```shell
docker compose up
```

This will:

- spin up a docker container for the CipherStash Proxy and Postgres
- install EQL

8. Check Postgres and the Proxy are running:

```shell
docker ps
```

You should see 2 containers running, `postgres_proxy` and `eql-playground-pg`.

## Example

These examples will show how EQL works using raw SQL.

Prerequisites:

- PostgreSQL and CipherStash Proxy are running in docker containers.

Let's step through an example of how we go from a plaintext text field to an encrypted text field.

This guide will include:

- How to [setup your database](#setup-your-database)
- How to [add indexes](#adding-indexes)
- How to [encrypt existing plaintext data](#encrypting-existing-plaintext-data)
- How to [insert data](#inserting-data)
- How to [query data](#querying-data)

Connect to your postgres docker container:

```bash
docker exec -it eql-playground-pg bash
```

Start `psql`:

```bash
PGPASSWORD=postgres PGUSER=postgres psql
```

We will use a `users` table with an email field for this example.

In psql, run:

```sql
CREATE TABLE IF NOT EXISTS users (
	id serial PRIMARY KEY NOT NULL,
	email VARCHAR(100)
);
```

Our `users` schema looks like this:

| Column  | Type                     | Nullable |
| ------- | ------------------------ | -------- |
| `email` | `character varying(100)` |          |

Seed plaintext data into the users table:

```sql
INSERT INTO users (email) VALUES
('adalovelace@example.com'),
('gracehopper@test.com'),
('edithclarke@email.com');
```

### Setup your database

In the previous step we:

- setup a basic users table with a plaintext email (text) field.
- seeded the db with plaintext emails.

In this part we will add a new column to store our encrypted email data.

When we add the column we use a `Type` of `cs_encrypted_v2`.

This type will enforce constraints on the field to ensure that:

- the payload is in the format EQL and CipherStash Proxy expects.
- the payload has been encrypted before inserting.

If there are issues with the payload being inserted into a field with a type of `cs_encrypted_v2`, an error will be returned describing what the issue with the payload is.

To add a new column called `email_encrypted` with a type of `cs_encrypted_v2`:

```sql
ALTER TABLE users ADD email_encrypted cs_encrypted_v2;
```

Our `users` schema now looks like this:

| Column            | Type                     | Nullable |
| ----------------- | ------------------------ | -------- |
| `email`           | `character varying(100)` |          |
| `email_encrypted` | `cs_encrypted_v2`        |          |

### Adding indexes

We now have our database schema setup to store encrypted data.

In this part we will learn about why we need to add indexes and how to add them.

When you install EQL, a table called `eql_v2_configuration` is created in your database.

Adding indexes updates this table with the details and configuration needed for CipherStash Proxy to know how to encrypt your data, and what types of queries are able to be performed

We will also need to add the relevant native database indexes to be able to perform these queries.

In this example, we want to be able to execute these types of queries on our `email_encrypted` field:

- free text search
- equality
- order by
- comparison

This means that we need to add the below indexes for our new `email_encrypted` field.

For free text queries (e.g `LIKE`, `ILIKE`) we add a `match` index and a GIN index:

```sql
SELECT cs_add_index_v2('users', 'email_encrypted', 'match', 'text');
CREATE INDEX ON users USING GIN (cs_match_v2(email_encrypted));
```

For equality queries we add a `unique` index:

```sql
SELECT cs_add_index_v2('users', 'email_encrypted', 'unique', 'text', '{"token_filters": [{"kind": "downcase"}]}');
CREATE UNIQUE INDEX ON users(cs_unique_v2(email_encrypted));
```

For ordering or comparison queries we add an `ore` index:

```sql
SELECT cs_add_index_v2('users', 'email_encrypted', 'ore', 'text');
CREATE INDEX ON users (ore_block_u64_8_256(email_encrypted));
```

After adding these indexes, our `eql_v2_configuration` table will look like this:

```bash
id         | 1
state      | pending
data       | {"v": 2, "tables": {"users": {"email_encrypted": {"cast_as": "text", "indexes": {"ore": {}, "match": {"k": 6, "bf": 2048, "tokenizer": {"kind": "ngram", "token_length": 3}, "token_filters": [{"kind": "downcase"}], "include_original": true}, "unique": {"token_filters": [{"kind": "downcase"}]}}}}}}
```

The initial `state` will be set as pending.

To activate this configuration run:

```sql
SELECT cs_encrypt_v2();
SELECT cs_activate_v2();
```

The `cs_configured_v2` table will now have a state of `active`.

```bash
id         | 1
state      | active
data       | {"v": 2, "tables": {"users": {"email_encrypted": {"cast_as": "text", "indexes": {"ore": {}, "match": {"k": 6, "bf": 2048, "tokenizer": {"kind": "ngram", "token_length": 3}, "token_filters": [{"kind": "downcase"}], "include_original": true}, "unique": {"token_filters": [{"kind": "downcase"}]}}}}}}
```

### Encrypting existing plaintext data

Prerequisites:

- [Database is setup](#setup-your-database)
- [Indexes added](#adding-indexes)

Ensure CipherStash Proxy has the most up to date configuration from the `eql_v2_configuration` table.

CipherStash Proxy pings the database every 60 seconds to refresh the configuration but we can force the refresh by running:

```sql
SELECT cs_refresh_encrypt_config();
```

Bundled in with the CipherStash Proxy is a [migrator tool](./MIGRATOR.md).

This tool encrypts the plaintext data from the plaintext `email` field, and inserts it into the encrypted field, `email_encrypted`.

We access the migrator tool by requesting a shell inside the CipherStash Proxy container.

```bash
docker exec -it postgres_proxy bash
```

Run:

```bash
cipherstash-migrator --columns email=email_encrypted --table users --database-name postgres --username postgres --password postgres
```

We now have encrypted data in our `email_encrypted` field that we can query.

Drop the plaintext email column:

```sql
ALTER TABLE users DROP COLUMN email;
```

**Note: In production ensure data is backed up before dropping any columns**

### Insert a new record

Before inserting or querying any records, we need to connect to our database via the Proxy.

We do this so our data is encrypted and decrypted.

In another terminal run:

```bash
PGPASSWORD=postgres psql -h localhost -p 6432 -U postgres -d postgres
```

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
    "c": "email_encrypted" // The encrypted column
  },
  "v": 2,
  "q": null // Used in queries only.
}
```

**Example:**

A query to insert an email into the plaintext `email` field in the `users` table looks like this:

```sql
INSERT INTO users (email) VALUES ('test@test.com');
```

The equivalent of this query to insert a plaintext email and encrypt it into the `email_encrypted` column using EQL:

```sql
INSERT INTO users (email_encrypted) VALUES ('{"v":2,"k":"pt","p":"test@test.com","i":{"t":"users","c":"email_encrypted"}}');
```

**What is happening?**

The CipherStash Proxy takes this EQL payload and encrypts the plaintext data.

It creates an EQL payload that looks similar to this and inserts this into the encrypted field in the database.

```json
{
  "k": "ct", // The kind of EQL payload. The Proxy will insert a json payload of a ciphertext or "ct".
  "c": "encrypted test@test.com", // The source ciphertext of the plaintext email.
  "e": {
    "t": "users", // Table
    "c": "email_encrypted" // Encrypted column
  },
  "bf": [42], // The ciphertext used for free text queries i.e match index
  "u": "unique ciphertext", // The ciphertext used for unique queries. i.e unique index
  "ob": ["a", "b", "c"], // The ciphertext used for order or comparison queries. i.e ore index
  "v": 2
}
```

This is what is stored in the `email_encrypted` column.

### Querying data

In this part we will step through how to read our encrypted data.

We will cover:

- simple queries
- free text search queries
- exact/unique queries
- order by and comparison queries

#### Simple query

If we don't need to execute any searchable operations (free text, exact) on the encrypted field.

The query will look similar to a plaintext query except we will use the encrypted column.

A plaintext query to select all emails from the users table would look like this:

```sql
SELECT email FROM users;
```

The EQL equivalent of this query is:

```sql
SELECT email_encrypted FROM users;
```

Returns:

```bash
                                         email_encrypted
-------------------------------------------------------------------------------------------------
 {"k":"pt","p":"adalovelace@example.com","i":{"t":"users","c":"email_encrypted"},"v":2,"q":null}
 {"k":"pt","p":"gracehopper@test.com","i":{"t":"users","c":"email_encrypted"},"v":2,"q":null}
 {"k":"pt","p":"edithclarke@email.com","i":{"t":"users","c":"email_encrypted"},"v":2,"q":null}
 {"k":"pt","p":"test@test.com","i":{"t":"users","c":"email_encrypted"},"v":2,"q":null}
```

**What is happening?**

The json stored in the database looks similar to this:

```json
{
  "k": "ct", // The kind of EQL payload. The Proxy will insert a json payload of a ciphertext or "ct".
  "c": "encrypted test@test.com", // The source ciphertext of the plaintext email.
  "e": {
    "t": "users", // Table
    "c": "email_encrypted" // Encrypted column
  },
  "bf": [42], // The ciphertext used for free text queries i.e match index
  "u": "unique ciphertext", // The ciphertext used for unique queries. i.e unique index
  "ob": ["a", "b", "c"], // The ciphertext used for order or comparison queries. i.e ore index
  "v": 2
}
```

The Proxy decrypts the json above and returns a plaintext json payload that looks like this:

```json
{
  "k": "pt",
  "p": "test@test.com", // The returned plaintext data
  "i": {
    "t": "users",
    "c": "email_encrypted"
  },
  "v": 2,
  "q": null
}
```

> When working with EQL in an application you would likely be using an ORM.

> We are currently building out [packages and examples](../../README.md#helper-packages) to make it easier to work with EQL json payloads.

#### Advanced querying

EQL provides specialized functions to be able to interact with encrypted data and to support operations like equality checks, comparison queries, and unique constraints.

#### Full-text search

Prerequsites:

- A [match index](#adding-indexes) is needed on the encrypted column to support this operation.
- Connected to the database via the Proxy.

EQL function to use: `cs_match_v2(val JSONB)`

EQL query payload for a match query:

```json
{
  "k": "pt",
  "p": "grace", // The text we want to use for search
  "i": {
    "t": "users",
    "c": "email_encrypted"
  },
  "v": 2,
  "q": "match" // This field is required on queries. This specifies the type of query we are executing.
}
```

A plaintext query, to search for any records that have an email like `grace`, looks like this:

```sql
SELECT * FROM users WHERE email LIKE '%grace%';
```

The EQL equivalent of this query is:

```sql
SELECT * FROM users WHERE cs_match_v2(email_encrypted) @> cs_match_v2(
  '{"v":2,"k":"pt","p":"grace","i":{"t":"users","c":"email_encrypted"},"q":"match"}'
  );
```

This query returns:

| id  | email_encrypted                                                                              |
| --- | -------------------------------------------------------------------------------------------- |
| 2   | {"k":"pt","p":"gracehopper@test.com","i":{"t":"users","c":"email_encrypted"},"v":2,"q":null} |

#### Equality query

Prerequsites:

- A [unique index](#adding-indexes) is needed on the encrypted column to support this operation.

EQL function to use: `cs_unique_v2(val JSONB)`

EQL query payload for a match query:

```json
{
  "k": "pt",
  "p": "adalovelace@example.com", // The text we want to use for the equality query
  "i": {
    "t": "users",
    "c": "email_encrypted"
  },
  "v": 2,
  "q": "unique" // This field is required on queries. This specifies the type of query we are executing.
}
```

A plaintext query to search for any records that equal `adalovelace@example.com` looks like this:

```sql
SELECT * FROM users WHERE email = 'adalovelace@example.com';
```

The EQL equivalent of this query is:

```sql
SELECT * FROM users WHERE cs_unique_v2(email_encrypted) = cs_unique_v2(
  '{"v":2,"k":"pt","p":"adalovelace@example.com","i":{"t":"users","c":"email_encrypted"},"q":"unique"}'
  );
```

This query returns:

| id  | email_encrypted                                                                                 |
| --- | ----------------------------------------------------------------------------------------------- |
| 1   | {"k":"pt","p":"adalovelace@example.com","i":{"t":"users","c":"email_encrypted"},"v":2,"q":null} |

#### Order by query

Prerequsites:

- An [ore index](#adding-indexes) is needed on the encrypted column to support this operation.

EQL function to use: `ore_block_u64_8_256(val JSONB)`.

A plaintext query order by email looks like this:

```sql
SELECT * FROM users ORDER BY email ASC;
```

The EQL equivalent of this query is:

```sql
SELECT * FROM users ORDER BY ore_block_u64_8_256(email_encrypted) ASC;
```

This query returns:

| id  | email_encrypted                                                                                 |
| --- | ----------------------------------------------------------------------------------------------- |
| 1   | {"k":"pt","p":"adalovelace@example.com","i":{"t":"users","c":"email_encrypted"},"v":2,"q":null} |
| 3   | {"k":"pt","p":"edithclarke@email.com","i":{"t":"users","c":"email_encrypted"},"v":2,"q":null}   |
| 2   | {"k":"pt","p":"gracehopper@test.com","i":{"t":"users","c":"email_encrypted"},"v":2,"q":null}    |
| 4   | {"k":"pt","p":"test@test.com","i":{"t":"users","c":"email_encrypted"},"v":2,"q":null}           |

#### Comparison query

Prerequsites:

- A [unique index](#adding-indexes) is needed on the encrypted column to support this operation.

EQL function to use: `ore_block_u64_8_256(val JSONB)`.

EQL query payload for a comparison query:

```json
{
  "k": "pt",
  "p": "gracehopper@test.com", // The text we want to use for the equality query
  "i": {
    "t": "users",
    "c": "email_encrypted"
  },
  "v": 2,
  "q": "ore" // This field is required on queries. This specifies the type of query we are executing.
}
```

A plaintext text query to compare email values looks like this:

```sql
SELECT * FROM users WHERE email > 'gracehopper@test.com';
```

The EQL equivalent of this query is:

```sql
SELECT * FROM users WHERE ore_block_u64_8_256(email_encrypted) > ore_block_u64_8_256(
  '{"v":2,"k":"pt","p":"gracehopper@test.com","i":{"t":"users","c":"email_encrypted"},"q":"ore"}'
  );
```

This query returns:

| id  | email_encrypted                                                                       |
| --- | ------------------------------------------------------------------------------------- |
| 4   | {"k":"pt","p":"test@test.com","i":{"t":"users","c":"email_encrypted"},"v":2,"q":null} |

#### Summary

This tutorial showed how we can go from a plaintext text field to an encrypted field and how to query the encrypted fields.

We have some [examples here](../../README.md#helper-packages) of what this would look like if you are using an ORM.

---

### Didn't find what you wanted?

[Click here to let us know what was missing from our docs.](https://github.com/cipherstash/encrypt-query-language/issues/new?template=docs-feedback.yml&title=[Docs:]%20Feedback%20on%20GETTINGSTARTED.md)
