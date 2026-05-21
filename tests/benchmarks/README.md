# Benchmark Utilities

This directory contains the Dockerized support stack for generating a 100K-row
encrypted benchmark dataset through CipherStash Proxy.

The committed automated benchmark coverage lives in the SQLx bench/regression
suite (`mise run test:bench`). `mise run bench:full` is a convenience wrapper
around that existing suite; it does not consume the 100K Docker dataset.

## Local usage

```bash
# Populate credentials for the Dockerized Proxy
cp tests/benchmarks/.env.example tests/benchmarks/.env
# Edit .env with your CipherStash credentials

# Start bench-postgres + bench-proxy and wait for host-side readiness checks
mise run bench:up

# Build EQL and generate the 100K encrypted dataset in bench-postgres
mise run bench:generate

# Run the committed SQLx bench/regression suite (10K fixture-based)
mise run bench:full

# Tear down the Dockerized benchmark stack when finished
mise run bench:down
```

## What each task does

- `bench:up` starts `bench-postgres` and `bench-proxy`, then probes them from
  the host with `psql`.
- `bench:generate` installs the built EQL SQL into `bench-postgres`, applies
  `schema.sql`, and inserts 100K plaintext rows through Proxy on `localhost:6433`.
- `bench:full` delegates to `mise run test:bench`, which runs the committed
  SQLx benchmark/regression suite against the normal local test database.
