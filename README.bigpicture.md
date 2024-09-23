# Postgres data security with CipherStash

## Introduction

This reference guide provides a comprehensive overview of CipherStash's encryption in use solution, including the CipherStash Proxy and the Encrypt Query Language (EQL). 
It is designed for developers and engineers who need to implement robust data security in PostgreSQL without sacrificing performance or usability.

## Table of Contents

1. [Encryption in use](#1-encryption-in-use)
   - [1.1 What is encryption in use?](#11-what-is-encryption-in-use)
   - [1.2 Why use encryption in use?](#12-why-use-encryption-in-use)
2. [CipherStash Proxy](#2-cipherstash-proxy)
   - [2.1 Overview](#21-overview)
   - [2.2 How it works](#22-how-it-works)
   - [2.3 Setup and configuration](#23-setup-and-configuration)
3. [Encrypt Query Language (EQL)](#3-encrypt-query-language-eql)
   - [3.1 Overview](#31-overview)
   - [3.2 Key components](#32-key-components)
     - [3.2.1 Encrypted columns](#321-encrypted-columns)
     - [3.2.2 EQL functions](#322-eql-functions)
     - [3.2.3 Data format](#323-data-format)
   - [3.3 Using EQL](#33-using-eql)
     - [3.3.1 Write operations](#331-write-operations)
     - [3.3.2 Read operations](#332-read-operations)
4. [Best practices](#4-best-practices)
5. [Advanced topics](#5-advanced-topics)
   - [5.1 Integrating without proxy](#51-integrating-without-proxy)
6. [Conclusion](#6-conclusion)

## 1. Encryption in use

### 1.1 What is encryption in use?

Encryption in use refers to the practice of keeping data encrypted even while it's being processed or queried in the database. 
Unlike traditional encryption methods that secure data only at rest (on disk) or in transit (over the network), encryption in use ensures that data remains encrypted during computation, providing an additional layer of security against unauthorized access.

### 1.2 Why use encryption in use?

While encryption at rest and in transit are essential, they don't protect data when the database server itself is compromised. 
Encryption in use mitigates this risk by ensuring that:

- **Data remains secure**: Even if the database server is breached, the data remains encrypted and unreadable without the proper keys.
- **Compliance requirements**: Helps meet stringent regulatory requirements for data protection and privacy.
- **Enhanced security posture**: Reduces the attack surface and potential impact of data breaches.

## 2. CipherStash Proxy

### 2.1 Overview

CipherStash Proxy is a transparent proxy that sits between your application and your Postgres database.
It intercepts SQL queries and handles the encryption and decryption of data on-the-fly, enabling encryption in use without significant changes to your application code.

### 2.2 How it works

- **Intercepts queries**: CipherStash Proxy captures SQL statements from the client application.
- **Encrypts data**: For write operations, it encrypts the plaintext data before sending it to the database.
- **Decrypts data**: For read operations, it decrypts the encrypted data retrieved from the database before returning it to the client.
- **Maintains searchability**: Ensures that the encrypted data is searchable and retrievable without sacrificing performance or application functionality.
- **Manages encryption keys**: Securely handles encryption keys required for encrypting and decrypting data.

### 2.3 Setup and configuration

1. **Getting started**: Follow the official [Getting Started guide](https://cipherstash.com/docs/getting-started/cipherstash-proxy) to install and configure CipherStash Proxy.
3. **Application Modification**: Update your application's database connection string to point to the Proxy instead of the database directly.

**Example connection string update:**

```plaintext
Original: postgresql://user:password@postgres.host:5432/mydb
Updated:  postgresql://user:password@cipherstash-proxy.host:6432/mydb
```

## 3. Encrypt Query Language (EQL)

### 3.1 Overview

Encrypt Query Language (EQL) is a set of PostgreSQL functions and data types provided by CipherStash to facilitate working with encrypted data and indexes. 
EQL allows you to perform queries on encrypted data without decrypting it, supporting operations like equality checks, range queries, and unique constraints.

### 3.2 Key components

#### 3.2.1 Encrypted columns

Encrypted columns are defined using the `cs_encrypted_v1` domain type, which extends the `jsonb` type with additional constraints to ensure data integrity.

**Example table definition:**

```sql
CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name_encrypted cs_encrypted_v1
);
```

#### 3.2.2 EQL functions

EQL provides specialized functions to interact with encrypted data:

- **`cs_ciphertext_v1(val JSONB)`**: Extracts the ciphertext for decryption by CipherStash Proxy.
- **`cs_match_v1(val JSONB)`**: Retrieves the match index for equality comparisons.
- **`cs_unique_v1(val JSONB)`**: Retrieves the unique index for enforcing uniqueness.
- **`cs_ore_v1(val JSONB)`**: Retrieves the Order-Revealing Encryption index for range queries.

#### 3.2.3 Data Format

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

Please refer to the [EQL reference guide](https://cipherstash.com/docs/getting-started/cipherstash-encrypt) for more information on the `jsonb` schema.

### 3.3 Using EQL

#### 3.3.1 Write Operations

When inserting data:

1. **Application sends plaintext**: Wrap the plaintext in the appropriate JSON structure.

   ```sql
   INSERT INTO users (name_encrypted) VALUES ('{"p": "Alice"}');
   ```

2. **Proxy encrypts data**: CipherStash Proxy encrypts the plaintext before storing it in the database. 

#### 3.3.2 Read Operations

When querying data:

1. **Use EQL functions**: Wrap encrypted columns and query parameters with EQL functions.

   ```sql
   SELECT cs_ciphertext_v1(name_encrypted)
   FROM users
   WHERE cs_match_v1(name_encrypted) @> cs_match_v1('{"p": "Alice"}');
   ```

2. **Proxy decrypts data**: CipherStash Proxy decrypts the results before returning them to the application.

## 4. Best Practices

- **Leverage CipherStash Proxy**: Use CipherStash Proxy to handle encryption/decryption transparently.
- **Utilize EQL functions**: Always use EQL functions when interacting with encrypted data.
- **Define constraints**: Apply database constraints to maintain data integrity.
- **Secure key management**: Ensure encryption keys are securely managed and stored.
- **Monitor performance**: Keep an eye on query performance and optimize as needed.

## 5. Advanced Topics

### 5.1 Integrating without CipehrStash Proxy

> The SDK approach is currently in development, but if you're interested in contributing, please start a discussion [here](https://github.com/cipherstash/cipherstash).

For advanced users who prefer to handle encryption within their application:

- **SDKs available**: Use CipherStash SDKs (at the moment, Rust and TypeScript) to manage encryption/decryption.
- **Manual encryption**: Implement encryption logic in your application code.
- **Data conformity**: Ensure encrypted data matches the expected `jsonb` schema.
- **Key management**: Handle encryption keys securely within your application.

**Note**: This approach increases complexity and is recommended only if CipherStash Proxy does not meet specific requirements. 

## 6. Conclusion

CipherStash's encryption in use solution, comprising CipherStash Proxy and EQL, provides a practical way to enhance data security in Postgres databases. 
By keeping data encrypted even during processing, you minimize the risk of data breaches and comply with stringent security standards without significant changes to your application logic.

**Contact Support:** For further assistance, start a discussion [here](https://github.com/cipherstash/cipherstash).
