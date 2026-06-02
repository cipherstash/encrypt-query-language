#!/usr/bin/env bash
#MISE description="Parity gate: Rust eql-codegen output matches the int4 golden (byte-for-byte)"

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Generating with the Rust generator (writes the real repo tree)"
cargo run -q -p eql-codegen -- > /dev/null

echo "==> Comparing int4 generated SQL file SET vs golden (catches extra/dropped files)"
# The content loop below is golden-driven: it verifies every golden file has a
# matching generated body, so a DROPPED file fails there. It cannot see an EXTRA
# generated file (a new template output, or the new half of a rename) — that name
# is never iterated. Assert the sets are equal first to close that blind spot.
# "Generated" excludes any committed, hand-written SQL (e.g. int4_extensions.sql),
# which lives in this dir but has no golden counterpart; git-tracked == hand-written.
golden_set=$(cd tests/codegen/reference/int4 && ls *.sql | LC_ALL=C sort)
gen_set=$(cd src/encrypted_domain/int4 \
  && comm -23 <(ls *.sql | LC_ALL=C sort) \
              <(git ls-files . | sed 's#.*/##' | LC_ALL=C sort))
if [ "$golden_set" != "$gen_set" ]; then
  echo "int4 generated SQL file set differs from golden (< golden, > generated):" >&2
  diff <(echo "$golden_set") <(echo "$gen_set") >&2 || true
  exit 1
fi

echo "==> Diffing Rust int4 SQL vs golden reference (byte-for-byte)"
for f in tests/codegen/reference/int4/*.sql; do
  name="$(basename "$f")"
  # Drop the 1-line `-- REFERENCE:` provenance line, then compare the remaining
  # bytes EXACTLY. Both the reference body (from line 2) and the whole generated
  # file start with the template-owned `-- AUTOMATICALLY GENERATED FILE.` marker,
  # so no header strip is needed — any whitespace or blank-line drift fails here.
  diff <(tail -n +2 "$f") "src/encrypted_domain/int4/$name"
done

echo "PARITY OK: Rust generator matches the int4 golden (byte-for-byte)."
