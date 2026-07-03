#!/usr/bin/env bash
#MISE description="Install release/cipherstash-encrypt.sql into a scratch DB with NO eql_v2 and smoke-test it (D11, D4)"
#USAGE flag "--port <port>" help="Postgres port" default="7432"
#USAGE flag "--user <user>" help="Postgres user" default="cipherstash"

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

PG_PORT="${usage_port:-7432}"
PG_USER="${usage_user:-cipherstash}"
export PGPASSWORD="${POSTGRES_PASSWORD:-password}"
SCRATCH_DB="cipherstash_v3_clean"

ADMIN=(psql -U "$PG_USER" -h localhost -p "$PG_PORT" -d postgres -v ON_ERROR_STOP=1 -q)
RUN=(psql -U "$PG_USER" -h localhost -p "$PG_PORT" -d "$SCRATCH_DB" -v ON_ERROR_STOP=1 -q)

test -f release/cipherstash-encrypt.sql || { echo "Build first: release/cipherstash-encrypt.sql missing" >&2; exit 2; }

echo "==> (re)creating scratch database $SCRATCH_DB (no eql_v2 installed)"
"${ADMIN[@]}" -c "DROP DATABASE IF EXISTS ${SCRATCH_DB} WITH (FORCE);"
"${ADMIN[@]}" -c "CREATE DATABASE ${SCRATCH_DB};"

cleanup() { "${ADMIN[@]}" -c "DROP DATABASE IF EXISTS ${SCRATCH_DB} WITH (FORCE);" >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "==> installing the standalone eql_v3 surface"
"${RUN[@]}" -f release/cipherstash-encrypt.sql

echo "==> asserting NO eql_v2 schema exists (proves no v2 dependency)"
"${RUN[@]}" -c "DO \$\$ BEGIN IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'eql_v2') THEN RAISE EXCEPTION 'eql_v2 schema unexpectedly present'; END IF; END \$\$;"

echo "==> smoke: domains, SEM types, extractors, opclass functional index (D4)"
"${RUN[@]}" <<'SQL'
-- Domains stay in eql_v3; SEM index-term types now live in eql_v3_internal.
SELECT 'eql_v3.integer_ord'::regtype;
SELECT 'eql_v3_internal.hmac_256'::regtype;
SELECT 'eql_v3_internal.ore_block_256'::regtype;

-- A real ordered-domain column + the documented functional index. This is the
-- D4 proof: it fails outright if the ported operator_class is absent.
CREATE TABLE v3_smoke (c eql_v3.integer_ord);
CREATE INDEX v3_smoke_ord ON v3_smoke (eql_v3.ord_term(c));
DROP TABLE v3_smoke;
SQL

echo "==> smoke: the shared blocker is reachable and raises"
"${RUN[@]}" <<'SQL'
DO $$
DECLARE
  raised boolean := false;
BEGIN
  -- The blocker always RAISEs; catch it and assert we got the expected message.
  BEGIN
    PERFORM eql_v3_internal.encrypted_domain_unsupported_bool('eql_v3.integer', '<');
  EXCEPTION WHEN OTHERS THEN
    raised := true;
    IF SQLERRM <> 'operator < is not supported for eql_v3.integer' THEN
      RAISE EXCEPTION 'blocker raised an unexpected message: %', SQLERRM;
    END IF;
  END;

  IF NOT raised THEN
    RAISE EXCEPTION 'blocker eql_v3_internal.encrypted_domain_unsupported_bool did not raise';
  END IF;
END $$;
SQL

echo "==> smoke: v3 encrypted JSONB surface"
"${RUN[@]}" <<'SQL'
CREATE TABLE v3_json_smoke (id int PRIMARY KEY, e eql_v3.json);
INSERT INTO v3_json_smoke VALUES
  (1, '{"i":{"c":"v3_json_smoke","t":"encrypted"},"v":3,"sv":[{"s":"sel","c":"ciphertext","hm":"00"}]}'::eql_v3.json);

-- Supported typed accessors and containment.
SELECT (e -> 'sel'::text)::jsonb ->> 'hm' FROM v3_json_smoke WHERE id = 1;
SELECT e ->> 'sel'::text FROM v3_json_smoke WHERE id = 1;
SELECT count(*) FROM v3_json_smoke
WHERE e @> '{"sv":[{"s":"sel","hm":"00"}]}'::eql_v3.jsonb_query;
SELECT count(*) FROM v3_json_smoke
WHERE '{"sv":[{"s":"sel","hm":"00"}]}'::eql_v3.jsonb_query <@ e;

-- Documented GIN expression installs cleanly in a v3-only database.
CREATE INDEX v3_json_smoke_gin
  ON v3_json_smoke USING gin ((eql_v3.to_ste_vec_query(e)::jsonb) jsonb_path_ops);

DO $$
DECLARE
  raised boolean := false;
BEGIN
  BEGIN
    PERFORM e ? 'sel'::text FROM v3_json_smoke WHERE id = 1;
  EXCEPTION WHEN OTHERS THEN
    raised := true;
    IF SQLERRM <> 'operator ? is not supported for eql_v3.json' THEN
      RAISE EXCEPTION 'json blocker raised an unexpected message: %', SQLERRM;
    END IF;
  END;

  IF NOT raised THEN
    RAISE EXCEPTION 'v3 json blocker did not raise';
  END IF;
END $$;

DROP TABLE v3_json_smoke;
SQL

echo "clean v3 install OK (D11 + D4 proven)"
