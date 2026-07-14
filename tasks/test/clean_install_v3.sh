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
SELECT 'public.eql_v3_integer_ord'::regtype;
SELECT 'eql_v3_internal.hmac_256'::regtype;
SELECT 'eql_v3_internal.ore_block_256'::regtype;

-- Real ordered-domain columns + the documented functional indexes, one per
-- ordering path. `_ord` is CLLW-OPE: eql_v3.ord_term returns a bytea-backed
-- type with a native btree opclass, so its index needs nothing installed.
-- `_ord_ore` is block-ORE and is the D4 proof: eql_v3.ord_term_ore's index
-- fails outright if the ported operator_class is absent.
CREATE TABLE v3_smoke (c public.eql_v3_integer_ord, c_ore public.eql_v3_integer_ord_ore);
CREATE INDEX v3_smoke_ord ON v3_smoke (eql_v3.ord_term(c));
CREATE INDEX v3_smoke_ord_ore ON v3_smoke (eql_v3.ord_term_ore(c_ore));
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
    PERFORM eql_v3_internal.encrypted_domain_unsupported_bool('public.eql_v3_integer', '<');
  EXCEPTION WHEN OTHERS THEN
    raised := true;
    IF SQLERRM <> 'operator < is not supported for public.eql_v3_integer' THEN
      RAISE EXCEPTION 'blocker raised an unexpected message: %', SQLERRM;
    END IF;
  END;

  IF NOT raised THEN
    RAISE EXCEPTION 'blocker eql_v3_internal.encrypted_domain_unsupported_bool did not raise';
  END IF;
END $$;
SQL

echo "==> smoke: v3 searchable encrypted JSONB (SteVec document) surface"
"${RUN[@]}" <<'SQL'
-- The searchable SteVec document domain is public.eql_v3_json_search (CIP-3512).
CREATE TABLE v3_json_smoke (id int PRIMARY KEY, e public.eql_v3_json_search);
INSERT INTO v3_json_smoke VALUES
  (1, '{"i":{"c":"v3_json_smoke","t":"encrypted"},"v":3,"sv":[{"s":"sel","c":"ciphertext","hm":"00"}]}'::public.eql_v3_json_search);

-- Supported typed accessors and containment.
SELECT (e -> 'sel'::text)::jsonb ->> 'hm' FROM v3_json_smoke WHERE id = 1;
SELECT e ->> 'sel'::text FROM v3_json_smoke WHERE id = 1;
SELECT count(*) FROM v3_json_smoke
WHERE e @> '{"sv":[{"s":"sel","hm":"00"}]}'::eql_v3.query_jsonb;
SELECT count(*) FROM v3_json_smoke
WHERE '{"sv":[{"s":"sel","hm":"00"}]}'::eql_v3.query_jsonb <@ e;

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
    IF SQLERRM <> 'operator ? is not supported for public.eql_v3_json_search' THEN
      RAISE EXCEPTION 'json_search blocker raised an unexpected message: %', SQLERRM;
    END IF;
  END;

  IF NOT raised THEN
    RAISE EXCEPTION 'v3 json_search blocker did not raise';
  END IF;
END $$;

DROP TABLE v3_json_smoke;
SQL

echo "==> smoke: v3 storage-only encrypted JSON surface (CIP-3512)"
"${RUN[@]}" <<'SQL'
-- The storage-only / encryption-only domain public.eql_v3_json is a plain
-- {v,i,c} envelope: it accepts a ciphertext-only payload and (its CHECK)
-- rejects a SteVec document, and its native-jsonb firewall raises on any op.
CREATE TABLE v3_json_storage_smoke (id int PRIMARY KEY, e public.eql_v3_json);
INSERT INTO v3_json_storage_smoke VALUES
  (1, '{"i":{"c":"v3_json_storage_smoke","t":"encrypted"},"v":3,"c":"ciphertext"}'::public.eql_v3_json);

DO $$
DECLARE
  raised boolean := false;
BEGIN
  -- A SteVec document payload must NOT satisfy the storage-only CHECK.
  BEGIN
    PERFORM '{"i":{},"v":3,"sv":[{"s":"sel","c":"ct","hm":"00"}]}'::public.eql_v3_json;
  EXCEPTION WHEN check_violation THEN
    raised := true;
  END;
  IF NOT raised THEN
    RAISE EXCEPTION 'storage-only json CHECK accepted a SteVec document payload';
  END IF;

  -- The native-jsonb firewall raises for the storage-only domain too.
  raised := false;
  BEGIN
    PERFORM e @> '{}'::jsonb FROM v3_json_storage_smoke WHERE id = 1;
  EXCEPTION WHEN OTHERS THEN
    raised := true;
    IF SQLERRM <> 'operator @> is not supported for public.eql_v3_json' THEN
      RAISE EXCEPTION 'storage json blocker raised an unexpected message: %', SQLERRM;
    END IF;
  END;
  IF NOT raised THEN
    RAISE EXCEPTION 'v3 storage json blocker did not raise';
  END IF;
END $$;

DROP TABLE v3_json_storage_smoke;
SQL

echo "clean v3 install OK (D11 + D4 proven)"
