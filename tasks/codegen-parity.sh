#!/usr/bin/env bash
#MISE description="Parity gate: Rust eql-codegen output matches the committed reference SQL files (byte-for-byte, every catalog type)"

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Generating with the Rust generator (writes the real repo tree)"
cargo run -q -p eql-codegen -- > /dev/null

# Every catalog type has a committed reference under tests/codegen/reference/<token>/,
# generated once. Discover them (each subdir is one token) and gate each against
# its generated counterpart. The Rust gate (crates/eql-codegen/tests/parity.rs,
# reference_dirs_match_catalog_tokens) asserts this dir set equals the catalog
# token set, so a new type with no reference fails there.
tokens=$(find tests/codegen/reference -mindepth 1 -maxdepth 1 -type d \
  | sed 's#.*/##' | LC_ALL=C sort)

for token in $tokens; do
  ref_dir="tests/codegen/reference/$token"
  gen_dir="src/v3/scalars/$token"

  echo "==> [$token] Comparing generated SQL file SET vs reference (catches extra/dropped files)"
  # The content loop below is reference-driven: it verifies every reference file has a
  # matching generated body, so a DROPPED file fails there. It cannot see an EXTRA
  # generated file (a new template output, or the new half of a rename) — that name
  # is never iterated. Assert the sets are equal first to close that blind spot.
  # "Generated" excludes any committed, hand-written SQL (e.g. <token>_extensions.sql),
  # which lives in this dir but has no reference counterpart; git-tracked == hand-written.
  # find (not `ls *.sql`) so an empty dir yields zero lines instead of aborting
  # under `set -e`; `-maxdepth 1` + sed strips the leading `./` for bare names.
  reference_set=$(cd "$ref_dir" \
    && find . -maxdepth 1 -name '*.sql' | sed 's#.*/##' | LC_ALL=C sort)
  gen_set=$(cd "$gen_dir" \
    && comm -23 <(find . -maxdepth 1 -name '*.sql' | sed 's#.*/##' | LC_ALL=C sort) \
                <(git ls-files . | sed 's#.*/##' | LC_ALL=C sort))
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
