#!/usr/bin/env bash
# Count assertions in SQL vs Rust tests for verification

set -euo pipefail

echo "=== Test Assertion Counts ==="
echo ""
echo "SQL Tests:"
echo "  Equality (=_test.sql):  $(grep -c 'PERFORM assert' src/operators/=_test.sql)"
echo "  JSONB (functions_test.sql): $(grep -c 'PERFORM assert' src/jsonb/functions_test.sql)"
echo ""
echo "Rust Tests:"
echo "  Equality: $(grep -c '^#\[sqlx::test' tests/sqlx/tests/equality_tests.rs)"
echo "  JSONB: $(grep -c '^#\[sqlx::test' tests/sqlx/tests/jsonb_tests.rs)"
echo ""
echo "Coverage:"
sql_total=$(($(grep -c 'PERFORM assert' src/operators/=_test.sql) + $(grep -c 'PERFORM assert' src/jsonb/functions_test.sql)))
rust_total=$(($(grep -c '^#\[sqlx::test' tests/sqlx/tests/equality_tests.rs) + $(grep -c '^#\[sqlx::test' tests/sqlx/tests/jsonb_tests.rs)))
coverage=$(awk "BEGIN {printf \"%.1f\", ($rust_total/$sql_total)*100}")
echo "  Total: ${rust_total}/${sql_total} assertions ($coverage%)"
