# Encrypt Query Language (EQL)

[![Test EQL](https://github.com/cipherstash/encrypt-query-language/actions/workflows/test-eql.yml/badge.svg?branch=main)](https://github.com/cipherstash/encrypt-query-language/actions/workflows/test-eql.yml)
[![Release EQL](https://github.com/cipherstash/encrypt-query-language/actions/workflows/release-eql.yml/badge.svg?branch=main)](https://github.com/cipherstash/encrypt-query-language/actions/workflows/release-eql.yml)

Encrypt Query Language (EQL) is a set of abstractions for transmitting, storing, and interacting with encrypted data and indexes in PostgreSQL.

> [!TIP] > 
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
- [Developing](#developing)

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

### dbdev

> [!WARNING]
> The version released on dbdev may not be in sync with the version released on GitHub until we automate the publishing process.

You can find the EQL extension on [dbdev's extension catalog](https://database.dev/cipherstash/eql) with instructions on how to install it.

## Getting started

Once the custom types and functions are installed in your PostgreSQL database, you can start using EQL in your queries.

### Enable encrypted columns

Define encrypted columns using the `eql_v2_encrypted` type, which stores encrypted data as `jsonb` with additional constraints to ensure data integrity.

**Example:**

```sql
CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    encrypted_email eql_v2_encrypted
);
```

## Encrypt configuration

In order to enable searchable encryption, you will need to configure your CipehrStash integration appropriately.

- If you are using [CipherStash Proxy](https://github.com/cipherstash/proxy), see [this guide](docs/tutorials/proxy-configuration.md).
- If you are using [Protect.js](https://github.com/cipherstash/protectjs), use the [Protect.js schema](https://github.com/cipherstash/protectjs/blob/main/docs/reference/schema.md).

## CipherStash integrations using EQL

These frameworks use EQL to enable searchable encryption functionality in PostgreSQL.

| Framework   | Repo                                       |
| ----------- | ------------------------------------------ |
| Protect.js  | [Protect.js](https://github.com/cipherstash/protectjs) |
| Protect.php | [Protect.php](https://github.com/cipherstash/protectphp) |
| CipherStash Proxy | [CipherStash Proxy](https://github.com/cipherstash/proxy) |

## Developing

See the [development guide](./DEVELOPMENT.md).
