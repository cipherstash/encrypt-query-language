# EQL documentation

This directory contains the documentation for the Encrypt Query Language (EQL).

## About

- [Postgres data security with CipherStash](concepts/WHY.md)

## Reference

- [EQL Functions Reference](reference/eql-functions.md) - Complete API reference for all EQL functions
- [SQL support matrix](reference/sql-support.md) - Which SQL operators and features each encrypted index enables
- [Database Indexes for Encrypted Columns](reference/database-indexes.md) - PostgreSQL B-tree index creation and usage
- [Writing fast queries against EQL columns](reference/query-performance.md) - Performance overview (points to Database Indexes)
- [Adding a Scalar Encrypted-Domain Type](reference/adding-a-scalar-encrypted-domain-type.md) - How the `eql_v3.<T>` domain families are generated
- [EQL with JSON and JSONB](reference/json-support.md)
- [EQL payload / wire format](../crates/eql-bindings/README.md) - Canonical wire types for the encrypted payload (envelope `v`/`i`/`c` and the `hm`/`ob`/`bf` index terms)
- [Client-side index configuration](https://github.com/cipherstash/protectjs/blob/main/docs/reference/schema.md) - Configuring searchable encryption in Protect.js / CipherStash Proxy

## Tutorials

- [CipherStash Proxy Configuration with EQL functions](tutorials/proxy-configuration.md)
