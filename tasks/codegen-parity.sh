#!/usr/bin/env bash
#MISE description="Parity gate: Rust eql-codegen output matches the int4 golden (normalized) and committed values.rs"

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Generating with the Rust generator (writes the real repo tree)"
cargo run -q -p eql-codegen -- > /dev/null

echo "==> Diffing Rust int4 SQL vs golden reference (line-normalized)"
norm() { sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | grep -v '^$'; }
for f in tests/codegen/reference/int4/*.sql; do
  name="$(basename "$f")"
  # Reference: drop the 1-line `-- REFERENCE:` provenance line. What remains —
  # and the whole generated file — both start with the template-owned
  # `-- AUTOMATICALLY GENERATED FILE.` marker, so no header strip is needed.
  diff <(tail -n +2 "$f" | norm) \
       <(norm < "src/encrypted_domain/int4/$name")
done

echo "==> Verifying committed <T>_values.rs are byte-identical (git clean)"
git diff --exit-code -- tests/sqlx/src/fixtures/*_values.rs

echo "PARITY OK: Rust generator matches the int4 golden (normalized) and committed values.rs."
