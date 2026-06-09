#!/usr/bin/env bash
#MISE description="Run one hash partition of the sqlx suite from a prebuilt nextest archive"

# bash is pinned via the shebang so pipefail is available on dash-based runners.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Required: which shard (1-based) and how many shards total.
: "${SHARD:?SHARD (1-based shard index) must be set}"
: "${SHARD_TOTAL:?SHARD_TOTAL (number of shards) must be set}"
ARCHIVE="${NEXTEST_ARCHIVE:-nextest.tar.zst}"

test -f "${ARCHIVE}" \
  || { echo "archive ${ARCHIVE} missing — run test:sqlx:archive / download the artifact first" >&2; exit 2; }
test -f release/cipherstash-encrypt.sql \
  || { echo "release/cipherstash-encrypt.sql missing — download the build-archive artifact first" >&2; exit 2; }

# 1. Install the built EQL into the SQLx migration set (same as test:sqlx:prep,
#    but WITHOUT rebuilding — the SQL comes from the build-archive artifact).
echo "==> installing built EQL into tests/sqlx/migrations/001_install_eql.sql"
cp release/cipherstash-encrypt.sql tests/sqlx/migrations/001_install_eql.sql

# 2. Migrate this shard's own Postgres.
echo "==> running sqlx migrations"
(cd tests/sqlx && sqlx migrate run)

# 3. Regenerate the gitignored per-test fixtures for THIS shard's DB. Not in the
#    archive/artifact (see plan Task 3 header); needs CS_* + a live PG.
echo "==> regenerating SQLx fixtures for this shard"
mise run fixture:generate:all

# 4. Run this partition from the prebuilt archive. Default features (matching the
#    archive). `hash:` is stable across test add/remove (see design decision 4).
echo "==> running nextest partition hash:${SHARD}/${SHARD_TOTAL}"
cd tests/sqlx
cargo nextest run \
  --archive-file "${REPO_ROOT}/${ARCHIVE}" \
  --workspace-remap "${REPO_ROOT}" \
  --partition "hash:${SHARD}/${SHARD_TOTAL}"
