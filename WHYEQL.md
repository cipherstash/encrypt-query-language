# Postgres data security with CipherStash

This article gives a high-level overview of CipherStash's encryption in use solution, including the CipherStash Proxy and the Encrypt Query Language (EQL).

It is designed for developers and engineers who need to implement robust data security in PostgreSQL without sacrificing performance or usability.

## Table of Contents

1. [Encryption in use](#encryption-in-use)
   - [What is encryption in use?](#what-is-encryption-in-use)
   - [Why use encryption in use?](#why-use-encryption-in-use)
2. [CipherStash Proxy](#cipherstash-proxy)
   - [Proxy overview](#proxy-overview)
   - [How it works](#how-it-works)
3. [Encrypt Query Language (EQL)](#encrypt-query-language-eql)
4. [Best practices](#best-practices)
5. [Advanced topics](#advanced-topics)
   - [Integrating without proxy](#integrating-without-proxy)
6. [Conclusion](#conclusion)

## Encryption in use

EQL enables encryption in use, without significant changes to your application code.
A variety of searchable encryption techniques are available, including:

- **Matching** - Equality or partial matches
- **Ordering** - comparison operations using order revealing encryption
- **Uniqueness** - enforcing unique constraints
- **Containment** - containment queries using structured encryption

### What is encryption in use?

Encryption in use is the practice of keeping data encrypted even while it's being processed or queried in the database. 
Unlike traditional encryption methods that secure data only at rest (on disk) or in transit (over the network), encryption in use keeps the data encrypted while operations are being performed on the data.
This provides an additional layer of security against unauthorized access — an adversary needs access to the encrypted data _and_ encryption keys. 

### Why use encryption in use?

While encryption at rest and in transit are essential, they don't protect data when the database server itself is compromised. 
Encryption in use mitigates this risk by ensuring that:

- **Data remains secure**: Even if the database server is breached, the data remains encrypted and unreadable without the proper keys.
- **Compliance controls are stronger**: When you need stronger data security controls than what SOC2/SOC3 or ISO27001 mandate, encryption in use helps you meet those stringent requirements.

## CipherStash Proxy

### Proxy overview

CipherStash Proxy is a transparent proxy that sits between your application and your PostgreSQL database.
It intercepts SQL queries and handles the encryption and decryption of data on-the-fly.
This enables encryption in use without significant changes to your application code.

### How it works

- **Intercepts queries**: CipherStash Proxy captures SQL statements from the client application.
- **Encrypts data**: For write operations, it encrypts the plaintext data before sending it to the database.
- **Decrypts data**: For read operations, it decrypts the encrypted data retrieved from the database before returning it to the client.
- **Maintains searchability**: Ensures that the encrypted data is searchable and retrievable without sacrificing performance or application functionality.
- **Manages encryption keys**: Securely handles encryption keys required for encrypting and decrypting data.

## Encrypt Query Language (EQL)

Encrypt Query Language (EQL) is a set of PostgreSQL functions and data types provided by CipherStash to work with encrypted data and indexes.
EQL allows you to perform queries on encrypted data without decrypting it, supporting operations like equality checks, range queries, and unique constraints.

To get started, see the root [README.md](https://github.com/cipherstash/encrypt-query-language?tab=readme-ov-file#getting-started) file.

## Best Practices

- **Leverage CipherStash Proxy**: Use CipherStash Proxy to handle encryption/decryption transparently.
- **Utilize EQL functions**: Always use EQL functions when interacting with encrypted data.
- **Define constraints**: Apply database constraints to maintain data integrity.
- **Secure key management**: Ensure encryption keys are securely managed and stored.
- **Monitor performance**: Keep an eye on query performance and optimize as needed.

## Advanced Topics

### Integrating without CipehrStash Proxy

> The SDK approach is currently in development, but if you're interested in contributing, please start a discussion [here](https://github.com/cipherstash/cipherstash).

For advanced users who prefer to handle encryption within their application:

- **SDKs available**: Use CipherStash SDKs (at the moment, Rust and TypeScript) to manage encryption/decryption.
- **Manual encryption**: Implement encryption logic in your application code.
- **Data conformity**: Ensure encrypted data matches the expected `jsonb` schema.
- **Key management**: Handle encryption keys securely within your application.

**Note**: This approach increases complexity and is recommended only if CipherStash Proxy does not meet specific requirements. 

## Conclusion

CipherStash's encryption in use solution, comprising CipherStash Proxy and EQL, provides a practical way to enhance data security in Postgres databases. 
By keeping data encrypted even during processing, you minimize the risk of data breaches and comply with stringent security standards without significant changes to your application logic.

To get started, see the root [README.md](https://github.com/cipherstash/encrypt-query-language?tab=readme-ov-file#getting-started) file.

**Contact Support:** For further assistance, raise an issue [here](https://github.com/cipherstash/encrypt-query-language/issues).
