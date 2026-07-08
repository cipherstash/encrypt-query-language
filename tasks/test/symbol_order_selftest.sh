#!/usr/bin/env bash
#MISE description="DB-free self-test for the symbol-order cross-check (good passes, mis-ordered fails)"
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# GOOD: definer ordered before user. (a.sql RETURNS a non-owned type — the
# hmac_256 domain-capture branch is exercised separately by d.sql/e.sql below, so
# this pair isolates the eql_v3.eq_term define-before-use ordering it is testing.)
printf 'CREATE FUNCTION eql_v3.eq_term(a public.integer_eq) RETURNS text ...\n' > "$tmp/a.sql"
printf 'CREATE OPERATOR = ( FUNCTION = eql_v3.eq_term );\n' > "$tmp/b.sql"
printf '%s\n%s\n' "$tmp/a.sql" "$tmp/b.sql" > "$tmp/good_order.txt"
bash tasks/test/verify_symbol_order_v3.sh "$tmp/good_order.txt" \
  || { echo "FAIL: good order rejected"; exit 1; }
echo "ok: good order accepted"

# BAD: user ordered before definer.
printf '%s\n%s\n' "$tmp/b.sql" "$tmp/a.sql" > "$tmp/bad_order.txt"
if bash tasks/test/verify_symbol_order_v3.sh "$tmp/bad_order.txt" 2>/dev/null; then
  echo "FAIL: mis-ordered reference accepted"; exit 1
fi
echo "ok: mis-ordered reference rejected"

# COMMENT-ONLY reference must NOT trip the gate (doxygen @see).
printf -- '--! @see eql_v3.eq_term\nSELECT 1;\n' > "$tmp/c.sql"
printf '%s\n' "$tmp/c.sql" > "$tmp/comment_order.txt"
bash tasks/test/verify_symbol_order_v3.sh "$tmp/comment_order.txt" \
  || { echo "FAIL: comment-only reference tripped the gate"; exit 1; }
echo "ok: comment-only reference ignored"

# CREATE DOMAIN eql_v3_internal.* form (SEM index-term types hmac_256/ope_cllw/
# bloom_filter). A domain-form definer ordered before a function returning it
# must be ACCEPTED — pins the domain-capture branch's eql_v3_internal arm so the
# real surface (~165 refs to these three types) can never be misread as "defined
# nowhere" (which would tempt an allowlist entry).
printf 'CREATE DOMAIN eql_v3_internal.hmac_256 AS text;\n' > "$tmp/d.sql"
printf 'CREATE FUNCTION eql_v3.eq_term(a public.integer_eq) RETURNS eql_v3_internal.hmac_256 ...\n' > "$tmp/e.sql"
printf '%s\n%s\n' "$tmp/d.sql" "$tmp/e.sql" > "$tmp/domain_good.txt"
bash tasks/test/verify_symbol_order_v3.sh "$tmp/domain_good.txt" \
  || { echo "FAIL: CREATE DOMAIN eql_v3_internal.* definer not recognised"; exit 1; }
echo "ok: CREATE DOMAIN eql_v3_internal.* definition form recognised"

# And the same domain-form type used BEFORE it is created must be REJECTED
# (defined-later ordering violation on a SEM index-term type — the exact rot
# this gate exists to catch).
printf '%s\n%s\n' "$tmp/e.sql" "$tmp/d.sql" > "$tmp/domain_bad.txt"
if bash tasks/test/verify_symbol_order_v3.sh "$tmp/domain_bad.txt" 2>/dev/null; then
  echo "FAIL: eql_v3_internal.hmac_256 used before its CREATE DOMAIN accepted"; exit 1
fi
echo "ok: domain-form type used before definition rejected"

# CREATE OPERATOR CLASS|FAMILY eql_v3_internal.* form (the conditional SEM
# ordered-index opclasses). A file that both creates the opclass and mentions it
# in a RAISE NOTICE (same file) must be ACCEPTED — pins the operator-class
# definition-capture branch so the real ore_block_256/ore_cllw operator_class.sql
# files (self-contained: def + NOTICE prose only) never read as "defined nowhere".
printf "CREATE OPERATOR FAMILY eql_v3_internal.ore_cllw_ops USING btree;\nCREATE OPERATOR CLASS eql_v3_internal.ore_cllw_ops USING btree FAMILY eql_v3_internal.ore_cllw_ops AS STORAGE text;\nRAISE NOTICE 'created operator class eql_v3_internal.ore_cllw_ops';\n" > "$tmp/opclass.sql"
printf '%s\n' "$tmp/opclass.sql" > "$tmp/opclass_order.txt"
bash tasks/test/verify_symbol_order_v3.sh "$tmp/opclass_order.txt" \
  || { echo "FAIL: CREATE OPERATOR CLASS/FAMILY definer not recognised"; exit 1; }
echo "ok: CREATE OPERATOR CLASS/FAMILY definition form recognised"

# An UNREADABLE path in the ordered list must FAIL the gate, not be silently
# skipped as an empty file (a skipped file's definitions/references go unchecked).
printf '%s\n' "$tmp/does-not-exist.sql" > "$tmp/missing_order.txt"
if bash tasks/test/verify_symbol_order_v3.sh "$tmp/missing_order.txt" 2>/dev/null; then
  echo "FAIL: unreadable path silently accepted"; exit 1
fi
echo "ok: unreadable path rejected"
echo "symbol-order self-test passed"
