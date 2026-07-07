#!/usr/bin/env bash
# Regression guard for the security hardening of
# .github/workflows/release-typescript.yml. These are structural invariants —
# they pin the fixes for the code-review findings so they cannot silently
# regress. Dependency-free; no network, no Actions runner needed.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
wf="${here}/../workflows/release-typescript.yml"

fail=0
pass() { echo "ok: $1"; }
fault() { echo "FAIL: $1"; fail=1; }

[[ -f "$wf" ]] || { echo "FAIL: workflow not found at $wf"; exit 1; }

# --- F1: no command injection via workflow inputs ---------------------------
# `${{ inputs.* }}` must ONLY appear as an `env:` entry (`NAME: ${{ inputs.x }}`),
# never interpolated into a `run:` script body (GitHub expands the expression
# into the script text before bash runs → arbitrary command execution).
offenders="$(grep -nE '\$\{\{ *inputs\.' "$wf" \
  | grep -vE '^[0-9]+:[[:space:]]*[A-Za-z_][A-Za-z0-9_]*: \$\{\{ inputs\.[a-z_]+ \}\}$' \
  || true)"
if [[ -z "$offenders" ]]; then
  pass "F1: workflow inputs are only surfaced via env:, never in run: bodies"
else
  fault "F1: inputs.* interpolated into a run: body (injection risk):"
  echo "$offenders"
fi

# --- F3: checkout must not persist git credentials --------------------------
if grep -qE 'persist-credentials: false' "$wf"; then
  pass "F3: checkout sets persist-credentials: false"
else
  fault "F3: checkout is missing persist-credentials: false"
fi

# --- F3: the tag push must be authenticated (extraheader), not bare origin --
if grep -qE 'extraheader=AUTHORIZATION' "$wf"; then
  pass "F3: tag push authenticates via git extraheader"
else
  fault "F3: authenticated push pattern (extraheader) missing"
fi
if grep -qE 'git push origin "refs/tags' "$wf"; then
  fault "F3: bare 'git push origin' remains (unauthenticated once creds are not persisted)"
else
  pass "F3: no bare 'git push origin' tag push"
fi

# --- F2: publish and tag must be retry-safe (idempotent) --------------------
if grep -qE 'npm view' "$wf"; then
  pass "F2: publish is idempotent (npm view existence guard)"
else
  fault "F2: idempotent publish guard (npm view) missing"
fi
if grep -qE 'ls-remote' "$wf"; then
  pass "F2: tag creation is idempotent (ls-remote existence guard)"
else
  fault "F2: idempotent tag guard (ls-remote) missing"
fi

exit "$fail"
