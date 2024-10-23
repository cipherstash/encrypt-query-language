# CipherStash Migrator

The CipherStash Migrator is a tool that can be used to migrate plaintext data in a database to its encrypted equivalent.
It works inside the CipherStash Proxy Docker container and can handle different data types such as text, JSONB, integers, booleans, floats, and dates.
By specifying the relevant columns in your table, the migrator will seamlessly encrypt the existing data and store it in designated encrypted columns.

## Prerequisites

- [CipherStash Proxy](PROXY.md)
- [Have set up EQL in your database](GETTINGSTARTED.md)
  - Ensure that the columns where data will be migrated already exist.

Here’s a draft for the technical usage documentation for the CipherStash Migrator tool:

## Usage

The CipherStash Migrator allows you to specify key-value pairs where the key is the plaintext column, and the value is the corresponding encrypted column. Multiple key-value pairs can be specified, and the tool will perform a migration for each specified column.

### Running the migrator

You will need to SSH into the CipherStash Proxy Docker container to run the migrator.

```bash
docker exec -it eql-cipherstash-proxy bash
```

Once inside the container, you have access to the migrator tool.

```bash
cipherstash-migrator --version
```

#### Flags

| Flag | Description | Required |
| --- | --- | --- |
| `--columns` | Specifies the plaintext columns and their corresponding encrypted columns. The format is `plaintext_column=encrypted_column`. | Yes |
| `--table` | Specifies the table where the data will be migrated. | Yes |
| `--database-name` | Specifies the database name. | Yes |
| `--username` | Specifies the database username. | Yes |
| `--password` | Specifies the database password. | Yes |

#### Supported data types

- Text
- JSONB
- Integer
- Boolean
- Float
- Date

### Example

The following is an example of how to run the migrator with a single column:

```bash
cipherstash-migrator --columns example_column=example_column_encrypted --table examples --database-name postgres --username postgres --password postgres
```

If you require additional data types, please [raise an issue](https://github.com/cipherstash/encrypt-query-language/issues)

### Running migrations with multiple columns

To run a migration on multiple columns at once, specify multiple key-value pairs in the `--columns` option:

```bash
cipherstash-migrator --columns test_text=encrypted_text test_jsonb=encrypted_jsonb test_int=encrypted_int test_boolean=encrypted_boolean --table examples --database-name migrator_test --username postgres --password postgres
```

## Notes

- Ensure that the corresponding encrypted columns already exist in the table before running the migration.
- Data migration operations should be tested in a development environment before being executed in production.
