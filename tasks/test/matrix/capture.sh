#!/usr/bin/env bash
#MISE description="Run the int4 matrix and capture executed SQL from Postgres logs"
#USAGE flag "--postgres <version>" help="PostgreSQL version to test against" default="17" {
#USAGE   choices "14" "15" "16" "17"
#USAGE }
#USAGE flag "--out <dir>" help="Output directory for captured SQL artifacts" default="/tmp/eql-matrix-capture"

# Verify the int4 test matrix's real SQL coverage by capturing every statement
# Postgres executes during the run.
#
# The matrix (tests/sqlx/src/matrix.rs, surfaced as scalars::int4) builds its
# SQL at runtime via format!, so the only way to see the actual predicates /
# casts / operators that reach the server is to log them. We flip
# `log_statement='all'` via ALTER SYSTEM + reload (SIGHUP-reloadable, no restart
# and no docker-compose edit), run only the int4 matrix, then pull the
# statements back out of `docker logs`. A trap always resets logging on exit so
# an aborted run never leaves the shared container verbose.
#
# `pg_stat_statements` is deliberately NOT used: it normalises literals/params,
# discarding the exact predicates (`= MIN`, `<@`, specific casts) that coverage
# verification depends on. log_statement=all keeps statements verbatim.
#
# Build + migration refresh is done here on purpose: a coverage-verification
# tool that runs against a STALE install silently reports the wrong surface (we
# hit exactly this — a stale eql_v3.int4 migration made every domain cast fail
# while the current codegen emits eql_v2_int4). `mise run build` is deterministic
# and credential-free, so we always rebuild the release and copy it into
# migrations/001_install_eql.sql before running. Only *fixture* regeneration
# needs CS_* creds, so this task does NOT regenerate fixtures — it assumes the
# gitignored tests/sqlx/fixtures/eql_v2_int4.sql already exists (run `mise run
# test:sqlx` once to create it).

set -euo pipefail

POSTGRES_VERSION=${usage_postgres}
OUT=${usage_out}
CONTAINER=postgres-${POSTGRES_VERSION}
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

echo "=========================================="
echo "int4 Matrix SQL Capture"
echo "PostgreSQL Version: ${POSTGRES_VERSION}  (container: ${CONTAINER})"
echo "Output dir:         ${OUT}"
echo "=========================================="
echo ""
echo "Note: requires tests/sqlx/fixtures/eql_v2_int4.sql (gitignored) to exist."
echo "      If absent, run 'mise run test:sqlx' once (needs CS_* creds) first."
echo ""

# Check the container is up (reuses the shared task; inherits usage_postgres).
"${SCRIPT_DIR}/../../postgres/check_container.sh" "${POSTGRES_VERSION}"

if [ ! -f "${CONFIG_ROOT}/tests/sqlx/fixtures/eql_v2_int4.sql" ]; then
  echo "error: tests/sqlx/fixtures/eql_v2_int4.sql is missing."
  echo "error: run 'mise run test:sqlx' once (needs CS_* creds) to generate it."
  exit 1
fi

# Rebuild and refresh the migration so the test DBs install the CURRENT EQL
# surface, not a stale release. build is deterministic and needs no creds.
echo "Building EQL and refreshing the install migration..."
mise run --output prefix --force build
cp "${CONFIG_ROOT}/release/cipherstash-encrypt.sql" \
   "${CONFIG_ROOT}/tests/sqlx/migrations/001_install_eql.sql"

mkdir -p "${OUT}"

reset_logging() {
  docker exec "${CONTAINER}" psql -U cipherstash -d cipherstash \
    -c "ALTER SYSTEM RESET log_statement;" \
    -c "SELECT pg_reload_conf();" >/dev/null 2>&1 || true
}
trap reset_logging EXIT

echo "Enabling log_statement='all'..."
docker exec "${CONTAINER}" psql -U cipherstash -d cipherstash \
  -c "ALTER SYSTEM SET log_statement='all';" \
  -c "SELECT pg_reload_conf();" >/dev/null

# Only pull logs produced from here on (the container is long-lived & shared).
START=$(date -u +%FT%TZ)

echo ""
echo "Running int4 matrix (cargo test --test encrypted_domain scalars::int4)..."
echo ""
# --test-threads=1 is REQUIRED, not just tidy: the SQL extractor below reassembles
# multi-line statements by appending un-prefixed continuation lines (which carry no
# backend pid) to the statement currently being captured. Parallel tests open
# concurrent backends whose log lines interleave in `docker logs`, so a
# continuation line from backend A would be glued onto backend B's statement —
# producing corrupt merged statements (e.g. `SELECT current_database()` with a
# CREATE FUNCTION body spliced on). Serial execution keeps each statement's lines
# contiguous so reassembly is correct. It also lowers peak disk (one ephemeral
# test DB at a time) on the shared 12G Docker volume.
if ! ( cd "${CONFIG_ROOT}/tests/sqlx" && cargo test --test encrypted_domain scalars::int4 -- --test-threads=1 ); then
  echo ""
  echo "error: matrix run failed."
  echo "error: if this is a missing-migration/fixture failure, run 'mise run test:sqlx' once first."
  exit 1
