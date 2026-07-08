#!/usr/bin/env bash
#MISE description="DB-free unit tests for tasks/build/ordering.sh (cycle gate, edge reversal, anchored strip)"
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
source tasks/build/ordering.sh

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# 1. Cycle gate must FAIL on both BSD and GNU tsort (BSD exits 0 but prints to stderr).
printf 'a b\nb a\n' > "$tmp/cyc.txt"
if run_tsort_or_die "$tmp/cyc.txt" "$tmp/cyc.out" 2>/dev/null; then
  echo "FAIL: cycle not rejected"; exit 1
fi
echo "ok: cycle rejected"

# 2. Edge reversal: dependency-first edges yield dependency-before-file order (no tac).
printf 'schema.sql types.sql\ntypes.sql ops.sql\n' > "$tmp/ok.txt"
run_tsort_or_die "$tmp/ok.txt" "$tmp/ok.out"
[[ "$(tr '\n' ' ' < "$tmp/ok.out")" == "schema.sql types.sql ops.sql " ]] || { echo "FAIL: order $(cat "$tmp/ok.out")"; exit 1; }
echo "ok: dependency-first order without tac"

# 3. Anchored strip keeps a body line that merely contains the substring REQUIRE.
printf -- '-- REQUIRE: src/v3/schema.sql\nSELECT 1; -- the REQUIRE keyword in prose\n' > "$tmp/body.sql"
out="$(strip_require_lines "$tmp/body.sql")"
[[ "$out" == "SELECT 1; -- the REQUIRE keyword in prose" ]] || { echo "FAIL: strip removed non-directive line: [$out]"; exit 1; }
echo "ok: anchored strip preserves non-directive REQUIRE substring"

# 4. verify_linearization fails when a dep is ordered AFTER its dependent.
printf 'types.sql ops.sql\n' > "$tmp/edges.txt"
printf 'ops.sql\ntypes.sql\n' > "$tmp/badorder.txt"
if verify_linearization "$tmp/edges.txt" "$tmp/badorder.txt" 2>/dev/null; then
  echo "FAIL: bad linearization accepted"; exit 1
fi
echo "ok: linearization violation detected"
echo "ALL build-ordering helper tests passed"
