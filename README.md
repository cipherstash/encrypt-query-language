# Encrypt Query Language (EQL)

[![Test EQL](https://github.com/cipherstash/encrypt-query-language/actions/workflows/test-eql.yml/badge.svg?branch=main)](https://github.com/cipherstash/encrypt-query-language/actions/workflows/test-eql.yml)
[![Release EQL](https://github.com/cipherstash/encrypt-query-language/actions/workflows/release-eql.yml/badge.svg?event=release)](https://github.com/cipherstash/encrypt-query-language/actions/workflows/release-eql.yml)

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
  - [Local development (fastest)](#local-development-fastest)
  - [Install into an existing database](#install-into-an-existing-database)
  - [dbdev](#dbdev)
- [Getting started](#getting-started)
  - [Enable encrypted columns](#enable-encrypted-columns)
- [Encrypt configuration](#encrypt-configuration)
- [Performance](#performance)
- [Documentation](#documentation)
- [CipherStash integrations using EQL](#cipherstash-integrations-using-eql)
- [Versioning](#versioning)
  - [Upgrading](#upgrading)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## Installation

### Local development (fastest)

Run a Postgres image with EQL pre-installed:

```sh
docker run --rm -p 5432:5432 -e POSTGRES_PASSWORD=postgres \
  ghcr.io/cipherstash/postgres-eql:17
```

EQL is installed automatically on first boot. Pin a specific version with `:17-2.1.8`. Other PostgreSQL majors are available as `:14`, `:15`, `:16`. See [`docker/README.md`](./docker/README.md) for the full tag scheme and details.

### Install into an existing database

Execute the install SQL file directly:

1. Download the latest EQL install script:

   ```sh
   curl -sLo cipherstash-encrypt.sql https://github.com/cipherstash/encrypt-query-language/releases/latest/download/cipherstash-encrypt.sql
   ```

2. Run this command to install the custom types and functions:

   ```sh
   psql -f cipherstash-encrypt.sql
   ```


## EQL Components

EQL installs the following components into the `eql_v3` schema:

| Name                                                | Entity Type   | Purpose                                                              |
| --------------------------------------------------- | ------------- | ------------------------------------------------------------------- |
| `eql_v3`                                            | Schema        | Holds all EQL types, operators, functions, and aggregates           |
| `eql_v3.<T>`, `eql_v3.<T>_eq`, `eql_v3.<T>_ord`     | Domain types  | Per-scalar encrypted columns (one family per scalar: `int4`, `text`, `timestamptz`, …) |
| `eql_v3.json`                                       | Domain type   | Encrypted JSON (structured-encryption) documents                    |
| `eql_v3.eq_term` / `ord_term` / `match_term`        | Functions     | Index-term extractors for functional indexes                        |


### `eql_v3` Schema

The `eql_v3` schema holds the encrypted-domain types, their operators and term extractors, and the `MIN` / `MAX` aggregates.

Encrypted columns are typed as `eql_v3` domains (e.g. `eql_v3.text_eq`, `eql_v3.json`), and the searchable surface available on a column is fixed by its domain **variant** — there is no database-side configuration state. Which index terms a value carries is decided by the encryption client (Protect.js / CipherStash Proxy).

Because the domain types live in the `eql_v3` schema, columns depend on them; `DROP SCHEMA eql_v3 CASCADE` removes the surface (and would drop columns typed as those domains). Re-running the install script is idempotent.


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

-- User table permissions (for encrypted column constraints)
GRANT ALTER ON ALL TABLES IN SCHEMA public TO your_eql_user;
-- Or grant ALTER on specific tables that will have encrypted columns:
-- GRANT ALTER ON TABLE your_table TO your_eql_user;
```

**Why these permissions are needed:**

- **CREATE ON DATABASE**: Required to create the `eql_v3` schema, domain types, and functions during installation
- **CREATE ON SCHEMA public**: Required to add encrypted columns (typed as `eql_v3` domains) to tables in the public schema
- **ALTER on user tables**: encrypted-domain `CHECK` constraints are validated on the user tables

### Splitting Read and Write Access

A common production pattern separates setup/migration permissions from runtime permissions:

#### Setup/Migration User (Write Access)

Use during database migrations and EQL installation:

```sql
-- All default permissions above, plus:
GRANT CREATE ON DATABASE your_database TO your_migration_user;
GRANT CREATE ON SCHEMA public TO your_migration_user;
GRANT ALTER ON ALL TABLES IN SCHEMA public TO your_migration_user;
```

#### Runtime User (Read Access)

Use for application queries in production:

```sql
-- EQL schema usage (resolves the encrypted operators / extractors)
GRANT USAGE ON SCHEMA eql_v3 TO your_app_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA eql_v3 TO your_app_user;

-- User table access (normal application permissions)
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE your_tables TO your_app_user;
```

**Migration Workflow:**
1. Use the migration user to install EQL and add encrypted columns
2. Use the runtime user for normal application operations
3. Schema changes (adding/removing encrypted columns) require the migration user


### dbdev

> [!WARNING]
> The version released on dbdev may not be in sync with the version released on GitHub until we automate the publishing process.

You can find the EQL extension on [dbdev's extension catalog](https://database.dev/cipherstash/eql) with instructions on how to install it.

## Getting started

Once EQL is installed in your PostgreSQL database, you can start using encrypted columns in your tables.

### Enable encrypted columns

Define encrypted columns using an `eql_v3` domain type. Type the column as the **variant** for the capability you need — `eql_v3.text_eq` for equality, `eql_v3.<T>_ord` for range/ordering, `eql_v3.text_match` for full-text, `eql_v3.json` for encrypted JSON. Each is stored as `jsonb` with a `CHECK` constraint that validates the encrypted payload.

**Example:**

```sql
-- Step 1: Create a table with an equality-searchable encrypted column
CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    encrypted_email eql_v3.text_eq
);

-- Step 2: Add a functional index on the term extractor (engages bare-form queries)
CREATE INDEX users_email_eq ON users USING hash (eql_v3.eq_term(encrypted_email));
```

See the [SQL support matrix](docs/reference/sql-support.md) for every variant and [Database Indexes](docs/reference/database-indexes.md) for the index recipes.

> [!NOTE]
> You must use [CipherStash Proxy](https://github.com/cipherstash/proxy) or [Protect.js](https://github.com/cipherstash/protectjs) to encrypt and decrypt data. EQL provides the database functions and types, while these tools handle the actual cryptographic operations.

## Encrypt configuration

In order to enable searchable encryption, you will need to configure your CipherStash integration appropriately.

- If you are using [CipherStash Proxy](https://github.com/cipherstash/proxy), see [this guide](docs/tutorials/proxy-configuration.md).
- If you are using [Protect.js](https://github.com/cipherstash/protectjs), use the [Protect.js schema](https://github.com/cipherstash/protectjs/blob/main/docs/reference/schema.md).

## Performance

Query latency for searchable-encryption operations stays low across data set sizes. The numbers below are query-only medians (no decryption) from a full benchmark run against EQL 2.3 on PostgreSQL 17, across four row-count tiers.

| Family | Scenario | 10k | 100k | 1M | 10M |
|---|---|--:|--:|--:|--:|
| **JSON** | contains/functional | 0.66 ms | 0.65 ms | 0.68 ms | 6.8 ms |
| JSON | field_eq/functional | 0.98 ms | 0.98 ms | 0.90 ms | 0.92 ms |
| JSON | field_order/functional | 0.74 ms | 0.77 ms | 0.77 ms | 0.84 ms |
| **ORE** | range_gt_100 | 4.1 ms | 6.7 ms | 6.9 ms | 8.1 ms |
| ORE | range_lt_hybrid_ordered_10 | — | 1.1 ms | 1.2 ms | 1.2 ms |
| **EXACT** | eql_hash | 0.43 ms | 0.44 ms | 0.43 ms | 0.46 ms |
| **MATCH** | eql_bloom | 1.0 ms | 2.5 ms | 18 ms | 216 ms |
| **GROUP_BY** | low_cardinality — encrypted | 2.7 ms | 28 ms | 179 ms | 1.47 s |
| GROUP_BY | low_cardinality — plaintext baseline | 1.5 ms | 9.9 ms | 36 ms | 430 ms |
| **COMBO** | top_n_filtered_group_by | 0.84 ms | 1.1 ms | 5.5 ms | 43 ms |

Full methodology, per-scenario SQL, planner index choices, and EXPLAIN plans are in the [`cipherstash/benches`](https://github.com/cipherstash/benches) repository.

## Documentation

### API Documentation

All EQL functions and types are fully documented with Doxygen-style comments in the source code.

**Install Doxygen** (required for documentation generation):

```bash
# macOS
brew install doxygen

# Ubuntu/Debian
apt-get install doxygen

# Other platforms: https://www.doxygen.nl/download.html
```

**Generate API documentation:**

```bash
# Using mise
mise run docs:generate

# Or directly with doxygen
doxygen Doxyfile
```

The generated HTML documentation will be available at `docs/api/html/index.html`.

### Documentation Standards

All SQL functions, types, and operators include:
- **@brief** - Short description of purpose
- **@param** - Parameter descriptions with types
- **@return** - Return value description and type
- **@example** - Usage examples
- **@throws** - Exception conditions
- **@note** - Important notes and caveats

For contribution guidelines, see [CLAUDE.md](./CLAUDE.md).

### Validation Tools

Verify documentation quality using these scripts:

```bash
# Using mise (validates coverage and tags)
mise run docs:validate

# Or run individual checks
./tasks/check-doc-coverage.sh      # Check 100% coverage
./tasks/validate-required-tags.sh  # Validate @brief, @param, @return
./tasks/validate-documented-sql.sh # Validate SQL syntax
```

Documentation validation runs automatically in CI for all pull requests.

## CipherStash integrations using EQL

These frameworks use EQL to enable searchable encryption functionality in PostgreSQL.

| Framework   | Repo                                       |
| ----------- | ------------------------------------------ |
| Protect.js  | [Protect.js](https://github.com/cipherstash/protectjs) |
| Protect.php | [Protect.php](https://github.com/cipherstash/protectphp) |
| CipherStash Proxy | [CipherStash Proxy](https://github.com/cipherstash/proxy) |

## Versioning

EQL is distributed as a versioned install script (`cipherstash-encrypt.sql`) published with each [GitHub release](https://github.com/cipherstash/encrypt-query-language/releases). Track the release tag you installed; re-running the install script is idempotent and upgrades the `eql_v3` surface in place.

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

**A query returns no rows / silently runs native `jsonb` semantics**
- **Cause**: the query operand was an untyped literal, so PostgreSQL flattened the `eql_v3` domain to its `jsonb` base type and resolved the native operator
- **Solution**: type the operand — `WHERE col = $1::eql_v3.text_eq` (CipherStash Proxy supplies typed parameters automatically)

**Error: "operator not supported" (raised)**
- **Cause**: the operator is blocked for the column's domain variant (e.g. `<` on an `_eq` column, or `LIKE` on any encrypted column)
- **Solution**: type the column as a variant that carries the required term (see the [SQL support matrix](docs/reference/sql-support.md)); use `@>` rather than `LIKE` for text match

**`=` returns no rows on a populated column**
- **Cause**: the column's values do not carry an `hm` equality term
- **Solution**: confirm the encryption client is configured to emit the equality term for the column's variant, and that data was written after configuring it

### Getting Help

- Check the [full documentation](./docs/README.md)
- Review [CipherStash Proxy configuration guide](./docs/tutorials/proxy-configuration.md)
- Report issues at [https://github.com/cipherstash/encrypt-query-language/issues](https://github.com/cipherstash/encrypt-query-language/issues)

## Contributing

See the [development guide](./DEVELOPMENT.md) for information on developing and extending EQL.
