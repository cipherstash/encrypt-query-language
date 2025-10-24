# Encrypt Query Language (EQL)

[![Test EQL](https://github.com/cipherstash/encrypt-query-language/actions/workflows/test-eql.yml/badge.svg?branch=main)](https://github.com/cipherstash/encrypt-query-language/actions/workflows/test-eql.yml)
[![Release EQL](https://github.com/cipherstash/encrypt-query-language/actions/workflows/release-eql.yml/badge.svg?branch=main)](https://github.com/cipherstash/encrypt-query-language/actions/workflows/release-eql.yml)

Encrypt Query Language (EQL) is a set of abstractions for transmitting, storing, and interacting with encrypted data and indexes in PostgreSQL.

> [!TIP]
> **New to EQL?**
> EQL is the basis for searchable encryption functionality when using [Protect.js](https://github.com/cipherstash/protectjs) and/or [CipherStash Proxy](https://github.com/cipherstash/proxy).

Store encrypted data alongside your existing data:

- Encrypted data is stored using a `jsonb` column type
- Query encrypted data with specialized SQL functions (equality, range, full-text, etc.)
- Index encrypted columns to enable searchable encryption

## Table of Contents

- [Installation](#installation)
  - [dbdev](#dbdev)
- [Getting started](#getting-started)
  - [Enable encrypted columns](#enable-encrypted-columns)
- [Encrypt configuration](#encrypt-configuration)
- [CipherStash integrations using EQL](#cipherstash-integrations-using-eql)
- [Versioning](#versioning)
  - [Upgrading](#upgrading)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## Installation

The simplest way to get up and running with EQL is to execute the install SQL file directly in your PostgreSQL database.

1. Download the latest EQL install script:

   ```sh
   curl -sLo cipherstash-encrypt.sql https://github.com/cipherstash/encrypt-query-language/releases/latest/download/cipherstash-encrypt.sql
   ```

2. Run this command to install the custom types and functions:

   ```sh
   psql -f cipherstash-encrypt.sql
   ```


## EQL Components

EQL installs and manages the following components

| Name                               | Entity Type
| ---------------------------------- | --------------- |
| eql_v2.*                           | Schema          |
| public.eql_v2_encrypted            | Type            |
| public.eql_v2_configuration_state  | Type            |
| public.eql_v2_configuration        | Table           |


### `eql_v2` Schema

The `eql_v2` schema holds all of the functions, types and operators required to query and interact with encrypted data.
The schema is stateless and the schema can be dropped without risk of data loss.

Updating EQL will drop and re-create the schema.
Unless otherwise documented this is a safe operation that requires no data migration or changes.


### Configuration Table & Type

The `public.eql_v2_configuration` table holds the searchable encryption configuration.
The `public.eql_v2_configuration_state` type is used by the configuration table.

The table and associated type are created in the `public` schema to avoid any risk of data loss when updating or uninstalling EQL.

EQL updates will automatically migrate the configuration if the internal structure changes.

On uninstall the configuration table is renamed with a timestamp suffix
The table is not automatically dropped to avoid any potential risk of data loss.

Renaming avoids potential conflicts in CI pipelines that may repeatedly install and uninstall EQL.


### `public.eql_v2_encrypted` Type

The `public.eql_v2_encrypted` is the type used to define encrypted columns, and is used in customer table definitions.
The type is created in the `public` schema to avoid any risk of data loss when updating or uninstalling EQL.

Dropping the `public.eql_v2_encrypted` type will remove any associated columns from the database.

Uninstalling EQL will not drop the `public.eql_v2_encrypted` type to avoid risk of data loss.


## Database Permissions

EQL requires specific database privileges to install and operate correctly. The permissions needed depend on your deployment pattern.

### Default Permissions (Recommended)

For most use cases, grant the following permissions to the database user that will install and use EQL:

```sql
-- Database-level permissions
GRANT CREATE ON DATABASE your_database TO your_eql_user;

-- Schema permissions  
GRANT USAGE ON SCHEMA public TO your_eql_user;
GRANT CREATE ON SCHEMA public TO your_eql_user;

-- Configuration table permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.eql_v2_configuration TO your_eql_user;

-- User table permissions (for encrypted column constraints)
GRANT ALTER ON ALL TABLES IN SCHEMA public TO your_eql_user;
-- Or grant ALTER on specific tables that will have encrypted columns:
-- GRANT ALTER ON TABLE your_table TO your_eql_user;
```

**Why these permissions are needed:**

- **CREATE ON DATABASE**: Required to create the `eql_v2` schema, types, and functions during installation
- **CREATE ON SCHEMA public**: Required to create types and tables in the public schema
- **Configuration table access**: EQL manages searchable encryption configuration in `public.eql_v2_configuration`
- **ALTER on user tables**: EQL adds check constraints to encrypted columns for data validation

### Splitting Read and Write Access

A common production pattern separates setup/migration permissions from runtime permissions:

#### Setup/Migration User (Write Access)

Use during database migrations and EQL installation:

```sql
-- All default permissions above, plus:
GRANT CREATE ON DATABASE your_database TO your_migration_user;
GRANT CREATE ON SCHEMA public TO your_migration_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.eql_v2_configuration TO your_migration_user;
GRANT ALTER ON ALL TABLES IN SCHEMA public TO your_migration_user;
```

#### Runtime User (Read Access)

Use for application queries in production:

```sql
-- Configuration read access
GRANT SELECT ON TABLE public.eql_v2_configuration TO your_app_user;

-- EQL schema usage
GRANT USAGE ON SCHEMA eql_v2 TO your_app_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA eql_v2 TO your_app_user;

-- User table access (normal application permissions)
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE your_tables TO your_app_user;
```

**Migration Workflow:**
1. Use the migration user to install EQL and configure encrypted columns
2. Use the runtime user for normal application operations
3. Configuration changes (adding/removing encrypted columns) require the migration user


### dbdev

> [!WARNING]
> The version released on dbdev may not be in sync with the version released on GitHub until we automate the publishing process.

You can find the EQL extension on [dbdev's extension catalog](https://database.dev/cipherstash/eql) with instructions on how to install it.

## Getting started

Once EQL is installed in your PostgreSQL database, you can start using encrypted columns in your tables.

### Enable encrypted columns

Define encrypted columns using the `eql_v2_encrypted` type, which stores encrypted data as `jsonb` with additional constraints to ensure data integrity.

**Example:**

```sql
-- Step 1: Create a table with an encrypted column
CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    encrypted_email eql_v2_encrypted
);

-- Step 2: Configure the column for encryption/decryption
SELECT eql_v2.add_column('users', 'encrypted_email', 'text');

-- Step 3: (Optional) Add search indexes
SELECT eql_v2.add_search_config('users', 'encrypted_email', 'unique', 'text');
```

> [!NOTE]
> You must use [CipherStash Proxy](https://github.com/cipherstash/proxy) or [Protect.js](https://github.com/cipherstash/protectjs) to encrypt and decrypt data. EQL provides the database functions and types, while these tools handle the actual cryptographic operations.

## Encrypt configuration

In order to enable searchable encryption, you will need to configure your CipherStash integration appropriately.

- If you are using [CipherStash Proxy](https://github.com/cipherstash/proxy), see [this guide](docs/tutorials/proxy-configuration.md).
- If you are using [Protect.js](https://github.com/cipherstash/protectjs), use the [Protect.js schema](https://github.com/cipherstash/protectjs/blob/main/docs/reference/schema.md).

## CipherStash integrations using EQL

These frameworks use EQL to enable searchable encryption functionality in PostgreSQL.

| Framework   | Repo                                       |
| ----------- | ------------------------------------------ |
| Protect.js  | [Protect.js](https://github.com/cipherstash/protectjs) |
| Protect.php | [Protect.php](https://github.com/cipherstash/protectphp) |
| CipherStash Proxy | [CipherStash Proxy](https://github.com/cipherstash/proxy) |

## Versioning

You can find the version of EQL installed in your database by running the following query:

```sql
SELECT eql_v2.version();
```

### Upgrading

To upgrade to the latest version of EQL, you can simply run the install script again.

1. Download the latest EQL install script:

   ```sh
   curl -sLo cipherstash-encrypt.sql https://github.com/cipherstash/encrypt-query-language/releases/latest/download/cipherstash-encrypt.sql
   ```

2. Run this command to install the custom types and functions:

   ```sh
   psql -f cipherstash-encrypt.sql
   ```

> [!NOTE]
> The install script will not remove any existing configurations, so you can safely run it multiple times.

#### Using dbdev?

Follow the instructions in the [dbdev documentation](https://database.dev/cipherstash/eql) to upgrade the extension to your desired version.

## Troubleshooting

### Common Errors

**Error: "Some pending columns do not have an encrypted target"**
- **Cause**: Trying to configure a column that doesn't exist as `eql_v2_encrypted` type
- **Solution**: First create the column: `ALTER TABLE table_name ADD COLUMN column_name eql_v2_encrypted;`

**Error: "Config exists for column: table_name column_name"**
- **Cause**: Attempting to add a column configuration that already exists
- **Solution**: Use `eql_v2.add_search_config()` to add indexes, or `eql_v2.remove_column()` first to reconfigure

**Error: "No configuration exists for column: table_name column_name"**
- **Cause**: Trying to add search configuration before configuring the column
- **Solution**: Run `eql_v2.add_column()` first, then add search indexes

### Getting Help

- Check the [full documentation](./docs/README.md)
- Review [CipherStash Proxy configuration guide](./docs/tutorials/proxy-configuration.md)
- Report issues at [https://github.com/cipherstash/encrypt-query-language/issues](https://github.com/cipherstash/encrypt-query-language/issues)

## Contributing

See the [development guide](./DEVELOPMENT.md) for information on developing and extending EQL.

## Test Coverage Tracking

During SQL→SQLx test migration, track coverage with:

```bash
./tools/check-test-coverage.sh
```

This generates:
- Test inventory (which tests ported)
- Assertion count comparison
- Function call coverage comparison

See `docs/test-inventory.md` and `docs/assertion-counts.md` for details.
