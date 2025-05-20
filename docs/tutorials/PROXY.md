# CipherStash Proxy

The CipherStash Proxy is a lightweight proxy that can be used to encrypt and decrypt data in your database.

## Table of Contents

- [Getting Started](#getting-started)
- [Create a dataset and client](#create-a-dataset-and-client)
- [Configuring CipherStash Proxy](#configuring-cipherstash-proxy)
- [Running the Proxy](#running-the-proxy)
- [Using the Proxy](#using-the-proxy)
- [How EQL works with CipherStash Proxy](#how-eql-works-with-cipherstash-proxy)
  - [Writes](#writes)
  - [Reads](#reads)

## Getting Started

To get started, you'll need to sign up for a free account at [https://dashboard.cipherstash.com](https://dashboard.cipherstash.com).

Once you've signed up, you can create an access key from your default workspace.

## Create a dataset and client

Before you can start using the proxy, you'll need to create a dataset and client.

You can do this using the [CipherStash CLI](https://cipherstash.com/docs/reference/cli)

1. [Create a dataset.](https://cipherstash.com/docs/how-to/creating-datasets)
1. [Create a client key for cryptographic operations.](https://cipherstash.com/docs/how-to/creating-clients)

## Configuring CipherStash Proxy

You can then create a `cipherstash-proxy.toml` file in the root of this directory. You can use the `cipherstash-proxy.toml.example` file as a starting point.

Populate the following fields with your values:

- `workspace_id`: The ID of your workspace.
- `client_access_key`: The access key for your client.
- `client_id`: The ID of your client.`
- `client_key`: The key of your client.
- `database.name`: The name of your database.
- `database.username`: The username for your database.
- `database.password`: The password for your database.
- `database.host`: The host for your database.
- `database.port`: The port for your database.

## Running the Proxy

To run the proxy, you can use `docker compose` to start the proxy using the configuration in the `cipherstash-proxy.toml` file.
Run the following command from the `cipherstash-proxy` directory:

```bash
docker compose up
```

## Using the Proxy

Once the proxy is running, you can use the different language examples to test the proxy and EQL.

## How EQL works with CipherStash Proxy

EQL uses **CipherStash Proxy** to mediate access to your PostgreSQL database and provide low-latency encryption & decryption.

At a high level:

- encrypted data is stored as `jsonb`
- references to the column in sql statements are wrapped in a helper function
- Cipherstash Proxy transparently encrypts and indexes data

### Writes

1. Database client sends `plaintext` data encoded as `jsonb`
1. CipherStash Proxy encrypts the `plaintext` and encodes the `ciphertext` value and associated indexes into the `jsonb` payload
1. The data is written to the encrypted column

![Insert](/diagrams/overview-insert.drawio.svg)

### Reads

1. Wrap references to the encrypted column in the appropriate EQL function
1. CipherStash Proxy encrypts the `plaintext`
1. PostgreSQL executes the SQL statement
1. CipherStash Proxy decrypts any returned `ciphertext` data and returns to client

![Select](/diagrams/overview-select.drawio.svg)

---

### Didn't find what you wanted?

[Click here to let us know what was missing from our docs.](https://github.com/cipherstash/encrypt-query-language/issues/new?template=docs-feedback.yml&title=[Docs:]%20Feedback%20on%20PROXY.md)
