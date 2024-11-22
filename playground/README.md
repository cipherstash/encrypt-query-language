# EQL and CipherStash Proxy playground

This playground environment provides a simple setup to experiment with **CipherStash Proxy** and **EQL** in a Docker Compose environment. 
It includes a PostgreSQL database with EQL installed at build time and a CipherStash Proxy configured to integrate with your CipherStash account. 
This environment is ideal for running the examples in the repository or testing CipherStash features.

## Prerequisites

1. [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) installed.
2. A CipherStash account and access to the [CipherStash Dashboard](https://dashboard.cipherstash.com) to obtain required environment variables.
3. The [CipherStash CLI](https://cipherstash.com/docs/reference/cli) installed and configured with your account credentials.

New to CipherStash? [Sign up for a free account](https://cipherstash.com/signup) to get started.

## Services

- **Postgres**: A PostgreSQL database with EQL installed at build time.
- **Proxy**: The CipherStash Proxy service that encrypts/decrypts data and manages schema encryption.

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/cipherstash/encrypt-query-language.git
   cd encrypt-query-language/playground
   ```

2. Create a `.envrc` file with the following variables:
   ```env
   # CipherStash account credentials
   export CS_WORKSPACE_ID=your_workspace_id
   export CS_CLIENT_ACCESS_KEY=your_client_access_key

   # Encryption keys
   export CS_ENCRYPTION__CLIENT_ID=your_client_id
   export CS_ENCRYPTION__CLIENT_KEY=your_client_key
   export CS_ENCRYPTION__DATASET_ID=your_dataset_id

   # Optional overrides
   export PGPORT=5432
   export CS_PORT=6432
   ```

   These values are available in your [CipherStash Dashboard](https://dashboard.cipherstash.com).
   The [Client ID and Key](https://cipherstash.com/docs/how-to/creating-clients) and [Dataset ID](https://cipherstash.com/docs/how-to/creating-datasets) are created through the CipherStash CLI.

3. Build and run the environment:
   ```bash
   docker compose up --build
   ```

## Usage

### Connecting to PostgreSQL

The PostgreSQL service is exposed on `localhost:${PGPORT:-5432}`. You can connect using any PostgreSQL client:

```bash
psql -h localhost -p 5432 -U postgres
```

### Connecting to CipherStash Proxy

The CipherStash Proxy service is exposed on `localhost:${CS_PORT:-6432}`. Example connection string:

```text
postgresql://postgres:postgres@localhost:6432/postgres
```

or using `psql`:

```bash
psql -h localhost -p 6432 -U postgres
```

### Logs

- PostgreSQL logs all SQL statements (`log_statement=all`) for debugging purposes.
- CipherStash Proxy supports unsafe logging for development. Disable it in production by setting `CS_UNSAFE_LOGGING` to `false`.

### Examples

Use this playground to test any examples from the repository's [examples](../examples/) directory:

## Notes

- **Security warning**: Do not use this environment in production. It is designed for local development and testing purposes only.
- **EQL installation**: The `eql-playground-pg` container automatically installs EQL during the build process. If modifications are needed, update the Dockerfile in the `db` directory.

## Stopping the Environment

To stop and remove the containers:

```bash
docker compose down
```