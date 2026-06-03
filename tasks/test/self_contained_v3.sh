#!/usr/bin/env bash
#MISE description="Assert the eql_v3 surface is self-contained (no eql_v2 symbol/file leakage)"

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

fail=0

# Symbol level (design goal 1): no eql_v2.<symbol> anywhere under src/v3 — the
# hand-written SEM + foundation files plus the gitignored generated scalar
# surface (present because build runs codegen). Run `mise run build` first.
echo "==> Symbol gate: no 'eql_v2.' under src/v3"
if grep -rn 'eql_v2\.' src/v3; then
  echo "ERROR: eql_v2.<symbol> reference found in src/v3 (must be self-contained)" >&2
  fail=1
fi

# File level (design goal 2): the v3-only dependency closure pulls in no file
# outside src/v3/. tsort output is one path per line.
if [[ ! -f src/deps-ordered-v3.txt ]]; then
  echo "ERROR: src/deps-ordered-v3.txt missing — run 'mise run build' first" >&2
  exit 2
fi
echo "==> File gate: every path in src/deps-ordered-v3.txt is under src/v3/"
if grep -v '^src/v3/' src/deps-ordered-v3.txt; then
  echo "ERROR: v3 dep closure pulls in a path outside src/v3/ (eql_v2 file leak)" >&2
  fail=1
fi

# Belt-and-braces: the assembled artifact carries no eql_v2 symbol.
echo "==> Artifact gate: release/cipherstash-encrypt-v3.sql has no 'eql_v2.'"
if [[ ! -f release/cipherstash-encrypt-v3.sql ]]; then
  echo "ERROR: release/cipherstash-encrypt-v3.sql missing — run 'mise run build' first" >&2
  exit 2
fi
if grep -n 'eql_v2\.' release/cipherstash-encrypt-v3.sql; then
  echo "ERROR: assembled v3 artifact contains an eql_v2. reference" >&2
  fail=1
fi

if [[ $fail -ne 0 ]]; then
  echo "self-containment gate FAILED" >&2
  exit 1
fi
echo "self-containment gate OK"
