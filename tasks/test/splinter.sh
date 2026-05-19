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
function_search_path_mutable	eql_v2	~~	function	Phase 1 inlining (#193): must inline so the planner can match eql_v2.bloom_filter(col). Three overloads. (Note: the eql_v2.~~* operator points at this same function — case-insensitivity of LIKE on encrypted ciphertexts is meaningless because the bloom filter index term is independent of case.)
function_search_path_mutable	eql_v2	like	function	LIKE/ILIKE inlining (#201): the eql_v2."~~" operator wrapper inlines to a single-statement call to eql_v2.like, which itself must inline to reach `eql_v2.bloom_filter(a) @> eql_v2.bloom_filter(b)` and match the documented functional GIN index. Pinning search_path here breaks the second inlining layer and reverts bare-form `WHERE col ~~ val` to seq scan.
function_search_path_mutable	eql_v2	ilike	function	LIKE/ILIKE inlining (#201): same rationale as eql_v2.like — the eql_v2."~~*" operator inlines through eql_v2.ilike to the bloom_filter containment form.
function_search_path_mutable	eql_v2	@>	function	GIN-inlining: must inline so the planner can match the index on eql_v2.jsonb_array(e). SET search_path disables SQL function inlining (see PostgreSQL inline_function), reverting GIN scans to seq scans.
function_search_path_mutable	eql_v2	<@	function	GIN-inlining: same as @>.
function_search_path_mutable	eql_v2	jsonb_contains	function	GIN-inlining: wrapper unfolds to eql_v2.jsonb_array(a) @> eql_v2.jsonb_array(b). Pinning search_path here drops the bitmap index scan.
function_search_path_mutable	eql_v2	jsonb_contained_by	function	GIN-inlining: same as jsonb_contains.
function_search_path_mutable	eql_v2	min	function	Aggregate (splinter labels these type=function): ALTER AGGREGATE has no SET configuration_parameter syntax, and ALTER ROUTINE/FUNCTION reject aggregates. The aggregate's SFUNC has a pinned search_path.
function_search_path_mutable	eql_v2	max	function	Aggregate: same as min.
function_search_path_mutable	eql_v2	grouped_value	function	Aggregate: same as min.
function_search_path_mutable	eql_v2	encrypted_text_eq	function	Domain prototype: inlineable wrapper that reduces to eql_v2.hmac_256(a::jsonb) = eql_v2.hmac_256(b::jsonb). SET search_path would disable SQL function inlining and break functional-index matching on hmac_256(value::jsonb). Three overloads: (domain, domain), (domain, jsonb), (jsonb, domain).
function_search_path_mutable	eql_v2	encrypted_text_neq	function	Domain prototype: same rationale as encrypted_text_eq.
function_search_path_mutable	eql_v2	encrypted_text_like	function	Domain prototype: inlines to eql_v2.bloom_filter(a::jsonb) @> eql_v2.bloom_filter(b::jsonb) for ~~/~~* engagement of the GIN index on bloom_filter(value::jsonb).
function_search_path_mutable	eql_v2	eql_v2_int4_eq	function	eql_v2_int4 default-variant equality: HMAC wrapper, same rationale as encrypted_text_eq. SET search_path would disable SQL function inlining (see PostgreSQL inline_function) and break functional-index matching on hmac_256(value::jsonb). Three overloads: (domain, domain), (domain, jsonb), (jsonb, domain).
function_search_path_mutable	eql_v2	eql_v2_int4_neq	function	eql_v2_int4 default-variant inequality: same hmac_256 inlining rationale as eql_v2_int4_eq. Three overloads.
function_search_path_mutable	eql_v2	eql_v2_int4_lt	function	eql_v2_int4 default-variant range: inlines to eql_v2.ore_block_u64_8_256(a::jsonb) < eql_v2.ore_block_u64_8_256(b::jsonb) for functional-btree engagement on the ORE-block extractor. Three overloads.
function_search_path_mutable	eql_v2	eql_v2_int4_lte	function	eql_v2_int4 default-variant range: same ORE-block rationale as eql_v2_int4_lt. Three overloads.
function_search_path_mutable	eql_v2	eql_v2_int4_gt	function	eql_v2_int4 default-variant range: same ORE-block rationale as eql_v2_int4_lt. Three overloads.
function_search_path_mutable	eql_v2	eql_v2_int4_gte	function	eql_v2_int4 default-variant range: same ORE-block rationale as eql_v2_int4_lt. Three overloads.
function_search_path_mutable	eql_v2	eql_v2_int4_eq_eq	function	eql_v2_int4_eq variant equality: HMAC wrapper, same hmac_256 inlining rationale as encrypted_text_eq. Three overloads.
function_search_path_mutable	eql_v2	eql_v2_int4_eq_neq	function	eql_v2_int4_eq variant inequality: same hmac_256 inlining rationale as eql_v2_int4_eq_eq. Three overloads.
function_search_path_mutable	eql_v2	eql_v2_int4_ord_ore_eq	function	eql_v2_int4_ord_ore variant equality: HMAC wrapper, same hmac_256 inlining rationale as encrypted_text_eq. Three overloads.
function_search_path_mutable	eql_v2	eql_v2_int4_ord_ore_neq	function	eql_v2_int4_ord_ore variant inequality: same hmac_256 inlining rationale as eql_v2_int4_ord_ore_eq. Three overloads.
function_search_path_mutable	eql_v2	eql_v2_int4_ord_ore_lt	function	eql_v2_int4_ord_ore variant range: inlines to eql_v2.ore_block_u64_8_256(a::jsonb) < eql_v2.ore_block_u64_8_256(b::jsonb) for functional-btree engagement on the ORE-block extractor. Three overloads.
function_search_path_mutable	eql_v2	eql_v2_int4_ord_ore_lte	function	eql_v2_int4_ord_ore variant range: same ORE-block rationale as eql_v2_int4_ord_ore_lt. Three overloads.
function_search_path_mutable	eql_v2	eql_v2_int4_ord_ore_gt	function	eql_v2_int4_ord_ore variant range: same ORE-block rationale as eql_v2_int4_ord_ore_lt. Three overloads.
function_search_path_mutable	eql_v2	eql_v2_int4_ord_ore_gte	function	eql_v2_int4_ord_ore variant range: same ORE-block rationale as eql_v2_int4_ord_ore_lt. Three overloads.
function_search_path_mutable	eql_v2	eql_v2_int4_ord_ope_eq	function	eql_v2_int4_ord_ope variant equality: HMAC wrapper, same hmac_256 inlining rationale as encrypted_text_eq. Three overloads.
function_search_path_mutable	eql_v2	eql_v2_int4_ord_ope_neq	function	eql_v2_int4_ord_ope variant inequality: same hmac_256 inlining rationale as eql_v2_int4_ord_ope_eq. Three overloads.
function_search_path_mutable	eql_v2	eql_v2_int4_ord_ope_lt	function	eql_v2_int4_ord_ope variant range: inlines to eql_v2.eql_v2_int4_ord_ope_ope_key(a) < eql_v2.eql_v2_int4_ord_ope_ope_key(b) (bytea lex-compare on OPE bytes) for functional-btree engagement on the OPE-key extractor. Three overloads.
function_search_path_mutable	eql_v2	eql_v2_int4_ord_ope_lte	function	eql_v2_int4_ord_ope variant range: same OPE-key bytea lex-compare rationale as eql_v2_int4_ord_ope_lt. Three overloads.
function_search_path_mutable	eql_v2	eql_v2_int4_ord_ope_gt	function	eql_v2_int4_ord_ope variant range: same OPE-key bytea lex-compare rationale as eql_v2_int4_ord_ope_lt. Three overloads.
function_search_path_mutable	eql_v2	eql_v2_int4_ord_ope_gte	function	eql_v2_int4_ord_ope variant range: same OPE-key bytea lex-compare rationale as eql_v2_int4_ord_ope_lt. Three overloads.
function_search_path_mutable	eql_v2	eql_v2_int4_ord_ope_ope_key	function	eql_v2_int4_ord_ope OPE-key extractor: used both by the range wrapper bodies and by the functional btree index expression ((eql_v2.eql_v2_int4_ord_ope_ope_key(col::jsonb))). Must inline. Two overloads (domain input, jsonb input).
function_search_path_mutable	eql_v2	encrypted_jsonb_array	function	Domain prototype: ste-vec array extractor used by the functional GIN index and by encrypted_jsonb_contains / encrypted_jsonb_contained_by. Two overloads.
function_search_path_mutable	eql_v2	encrypted_jsonb_eq	function	Domain prototype: hmac_256 rationale.
function_search_path_mutable	eql_v2	encrypted_jsonb_neq	function	Domain prototype: hmac_256 rationale.
function_search_path_mutable	eql_v2	encrypted_jsonb_contains	function	Domain prototype: inlines to encrypted_jsonb_array(a) @> encrypted_jsonb_array(b) so the GIN index on encrypted_jsonb_array(value) engages.
function_search_path_mutable	eql_v2	encrypted_jsonb_contained_by	function	Domain prototype: same as encrypted_jsonb_contains.
function_search_path_mutable	eql_v2	encrypted_jsonb_arrow	function	Domain prototype: text-selector path operator wrapper. Inlineable so a future ste_vec functional index on the rewrapped value could engage.
function_search_path_mutable	eql_v2	encrypted_jsonb_arrow_int	function	Domain prototype: integer-selector path operator wrapper (array element access on encrypted JSON arrays).
function_search_path_mutable	eql_v2	encrypted_jsonb_arrow_text	function	Domain prototype: ->> text-selector wrapper.
function_search_path_mutable	eql_v2	encrypted_jsonb_arrow_text_int	function	Domain prototype: ->> integer-selector wrapper.
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
