#!/usr/bin/env bash
set -euo pipefail

# Generates a 100K-row encrypted bench dataset via CipherStash Proxy.
# No dump is written in v1 — the Tier 2 workflow regenerates fresh each run.
#
# Prerequisites:
#   - mise run build  (produces release/cipherstash-encrypt.sql)
#   - docker compose -f tests/benchmarks/docker-compose.yml up -d --wait
#   - tests/benchmarks/.env populated with CipherStash credentials

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EQL_SQL="$REPO_ROOT/release/cipherstash-encrypt.sql"
SCALE="${1:-100k}"

case "$SCALE" in
    100k) ROWS=100000 ;;
    *) echo "Unsupported scale: $SCALE (only 100k in v1)" >&2; exit 1 ;;
esac

if [ ! -f "$EQL_SQL" ]; then
    echo "ERROR: $EQL_SQL not found. Run 'mise run build' first." >&2
    exit 1
fi

PG_URL="postgresql://cipherstash:password@localhost:7433/cipherstash"
PROXY_URL="postgresql://cipherstash:password@localhost:6433/cipherstash"

echo "==> Installing EQL into bench-postgres"
psql "$PG_URL" -v ON_ERROR_STOP=1 -f "$EQL_SQL" >/dev/null

echo "==> Applying bench schema and Proxy search configuration"
psql "$PG_URL" -v ON_ERROR_STOP=1 -f "$SCRIPT_DIR/schema.sql"

# Proxy caches the encrypt config at connection-handler init. add_search_config
# in schema.sql writes the new config but the Proxy will keep running in
# PASSTHROUGH MODE (inserts pass through unencrypted) until it reconnects.
# Restart and wait for it to come back before driving the INSERT.
echo "==> Restarting bench-proxy so it reloads the new encrypt config"
docker restart bench-proxy >/dev/null
for i in $(seq 1 60); do
    if psql "$PROXY_URL" -c 'SELECT 1' >/dev/null 2>&1; then
        echo "    Proxy ready."
        break
    fi
    sleep 1
    if [ "$i" -eq 60 ]; then
        echo "ERROR: bench-proxy did not come back up after restart" >&2
        docker logs bench-proxy 2>&1 | tail -20
        exit 1
    fi
done

echo "==> Inserting $ROWS plaintext rows through Proxy (this encrypts them)"
# generate_series emits plaintext rows; Proxy intercepts and encrypts each
# column per the search config applied in schema.sql.
psql "$PROXY_URL" -v ON_ERROR_STOP=1 -c "
INSERT INTO bench (encrypted_text, encrypted_int, encrypted_bigint)
SELECT
    ('text_' || (((gs - 1) % 1000) + 1))::text,
    (((gs - 1) % 1000) + 1)::int,
    (((gs - 1) % 1000) + 1)::bigint * 1000000000
FROM generate_series(1, $ROWS) AS gs;
"

echo "==> Creating indexes and running ANALYZE"
psql "$PG_URL" -v ON_ERROR_STOP=1 -c "
CREATE INDEX IF NOT EXISTS bench_text_hmac_idx   ON bench USING hash  (eql_v2.hmac_256(encrypted_text));
CREATE INDEX IF NOT EXISTS bench_text_ore_idx    ON bench USING btree (encrypted_text eql_v2.encrypted_operator_class);
CREATE INDEX IF NOT EXISTS bench_int_ore_idx     ON bench USING btree (encrypted_int eql_v2.encrypted_operator_class);
CREATE INDEX IF NOT EXISTS bench_bigint_ore_idx  ON bench USING btree (encrypted_bigint eql_v2.encrypted_operator_class);
CREATE INDEX IF NOT EXISTS bench_text_bloom_idx  ON bench USING gin   (eql_v2.bloom_filter(encrypted_text));
ANALYZE bench;
"

echo "==> Done. Rows: $ROWS"
