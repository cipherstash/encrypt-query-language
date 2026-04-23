# EQL Scheduled Benchmarks (Tier 2)

Heavy-weight performance benchmarks that run weekly in CI against 100K-row
encrypted datasets. Complements the Tier 1 tests in `tests/sqlx/tests/bench_*`.

## What this is

- Brings up Postgres + CipherStash Proxy via docker-compose
- Inserts 100K plaintext rows through the Proxy (which encrypts them)
- Runs each P0/P1/P2 query pattern 1000 times
- Reads `pg_stat_statements` for statistical aggregates
- Outputs JSON + Markdown reports

## Local usage

```bash
# Populate credentials
cp tests/benchmarks/.env.example tests/benchmarks/.env
# Edit .env with your CipherStash credentials

# Start Postgres + Proxy
mise run bench:up

# Build EQL and generate 100K dataset (bench:generate depends on build)
mise run bench:generate

# Run the full Tier 2 suite
mise run bench:full

# Results land in tests/benchmarks/reports/
```

## CI usage

Runs automatically every Monday at 03:00 UTC via
`.github/workflows/benchmark.yml`. Also manually invocable from the
GitHub Actions UI (Run workflow button).

## Why a separate workflow

- 100K generation takes ~100 seconds via the Proxy
- 1000-run query loops add several minutes per pattern
- Regular PR CI must stay under 10 minutes; this suite would blow that budget

## Output

`tests/benchmarks/reports/benchmark-YYYY-MM-DD.{json,md}` — uploaded as
GitHub Actions artifact named `benchmark-report-<run-id>`.
