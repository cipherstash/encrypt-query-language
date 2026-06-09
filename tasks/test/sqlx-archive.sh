#!/usr/bin/env bash
# NOTE: this script is invoked via `bash tasks/...` from an inline mise task, so
# `#MISE` directives here would be INERT (they only fire when mise auto-discovers
# a script as a file-task). The `build` dependency is therefore declared on the
# inline [tasks."test:sqlx:archive"] block (Step 2), mirroring test:sqlx:prep.

# bash is pinned via the shebang (mise honors a `#!` first line) so pipefail is
# available regardless of the runner's /bin/sh.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Archive lands at the repo root so the workflow can upload it by a stable path.
ARCHIVE="${NEXTEST_ARCHIVE:-nextest.tar.zst}"

# The mise task's `depends = ["build"]` (Step 2) has already produced
# release/cipherstash-encrypt.sql. Belt-and-braces: fail loudly if it's missing
# (e.g. the script is run directly rather than via `mise run test:sqlx:archive`).
test -f release/cipherstash-encrypt.sql \
  || { echo "release/cipherstash-encrypt.sql missing — run via 'mise run test:sqlx:archive' (it depends on build)" >&2; exit 2; }

# Compile every tests/sqlx test binary with DEFAULT features and pack them.
# No database is touched here — archive only compiles. The shards apply the live
# Postgres + migration at run time.
echo "==> archiving sqlx test binaries to ${ARCHIVE}"
cd tests/sqlx
cargo nextest archive --archive-file "${REPO_ROOT}/${ARCHIVE}"

echo "==> archive written: ${REPO_ROOT}/${ARCHIVE}"
