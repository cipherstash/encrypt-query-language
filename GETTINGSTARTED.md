## Getting started

The following guide assumes you have the prerequisites installed and running, and are running the SQL statements through your CipherStash Proxy instance.

### Prerequisites

- [PostgreSQL 14+](https://www.postgresql.org/download/)
- [Cipherstash Proxy guide](https://github.com/cipherstash/encrypt-query-language/tree/main/PROXY.md)

EQL relies on [Cipherstash Proxy](https://cipherstash.com/docs/getting-started/cipherstash-proxy) for low-latency encryption & decryption.
We plan to support direct language integration in the future.

> This guide will use raw SQL statements to demonstrate how to use the EQL extension. See the `languages` directory for more information on using specific language specific ORMs.

### Installation

In order to use EQL, you must first install the EQL extension in your PostgreSQL database.
You can do this by running the following command, which will execute the SQL from the `src/install.sql` file:

Update the database credentials based on your environment.

```bash
psql -U postgres -d postgres -f src/install.sql
```

> Note: We also have direct language specific ORM support for installing the extension. See the `languages` directory for more information.

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

Some language specific ORMs don't support custom types, so EQL also supports `jsonb` rather than the `cs_encrypted_v1` domain type.

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

The returned value is a `json` object with the decrypted value located in the `p` field.

```json
{
  "v": 1,
  "k": "ct",
  "p": "test@test.com",
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