fi

RAW="${OUT}/matrix-sql.raw.log"
FILTERED="${OUT}/matrix-sql.filtered.log"

echo ""
echo "Capturing executed SQL from ${CONTAINER} logs..."
# Capture only the EXTENDED query protocol (`LOG:  execute <name>: <sql>`). That
# is what sqlx issues for every test query — the int4 surface this tool exists to
# verify. The SIMPLE protocol (`LOG:  statement: <sql>`) is the EQL install /
# migration (every ephemeral test DB re-runs the full 001_install_eql.sql) and is
# NOT "the surface exercised" — it is the surface being created. Empirically every
# matrix probe (predicates, casts, EXPLAIN, blockers, aggregates, the planner-
# metadata catalog query) is `execute`, and zero test probes are `statement`, so
# selecting `execute` keeps 100% of coverage and structurally excludes the install.
#
# Postgres logs a MULTI-LINE statement as one prefixed line (EMPTY when the SQL
# string starts with a newline, as several matrix `r#"..."#` templates do)
# followed by un-prefixed continuation lines. A bare "print the prefixed line" sed
# drops every multi-line query body — e.g. the planner-metadata pg_operator query
# vanished entirely. So reassemble: treat a Postgres log-line prefix
# (`^YYYY-MM-DD `) as the record boundary, capture the text after the execute
# marker, append continuation lines, and emit each statement as one whitespace-
# collapsed line. Portable awk (no `{n}` interval quantifiers).
docker logs --since "${START}" "${CONTAINER}" 2>&1 | awk '
  function flush() {
    if (cap && acc != "") { gsub(/[ \t]+/, " ", acc); sub(/^ +/, "", acc); sub(/ +$/, "", acc); print acc }
    acc=""; cap=0
  }
  /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] / {
    flush()
    if (match($0, /LOG:  execute [^:]+: /)) { acc = substr($0, RSTART + RLENGTH); cap=1 }
    next
  }
  { if (cap) acc = acc " " $0 }
  END { flush() }
' > "${RAW}"

# RAW now holds only test-issued statements (extended protocol), but still mixes
# int4 coverage with per-test scaffolding (CREATE TEMP TABLE, INSERT, ANALYZE,
# SET, SAVEPOINT). Filter to the int4 domain surface and drop that setup, then
# dedupe. Include tokens:
# domain types eql_v2_int4{,_eq,_ord,_ord_ore}; wrapper fns eq/neq/lt/lte/gt/gte;
# extractors eq_term/ord_term; aggregates min/max. Plus `FROM typed_col` /
# `FROM typed_count`: some probes touch int4 ONLY through a temp-table column
# typed eql_v2_int4_* (`SELECT * FROM typed_col WHERE value <op> value`,
# `SELECT COUNT(value) FROM typed_count`) and carry NO eql_v2 token at all, so
# they can only be matched by table name. The exclude drops every setup verb
# (CREATE/INSERT/ANALYZE/SET/SAVEPOINT/…) and comment-led (`--`) install DDL, so
# admitting those table names / the broad `eql_v2_int4` token never drags in
# data-loading, planner-setup, or migration statements.
grep -E 'eql_v2_int4|::jsonb::eql_v2_|eql_v2\.(eq|neq|lt|lte|gt|gte|eq_term|ord_term|min|max)|EXPLAIN|FROM typed_col|FROM typed_count' \
    "${RAW}" \
  | grep -vE '^(--|CREATE|COMMENT|GRANT|ALTER|DROP|DO |INSERT|ANALYZE|SET |SAVEPOINT|ROLLBACK|RELEASE|BEGIN|COMMIT)' \
  | LC_ALL=C sort -u > "${FILTERED}"

echo ""
echo "=========================================="
echo "✅ Capture complete"
echo "=========================================="
echo "  raw      ($(wc -l < "${RAW}" | tr -d ' ') lines): ${RAW}"
echo "  filtered ($(wc -l < "${FILTERED}" | tr -d ' ') lines): ${FILTERED}"
echo ""
echo "Inspect the filtered log to verify each domain×operator combination"
echo "(eql_v2_int4_eq with =/<>, eql_v2_int4_ord{,_ore} with </<=/>/>=, blockers)"
echo "actually reached Postgres."
