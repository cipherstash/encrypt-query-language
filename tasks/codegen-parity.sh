#!/usr/bin/env bash
#MISE description="Drift gate: regenerate the scalar SQL surface in place and fail if the committed src/v3/scalars files differ (mirrors types:check for the Rust bindings)"

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Regenerate the scalar SQL surface IN PLACE from the eql-domains catalog, then
# assert the committed tree is unchanged — the same regenerate-and-git-diff
# pattern `mise run types:check` uses for the committed Rust bindings. The
# generator writes atomically (temp+rename) and marker-aware-prunes orphans, so
# a failed run leaves a clean tree; no temp-tree/golden dance is needed (there
# is no additive exporter to isolate, unlike the bindings' ts-rs/schemars step).
echo "==> Regenerating the scalar SQL surface in place"
cargo run -q -p eql-codegen -- > /dev/null

# Modified-tracked-file drift: any change to a committed generated file fails.
# Scoped to src/v3/scalars; the hand-written functions.sql / *_extensions.sql are
# never written by the generator, so they never appear here.
git diff --exit-code -- src/v3/scalars || {
  echo "generated SQL surface is stale — run 'mise run build' and commit src/v3/scalars" >&2
  exit 1
}

# New-untracked-file drift: git diff is blind to brand-new files, so a newly
# added catalog type (or a renamed output) whose SQL was never committed is
# caught here.
untracked=$(git ls-files --others --exclude-standard -- src/v3/scalars)
if [ -n "$untracked" ]; then
  echo "uncommitted generated SQL under src/v3/scalars (run 'mise run build' and commit):" >&2
  echo "$untracked" >&2
  exit 1
fi

echo "PARITY OK: committed scalar SQL surface matches the catalog."
