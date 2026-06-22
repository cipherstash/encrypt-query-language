#!/usr/bin/env bash
#MISE description="Fail if any user-facing doc still references the removed eql_v2 surface"

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Tier-1 user-facing docs that MUST be eql_v2-free after the eql_v3 migration.
# A file deleted by the migration (e.g. index-config.md) is simply skipped.
TIER1=(
  "README.md"
  "docs/README.md"
  "docs/reference/eql-functions.md"
  "docs/reference/query-performance.md"
  "docs/reference/database-indexes.md"
  "docs/tutorials/proxy-configuration.md"
  "docs/reference/json-support.md"
  "docs/reference/sql-support.md"
  "docs/reference/index-config.md"
  "docs/reference/adding-a-scalar-encrypted-domain-type.md"
)

# Tier-2 docs are retained on purpose and deliberately NOT checked:
#   docs/upgrading/v2.3.md            historical upgrade guide *for v2.3*
#   docs/decisions/0001-remove-eql-v2.md  the ADR describing the removal
# Their eql_v2 references are correct and must stay.

status=0
for f in "${TIER1[@]}"; do
  [ -f "$f" ] || continue
  if hits=$(grep -nE 'eql_v2' "$f"); then
    echo "FAIL: $f still references eql_v2:" >&2
    echo "$hits" >&2
    status=1
  fi
done

if [ "$status" -eq 0 ]; then
  echo "OK: no Tier-1 doc references eql_v2."
fi
exit "$status"
