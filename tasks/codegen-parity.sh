#!/usr/bin/env bash
#MISE description="Parity gate: Rust eql-codegen output matches the committed reference SQL files (byte-for-byte, every catalog type)"

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Generate into a throwaway tree (EQL_CODEGEN_OUT_ROOT), NOT the live repo, so a
# parity run never mutates src/v3/scalars — a partial/failed generate can't
# corrupt the working tree, and the gate has no side effects. The temp tree
# mirrors the repo layout under src/v3/scalars/<token>/.
GEN_ROOT="$(mktemp -d)"
trap 'rm -rf "$GEN_ROOT"' EXIT
echo "==> Generating with the Rust generator into a temp tree ($GEN_ROOT)"
EQL_CODEGEN_OUT_ROOT="$GEN_ROOT" cargo run -q -p eql-codegen -- > /dev/null

# Every catalog type has a committed reference under tests/codegen/reference/<token>/,
# generated once. Discover them (each subdir is one token) and gate each against
# its generated counterpart. The Rust gate (crates/eql-codegen/tests/parity.rs,
# reference_dirs_match_catalog_tokens) asserts this dir set equals the catalog
# token set, so a new type with no reference fails there.
tokens=$(find tests/codegen/reference -mindepth 1 -maxdepth 1 -type d \
  | sed 's#.*/##' | LC_ALL=C sort)

# Completeness cross-check against the catalog (the single source of truth),
# mirroring the matrix-inventory gate in mise.toml. The per-token loop below is
# golden-DRIVEN, so a new catalog type with no committed reference dir is never
# iterated and would slip through silently. Assert the committed reference dir
# set equals `list-types` (the CATALOG tokens) first so a missing golden fails
# HERE, not only in the Rust gate (crates/eql-codegen/tests/parity.rs,
# reference_dirs_match_catalog_tokens), which remains the in-process
# belt-and-suspenders. `list-types` prints one CATALOG token per line.
catalog_tokens=$(cargo run -q -p eql-codegen -- list-types | LC_ALL=C sort -u)
if [ "$tokens" != "$catalog_tokens" ]; then
  echo "reference dirs != catalog tokens (< reference dirs, > catalog list-types):" >&2
  diff <(echo "$tokens") <(echo "$catalog_tokens") >&2 || true
  echo "A new catalog type needs a committed tests/codegen/reference/<token>/ golden." >&2
  exit 1
fi

for token in $tokens; do
  ref_dir="tests/codegen/reference/$token"
  gen_dir="$GEN_ROOT/src/v3/scalars/$token"

  echo "==> [$token] Comparing generated SQL file SET vs reference (catches extra/dropped files)"
  # The content loop below is reference-driven: it verifies every reference file has a
  # matching generated body, so a DROPPED file fails there. It cannot see an EXTRA
  # generated file (a new template output, or the new half of a rename) — that name
  # is never iterated. Assert the sets are equal first to close that blind spot.
  # The temp tree holds ONLY generated files (no committed/hand-written SQL and no
  # git tracking), so the generated set is simply every *.sql in the dir.
  # find (not `ls *.sql`) so an empty dir yields zero lines instead of aborting
  # under `set -e`; `-maxdepth 1` + sed strips the leading `./` for bare names.
  reference_set=$(cd "$ref_dir" \
    && find . -maxdepth 1 -name '*.sql' | sed 's#.*/##' | LC_ALL=C sort)
  gen_set=$(cd "$gen_dir" \
    && find . -maxdepth 1 -name '*.sql' | sed 's#.*/##' | LC_ALL=C sort)
  if [ "$reference_set" != "$gen_set" ]; then
    echo "[$token] generated SQL file set differs from reference (< reference, > generated):" >&2
    diff <(echo "$reference_set") <(echo "$gen_set") >&2 || true
    exit 1
  fi

  echo "==> [$token] Diffing Rust SQL vs reference (byte-for-byte)"
  for f in "$ref_dir"/*.sql; do
    name="$(basename "$f")"
    # Drop the 1-line `-- REFERENCE:` provenance line, then compare the remaining
    # bytes EXACTLY. Both the reference body (from line 2) and the whole generated
    # file start with the template-owned `-- AUTOMATICALLY GENERATED FILE.` marker,
    # so no header strip is needed — any whitespace or blank-line drift fails here.
    diff <(tail -n +2 "$f") "$gen_dir/$name"
  done
done

echo "PARITY OK: Rust generator matches every committed reference (byte-for-byte)."
