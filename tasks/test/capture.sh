#!/usr/bin/env bash
# Stage 2 capture driver: run the eql_v3 scalar matrix against the dedicated
# logging Postgres and harvest its stderr to target/log-capture/raw/<run-id>.log.
#
# Why a separate server: the GUCs (log_statement=all + auto_explain JSON) make
# every statement and every executed index/scale plan land in the container log,
# self-named by the inline /* eqlmatrix:<case_id> */ tag the matrix leaves emit.
# The default test server stays clean/fast.
#
# bash 3.2 compatible (macOS): no mapfile, no associative arrays.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

RUN_ID="${RUN_ID:-$(date +%Y%m%dT%H%M%S)}"
RAW_DIR="${REPO_ROOT}/target/log-capture/raw"
# Compress the harvest: a full scalars:: capture is multi-GB of auto_explain
# JSON plans, which gzip ~10-20x. The ledger CLI gunzips `.log.gz` transparently
# (see eql_codegen::ledger::open_log_reader).
RAW_LOG="${RAW_DIR}/${RUN_ID}.log.gz"
mkdir -p "$RAW_DIR"

# The logging server is published on host port 7433 (the container itself
# listens on the anchor's PGPORT; the host mapping is 7433:7432 — see
# tests/docker-compose.yml). Retarget the WHOLE prep+test chain at the host
# port for this run only via the non-shadowed EQL_POSTGRES_PORT override.
#
# Why not `export DATABASE_URL=…7433`: mise.toml defines DATABASE_URL (and
# POSTGRES_PORT) in its static [env], and mise's rendered [env] value WINS over
# a parent export — so an outer DATABASE_URL would be silently overwritten back
# to 7432 inside `mise run test:sqlx:prep`, running prep against the wrong
# server. EQL_POSTGRES_PORT is the non-shadowed override [env] reads (mise.toml
# templates POSTGRES_PORT and DATABASE_URL from it — see Step 1), so it DOES
# reach the mise-run prep step. Export it for every child process below.
#
# We ALSO export a matching DATABASE_URL directly: the matrix run below is a
# *direct* `cargo test` (NOT via `mise run`), so it never sees mise's templated
# [env] — it reads DATABASE_URL straight from this process env. Both point at
# the same 7433 endpoint, so the mise-run prep step and the direct matrix run
# target the logging server consistently. (For the prep step, EQL_POSTGRES_PORT
# is what matters — mise re-renders DATABASE_URL from it and would ignore this
# exported one; for the direct cargo run, this exported DATABASE_URL is what
# matters. Belt and suspenders, each covering the path the other cannot.)
LOG_PORT=7433
export EQL_POSTGRES_PORT="${LOG_PORT}"
export DATABASE_URL="postgresql://cipherstash:password@localhost:${LOG_PORT}/cipherstash"

# Deterministic slice: instead of time-slicing a shared/long-lived container
# (which `docker logs --since` does at SECOND granularity — host/container clock
# skew can drop or double the boundary second of the authoritative witness log),
# we recreate the container fresh so its log starts EMPTY. `down` then `up`
# guarantees the whole subsequent `docker logs` stream belongs to exactly this
# run — no slicing, no boundary races.
echo "==> recreating postgres-logging for a fresh, empty log"
( cd tests && docker compose --profile capture down postgres-logging )
( cd tests && docker compose --profile capture up postgres-logging --detach --wait )

# Prep must run against THIS server so the ephemeral test DBs install EQL +
# fixtures here. test:sqlx:prep is a mise task, so it reads DATABASE_URL from
# mise's [env] — which we retargeted to 7433 via EQL_POSTGRES_PORT (exported
# above; see Step 1). It runs build -> cp 001_install_eql.sql -> sqlx migrate
# -> fixture:generate:all, all against the logging server.
echo "==> prep (build + migrate + fixtures) against the logging server"
mise run test:sqlx:prep

echo "==> running scalars:: matrix against the logging server"
# Run only the scalar matrix (the eql_v3 generated surface). A failure here is
# still useful — we want the captured log regardless — so do not abort on the
# test exit code; record it and continue to harvest.
set +e
( cd tests/sqlx && cargo test --test encrypted_domain scalars:: )
TEST_RC=$?
set -e
echo "==> matrix run exit code: ${TEST_RC}"

echo "==> harvesting container log to ${RAW_LOG}"
# The container was recreated above, so its entire log stream belongs to this
# run — capture all of it (no --since slicing). docker logs writes stdout+stderr;
# Postgres logs to stderr, so 2>&1 captures the log lines. Pipe through gzip so
# the on-disk artifact is the compressed `.log.gz`.
docker logs postgres-logging 2>&1 | gzip > "${RAW_LOG}"

# `wc -l` can't read the gzip directly; decompress on the fly for the count.
echo "==> captured $(gzip -dc "${RAW_LOG}" | wc -l) log lines ($(ls -lh "${RAW_LOG}" | awk '{print $5}') compressed)"
echo "==> raw log: ${RAW_LOG}"

# Leave the server up for inspection unless KEEP_LOGGING_DB=0.
if [ "${KEEP_LOGGING_DB:-1}" = "0" ]; then
  ( cd tests && docker compose --profile capture down postgres-logging )
fi

# Surface the run id for the ledger step.
echo "${RUN_ID}" > "${REPO_ROOT}/target/log-capture/last-run-id"
exit 0
