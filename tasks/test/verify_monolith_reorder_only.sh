#!/usr/bin/env bash
#MISE description="Prove the build-ordering refactor changed ONLY statement order: the LC_ALL=C-sorted monolith is byte-identical to a pre-refactor baseline build"
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# The pre-refactor baseline is the commit immediately BEFORE Task 1 of the
# build-ordering refactor. On this long-lived branch that is the branch tip at
# plan-execution start (c8d50efb) — NOT `git merge-base HEAD main`, which points
# 594 feature commits back and would diff on content, not order. Pass it
# explicitly.
BASELINE_REF="${1:?usage: verify_monolith_reorder_only.sh <baseline-ref>  (the pre-refactor commit, e.g. c8d50efb)}"
VERSION="${EQL_VERSION:-DEV}"   # BOTH builds must bake the SAME version string, else version.sql diffs spuriously.

OUT="$(mktemp -d)"
WT="$(mktemp -d)/eql-baseline"
cleanup() { git worktree remove --force "$WT" 2>/dev/null || true; rm -rf "$OUT" "$(dirname "$WT")"; }
trap cleanup EXIT

# 1. Current branch: build, then LC_ALL=C sort (locale-stable set view).
mise run build --version "$VERSION" >/dev/null
LC_ALL=C sort release/cipherstash-encrypt.sql > "$OUT/current-sorted.sql"

# 2. Baseline: build in an ISOLATED detached worktree at the pre-refactor ref so
#    the working tree is untouched; sort identically. `mise trust` is required —
#    a fresh worktree's mise.toml is untrusted and `mise run` refuses to run it.
git worktree add --detach "$WT" "$BASELINE_REF" >/dev/null
(
  cd "$WT"
  mise trust >/dev/null 2>&1 || true
  mise trust mise.toml >/dev/null 2>&1 || true
  mise run build --version "$VERSION" >/dev/null
)
LC_ALL=C sort "$WT/release/cipherstash-encrypt.sql" > "$OUT/baseline-sorted.sql"

# 3. HARD GATE: sorted views must be byte-identical.
if cmp -s "$OUT/baseline-sorted.sql" "$OUT/current-sorted.sql"; then
  echo "PASS: sorted monolith is byte-identical to baseline $BASELINE_REF — the refactor changed ONLY statement order (nothing added/dropped/mutated)."
else
  echo "FAIL: sorted monolith DIFFERS from baseline $BASELINE_REF — a line was added, dropped, or mutated (not merely reordered):" >&2
  diff "$OUT/baseline-sorted.sql" "$OUT/current-sorted.sql" | head -40 >&2
  exit 1
fi
