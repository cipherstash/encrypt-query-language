#!/usr/bin/env bash
# Common helpers for fixture generators (encrypted_text, encrypted_int4,
# encrypted_jsonb). Sourced — not executed directly. Sets PG_URL / PROXY_URL
# and exposes restart_proxy_and_wait + dump_fixture_table.

# Resolve Postgres / Proxy connection from mise [env] (POSTGRES_*) with the
# usual defaults. PROXY_PORT comes from tests/docker-compose.proxy.yml.
PG_USER="${POSTGRES_USER:-cipherstash}"
PG_PASSWORD="${POSTGRES_PASSWORD:-password}"
PG_DB="${POSTGRES_DB:-cipherstash}"
PG_HOST="${POSTGRES_HOST:-localhost}"
PG_PORT="${POSTGRES_PORT:-7432}"
PROXY_PORT="${PROXY_PORT:-6432}"

PG_URL="postgresql://${PG_USER}:${PG_PASSWORD}@${PG_HOST}:${PG_PORT}/${PG_DB}"
PROXY_URL="postgresql://${PG_USER}:${PG_PASSWORD}@${PG_HOST}:${PROXY_PORT}/${PG_DB}"

export PGPASSWORD="$PG_PASSWORD"

# Proxy caches its encrypt config at connection-handler init time, so any
# add_search_config call applied AFTER Proxy started won't take effect
# until Proxy reconnects. Restart and wait for it to come back.
restart_proxy_and_wait() {
    echo "==> Restarting Proxy so it reloads the new encrypt config"
    docker restart cipherstash-proxy >/dev/null

    for i in $(seq 1 60); do
        if psql "$PROXY_URL" -c 'SELECT 1' >/dev/null 2>&1; then
            echo "    Proxy ready."
            return 0
        fi
        sleep 1
    done

    echo "ERROR: Proxy did not come back up after restart" >&2
    docker logs cipherstash-proxy 2>&1 | tail -20
    return 1
}

# Render fixture rows as INSERT statements using format(%L). Caller supplies:
#   $1 = source table name (e.g. bench_text)
#   $2 = destination table name in the migration (e.g. encrypted_text_plaintext)
#   $3 = comma-separated source-column projection
#         (e.g. "id, plaintext, (encrypted_text).data::text")
#   $4 = comma-separated destination column types for format() placeholders
#         (e.g. "%L, %L, %L::jsonb")
#   $5 = destination column-name tuple
#         (e.g. "(id, plaintext, payload)")
#   $6 = output path
#
# The migration is written with a DROP / CREATE preamble plus the rendered
# INSERT statements. The CREATE statement must be supplied by the caller via
# stdin BEFORE calling this function; see how each generator pipes it in.
dump_fixture_table() {
    local src_table="$1"
    local dst_table="$2"
    local src_projection="$3"
    local fmt_placeholders="$4"
    local dst_columns="$5"
    local output_path="$6"

    psql "$PG_URL" -v ON_ERROR_STOP=1 -t -A -c "
SELECT format(
  'INSERT INTO ${dst_table} ${dst_columns} VALUES (${fmt_placeholders});',
  ${src_projection}
)
FROM ${src_table}
ORDER BY id;
" >> "$output_path"
}
