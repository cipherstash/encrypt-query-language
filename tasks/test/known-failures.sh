#!/usr/bin/env bash
#MISE description="Verify every known-failure marker points at a real, OPEN GitHub issue"
#
# A `known_failure` marker (tests/sqlx/src/known_failure.rs) suppresses a test
# failure. Two things keep that honest:
#
#   1. The Rust side is self-expiring: `known_failure()` FAILS once the wrapped
#      assertion starts passing, so a marker cannot outlive its bug.
#   2. This gate: every `ISSUE_*` constant must name an issue that exists and is
#      still OPEN. A marker pointing at a closed (or fixed, or wontfix'd, or
#      never-created) issue fails here.
#
# Together: you cannot suppress a failure without an open, identified bug, and
# you cannot keep suppressing it once the bug is closed.
#
# Needs `gh` authenticated (CI: GITHUB_TOKEN). Read-only.
set -euo pipefail

EQL_ROOT="${EQL_ROOT:-$(git rev-parse --show-toplevel)}"
REGISTRY="${EQL_ROOT}/tests/sqlx/src/known_failure.rs"

[ -f "$REGISTRY" ] || { echo "missing known-failure registry: $REGISTRY" >&2; exit 2; }

# The repo the issue numbers refer to, read from the registry so it cannot drift.
repo=$(sed -n 's/^pub const KNOWN_FAILURE_REPO: &str = "\(.*\)";$/\1/p' "$REGISTRY")
[ -n "$repo" ] || { echo "could not read KNOWN_FAILURE_REPO from $REGISTRY" >&2; exit 2; }

# Every `pub const ISSUE_<NAME>: u64 = <n>;` in the registry.
mapfile -t entries < <(
  sed -n 's/^pub const \(ISSUE_[A-Z0-9_]*\): u64 = \([0-9]*\);$/\1 \2/p' "$REGISTRY"
)

if [ "${#entries[@]}" -eq 0 ]; then
  echo "==> no known-failure markers registered — nothing to verify."
  exit 0
fi

echo "==> verifying ${#entries[@]} known-failure marker(s) against ${repo}"

# A marker whose constant is never referenced by a test is dead weight: the bug
# may be long fixed and nobody noticed. Catch that too.
fail=0
for entry in "${entries[@]}"; do
  name=${entry%% *}
  number=${entry##* }

  # `grep` exits 1 when it matches nothing — which is exactly the case this
  # check exists to report. Under `set -e` + `pipefail` that status propagates
  # out of the pipeline and kills the script here, before the diagnostic below
  # can print. Swallow only grep's status; `wc` still counts the (empty) input.
  refs=$( { grep -rl --include='*.rs' -- "$name" "${EQL_ROOT}/tests/sqlx/tests" 2>/dev/null || true; } | wc -l | tr -d ' ')
  if [ "$refs" -eq 0 ]; then
    echo "  ✗ ${name} (#${number}) is registered but referenced by no test — remove it" >&2
    fail=1
    continue
  fi

  state=$(gh issue view "$number" --repo "$repo" --json state -q .state 2>/dev/null || echo "MISSING")
  case "$state" in
    OPEN)
      echo "  ✓ ${name} → ${repo}#${number} is OPEN (${refs} test ref(s))"
      ;;
    CLOSED)
      echo "  ✗ ${name} → ${repo}#${number} is CLOSED." >&2
      echo "    Either the bug is fixed (delete the marker and let the assertion run)" >&2
      echo "    or it was closed in error (reopen it)." >&2
      fail=1
      ;;
    *)
      echo "  ✗ ${name} → ${repo}#${number} could not be read (state=${state})." >&2
      echo "    A known-failure marker must name a real issue." >&2
      fail=1
      ;;
  esac
done

if [ "$fail" -ne 0 ]; then
  echo >&2
  echo "known-failure gate FAILED: a suppressed test must have an open, identified issue." >&2
  exit 1
fi

echo "known-failure gate OK"
