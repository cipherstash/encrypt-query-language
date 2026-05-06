#!/usr/bin/env bash
#MISE description="Run Supabase splinter database linter against installed EQL"
#USAGE flag "--postgres <version>" help="PostgreSQL version (used for container check)" default="17" {
#USAGE   choices "14" "15" "16" "17"
#USAGE }
#USAGE flag "--port <port>" help="Postgres port" default="7432"
#USAGE flag "--user <user>" help="Postgres user" default="cipherstash"
#USAGE flag "--db <db>" help="Postgres database" default="cipherstash"

set -euo pipefail

# Pinned to splinter main as of 2026-04-27. Bump intentionally.
SPLINTER_SHA="55db5b1f28e58d816f7d9136eed87eabcd95868d"
SPLINTER_URL="https://raw.githubusercontent.com/supabase/splinter/${SPLINTER_SHA}/splinter.sql"

PG_PORT="${usage_port:-7432}"
PG_USER="${usage_user:-cipherstash}"
PG_DB="${usage_db:-cipherstash}"
PG_PASSWORD="${POSTGRES_PASSWORD:-password}"

PSQL=(psql -U "$PG_USER" -d "$PG_DB" -h localhost -p "$PG_PORT" -v ON_ERROR_STOP=1)
export PGPASSWORD="$PG_PASSWORD"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

splinter_sql="$work_dir/splinter.sql"
findings_tsv="$work_dir/findings.tsv"
summary_by_rule="$work_dir/by_rule.tsv"

echo "Fetching splinter@${SPLINTER_SHA}..."
curl -sSL --fail -o "$splinter_sql" "$SPLINTER_URL"

# Splinter calls has_table_privilege('anon', ...) etc., which errors if the role
# is missing. Create empty stand-ins so the lints can run on vanilla Postgres.
"${PSQL[@]}" -q <<'SQL'
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN;
  END IF;
END $$;
SQL

# Wrap splinter (a single bare SELECT expression) into a subquery we can
# aggregate from. Splinter starts with `set local search_path = ''` which only
# works inside a transaction, so wrap the whole thing in BEGIN/COMMIT.
splinter_body="$(tail -n +2 "$splinter_sql" | sed 's/;[[:space:]]*$//')"

"${PSQL[@]}" -At -F $'\t' --quiet <<SQL > "$findings_tsv"
BEGIN;
SET LOCAL search_path = '';
SELECT name, level, detail
FROM (${splinter_body}) splinter
ORDER BY level, name;
COMMIT;
SQL

"${PSQL[@]}" -At -F $'\t' --quiet <<SQL > "$summary_by_rule"
BEGIN;
SET LOCAL search_path = '';
SELECT level, name, count(*)
FROM (${splinter_body}) splinter
GROUP BY level, name
ORDER BY
  CASE level WHEN 'ERROR' THEN 0 WHEN 'WARN' THEN 1 WHEN 'INFO' THEN 2 ELSE 3 END,
  count(*) DESC;
COMMIT;
SQL

total="$(wc -l < "$findings_tsv" | tr -d ' ')"
errors="$(awk -F'\t' '$2 == "ERROR"' "$findings_tsv" | wc -l | tr -d ' ')"
warns="$(awk -F'\t' '$2 == "WARN"' "$findings_tsv" | wc -l | tr -d ' ')"
infos="$(awk -F'\t' '$2 == "INFO"' "$findings_tsv" | wc -l | tr -d ' ')"

echo
echo "Splinter findings: total=${total} (ERROR=${errors} WARN=${warns} INFO=${infos})"
echo
printf 'LEVEL\tRULE\tCOUNT\n'
cat "$summary_by_rule"

# Write a GitHub Actions step summary if we're in CI.
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "## Supabase splinter (database linter)"
    echo
    echo "Pinned to [\`splinter@${SPLINTER_SHA:0:12}\`](https://github.com/supabase/splinter/tree/${SPLINTER_SHA})."
    echo
    echo "**${total} findings** — ERROR: ${errors}, WARN: ${warns}, INFO: ${infos}"
    echo
    echo "_Advisory check. Findings here do not block merge until EQL is splinter-clean._"
    echo
    if [[ "$total" -gt 0 ]]; then
      echo "### By rule"
      echo
      echo "| Level | Rule | Count |"
      echo "| --- | --- | --- |"
      awk -F'\t' '{ printf "| %s | `%s` | %s |\n", $1, $2, $3 }' "$summary_by_rule"
      echo
      echo "<details><summary>All findings</summary>"
      echo
      echo "| Level | Rule | Detail |"
      echo "| --- | --- | --- |"
      awk -F'\t' '{
        gsub(/\|/, "\\|", $3);
        printf "| %s | `%s` | %s |\n", $2, $1, $3
      }' "$findings_tsv"
      echo
      echo "</details>"
    else
      echo "EQL is splinter-clean against this pinned ruleset."
    fi
  } >> "$GITHUB_STEP_SUMMARY"
fi

# Exit non-zero so the check surfaces in the UI. The workflow uses
# continue-on-error to keep it advisory until EQL is clean.
if [[ "$total" -gt 0 ]]; then
  exit 1
fi
