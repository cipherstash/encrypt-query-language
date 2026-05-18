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
all_findings_tsv="$work_dir/all_findings.tsv"
findings_tsv="$work_dir/findings.tsv"
allowlisted_tsv="$work_dir/allowlisted.tsv"
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

# Allowlist: each finding splinter emits is allowed only if rule + metadata
# (schema, name, type) match an entry below. Each entry must be justified.
#
# Format: TSV "rule\tschema\tname\ttype\treason" — kept as a heredoc so the
# justification lives next to the entry it covers. Keys are matched verbatim.
cat > "$work_dir/allowlist.tsv" <<'ALLOW'
function_search_path_mutable	eql_v2	=	function	Phase 1 inlining (#193): must inline so the planner can match the documented functional index eql_v2.hmac_256(col). SET search_path disables SQL function inlining (see PostgreSQL inline_function); pinning here would revert bare-equality queries to seq scan on Supabase / managed Postgres without superuser. Three overloads: (enc, enc), (enc, jsonb), (jsonb, enc).
function_search_path_mutable	eql_v2	<>	function	Phase 1 inlining (#193): same rationale as eql_v2.=. Three overloads.
function_search_path_mutable	eql_v2	<	function	Range-operator inlining: must inline so `WHERE col < val` reduces to `eql_v2.ore_block_u64_8_256(col) < eql_v2.ore_block_u64_8_256(val)` and matches the documented functional ORE index. Three overloads: (enc, enc), (enc, jsonb), (jsonb, enc).
function_search_path_mutable	eql_v2	<=	function	Range-operator inlining: same rationale as eql_v2.<. Three overloads.
function_search_path_mutable	eql_v2	>	function	Range-operator inlining: same rationale as eql_v2.<. Three overloads.
function_search_path_mutable	eql_v2	>=	function	Range-operator inlining: same rationale as eql_v2.<. Three overloads.
function_search_path_mutable	eql_v2	ore_block_u64_8_256_eq	function	Inner comparator for the ore_block_u64_8_256 type's `=` operator. The outer `eql_v2_encrypted` operators inline to `ore_block(a) op ore_block(b)`; the planner only carries that form through to index matching if this inner function is also inlinable (no SET, IMMUTABLE).
function_search_path_mutable	eql_v2	ore_block_u64_8_256_neq	function	Inner comparator for the ore_block_u64_8_256 type's `<>` operator. Same rationale as ore_block_u64_8_256_eq.
function_search_path_mutable	eql_v2	ore_block_u64_8_256_lt	function	Inner comparator for the ore_block_u64_8_256 type's `<` operator. Same rationale as ore_block_u64_8_256_eq.
function_search_path_mutable	eql_v2	ore_block_u64_8_256_lte	function	Inner comparator for the ore_block_u64_8_256 type's `<=` operator. Same rationale as ore_block_u64_8_256_eq.
function_search_path_mutable	eql_v2	ore_block_u64_8_256_gt	function	Inner comparator for the ore_block_u64_8_256 type's `>` operator. Same rationale as ore_block_u64_8_256_eq.
function_search_path_mutable	eql_v2	ore_block_u64_8_256_gte	function	Inner comparator for the ore_block_u64_8_256 type's `>=` operator. Same rationale as ore_block_u64_8_256_eq.
function_search_path_mutable	eql_v2	hash_encrypted	function	Hash operator class FUNCTION 1: called once per row by HashAggregate, hash joins, DISTINCT. SET search_path forces plpgsql-equivalent call overhead per row; without pinning, the SQL function machinery is ~10× cheaper and `GROUP BY` / `DISTINCT` on `eql_v2_encrypted` at 1M rows stays linear rather than degrading super-linearly via work_mem spillage.
function_search_path_mutable	eql_v2	~~	function	Phase 1 inlining (#193): must inline so the planner can match eql_v2.bloom_filter(col). Three overloads. (Note: the eql_v2.~~* operator points at this same function — case-insensitivity of LIKE on encrypted ciphertexts is meaningless because the bloom filter index term is independent of case.)
function_search_path_mutable	eql_v2	like	function	LIKE/ILIKE inlining (#201): the eql_v2."~~" operator wrapper inlines to a single-statement call to eql_v2.like, which itself must inline to reach `eql_v2.bloom_filter(a) @> eql_v2.bloom_filter(b)` and match the documented functional GIN index. Pinning search_path here breaks the second inlining layer and reverts bare-form `WHERE col ~~ val` to seq scan.
function_search_path_mutable	eql_v2	ilike	function	LIKE/ILIKE inlining (#201): same rationale as eql_v2.like — the eql_v2."~~*" operator inlines through eql_v2.ilike to the bloom_filter containment form.
function_search_path_mutable	eql_v2	hmac_256	function	HMAC equality extractor (#205): all overloads — (jsonb), (eql_v2_encrypted), (eql_v2_encrypted, text) — are inlinable SQL so they can be folded into the calling query, preserving the functional-index match for WHERE / GROUP BY / DISTINCT / hash-join on hmac_256(col) and hmac_256(col, '<selector>').
function_search_path_mutable	eql_v2	hmac_256_terms	function	HMAC terms aggregate (#205): inlinable SQL returning a jsonb array of {s, hm} pairs across sv elements. Must inline so `eql_v2.hmac_256_terms(col) @> $1::jsonb` engages a GIN index built on the same expression.
function_search_path_mutable	eql_v2	jsonb_path_query	function	Field-level JSONB extractor (#205): inlinable SQL body — `jsonb_array_elements((val).data -> 'sv') WHERE elem ->> 's' = selector`. Must inline to fold into the calling query and remove per-row function call overhead on large ste_vec scans. Three overloads: (jsonb, text), (eql_v2_encrypted, text), (eql_v2_encrypted, eql_v2_encrypted).
function_search_path_mutable	eql_v2	jsonb_path_query_first	function	Field-level JSONB extractor (#205): inlinable SQL LIMIT 1 variant. Same rationale as jsonb_path_query. Three overloads.
function_search_path_mutable	eql_v2	jsonb_path_exists	function	Field-level JSONB extractor (#205): inlinable SQL EXISTS variant. Same rationale as jsonb_path_query. Three overloads.
function_search_path_mutable	eql_v2	@>	function	GIN-inlining: must inline so the planner can match the index on eql_v2.jsonb_array(e). SET search_path disables SQL function inlining (see PostgreSQL inline_function), reverting GIN scans to seq scans.
function_search_path_mutable	eql_v2	<@	function	GIN-inlining: same as @>.
function_search_path_mutable	eql_v2	jsonb_contains	function	GIN-inlining: wrapper unfolds to eql_v2.jsonb_array(a) @> eql_v2.jsonb_array(b). Pinning search_path here drops the bitmap index scan.
function_search_path_mutable	eql_v2	jsonb_contained_by	function	GIN-inlining: same as jsonb_contains.
function_search_path_mutable	eql_v2	min	function	Aggregate (splinter labels these type=function): ALTER AGGREGATE has no SET configuration_parameter syntax, and ALTER ROUTINE/FUNCTION reject aggregates. The aggregate's SFUNC has a pinned search_path.
function_search_path_mutable	eql_v2	max	function	Aggregate: same as min.
function_search_path_mutable	eql_v2	grouped_value	function	Aggregate: same as min.
ALLOW

# Wrap splinter (a single bare SELECT expression) into a subquery we can
# aggregate from. Splinter starts with `set local search_path = ''` which only
# works inside a transaction, so wrap the whole thing in BEGIN/COMMIT.
splinter_body="$(tail -n +2 "$splinter_sql" | sed 's/;[[:space:]]*$//')"

# Pull all findings with their metadata, then split into allowlisted vs not.
"${PSQL[@]}" -At -F $'\t' --quiet <<SQL > "$all_findings_tsv"
BEGIN;
SET LOCAL search_path = '';
SELECT
  name,
  level,
  detail,
  coalesce(metadata->>'schema', ''),
  coalesce(metadata->>'name', ''),
  coalesce(metadata->>'type', '')
FROM (${splinter_body}) splinter
ORDER BY level, name, detail;
COMMIT;
SQL

# Refuse to run with an empty allowlist. Without this guard, the awk
# discriminator below would still classify everything as allowlisted on
# an accidentally-empty file (e.g., a heredoc syntax error during edits)
# and the gate would silently pass any real findings.
if [[ ! -s "$work_dir/allowlist.tsv" ]]; then
  echo "splinter: allowlist.tsv is empty — refusing to run to avoid silently passing findings" >&2
  exit 2
fi

# Split: allowlisted entries match all of (rule, schema, name, type).
# Use FILENAME as the discriminator rather than NR == FNR so behavior is
# robust to either file being empty.
awk -F'\t' \
  -v allowlist_file="$work_dir/allowlist.tsv" \
  -v allow_out="$allowlisted_tsv" \
  -v deny_out="$findings_tsv" '
  FILENAME == allowlist_file {
    key = $1 SUBSEP $2 SUBSEP $3 SUBSEP $4
    allow[key] = $5
    next
  }
  {
    key = $1 SUBSEP $4 SUBSEP $5 SUBSEP $6
    if (key in allow) {
      print $0 "\t" allow[key] > allow_out
    } else {
      print $0 > deny_out
    }
  }
' "$work_dir/allowlist.tsv" "$all_findings_tsv"

# Touch in case awk didn't write either file (no findings at all).
touch "$findings_tsv" "$allowlisted_tsv"

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

raw_total="$(wc -l < "$all_findings_tsv" | tr -d ' ')"
allowlisted_total="$(wc -l < "$allowlisted_tsv" | tr -d ' ')"
total="$(wc -l < "$findings_tsv" | tr -d ' ')"
errors="$(awk -F'\t' '$2 == "ERROR"' "$findings_tsv" | wc -l | tr -d ' ')"
warns="$(awk -F'\t' '$2 == "WARN"' "$findings_tsv" | wc -l | tr -d ' ')"
infos="$(awk -F'\t' '$2 == "INFO"' "$findings_tsv" | wc -l | tr -d ' ')"

echo
echo "Splinter findings: raw=${raw_total} (allowlisted=${allowlisted_total}, unallowlisted=${total} — ERROR=${errors} WARN=${warns} INFO=${infos})"
echo
printf 'LEVEL\tRULE\tCOUNT (raw)\n'
cat "$summary_by_rule"

if [[ "$allowlisted_total" -gt 0 ]]; then
  echo
  echo "Allowlisted findings (accepted, see tasks/test/splinter.sh for justifications):"
  awk -F'\t' '{ printf "  - [%s] %s.%s (%s) — %s\n", $1, $4, $5, $6, $7 }' "$allowlisted_tsv"
fi

if [[ "$total" -gt 0 ]]; then
  echo
  echo "Unallowlisted findings:"
  awk -F'\t' '{ printf "  - [%s] %s — %s\n", $2, $1, $3 }' "$findings_tsv"
fi

# Write a GitHub Actions step summary if we're in CI.
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "## Supabase splinter (database linter)"
    echo
    echo "Pinned to [\`splinter@${SPLINTER_SHA:0:12}\`](https://github.com/supabase/splinter/tree/${SPLINTER_SHA})."
    echo
    echo "**${raw_total} raw findings** (allowlisted: ${allowlisted_total}, unallowlisted: ${total} — ERROR: ${errors}, WARN: ${warns}, INFO: ${infos})"
    echo
    if [[ "$total" -gt 0 ]]; then
      echo "### Unallowlisted findings (action required)"
      echo
      echo "| Level | Rule | Detail |"
      echo "| --- | --- | --- |"
      awk -F'\t' '{
        gsub(/\|/, "\\|", $3);
        printf "| %s | `%s` | %s |\n", $2, $1, $3
      }' "$findings_tsv"
      echo
    elif [[ "$raw_total" -eq 0 ]]; then
      echo "EQL is splinter-clean against this pinned ruleset."
      echo
    else
      echo "EQL is splinter-clean (all findings covered by the allowlist)."
      echo
    fi
    if [[ "$allowlisted_total" -gt 0 ]]; then
      echo "<details><summary>Allowlisted findings (${allowlisted_total})</summary>"
      echo
      echo "| Rule | Schema | Name | Type | Reason |"
      echo "| --- | --- | --- | --- | --- |"
      awk -F'\t' '{
        gsub(/\|/, "\\|", $7);
        printf "| `%s` | `%s` | `%s` | %s | %s |\n", $1, $4, $5, $6, $7
      }' "$allowlisted_tsv"
      echo
      echo "</details>"
    fi
  } >> "$GITHUB_STEP_SUMMARY"
fi

# Fail only on findings that aren't allowlisted.
if [[ "$total" -gt 0 ]]; then
  exit 1
fi
