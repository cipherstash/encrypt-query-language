#!/usr/bin/env bash
#MISE description="Run all tests (legacy SQL + SQLx Rust)"
#USAGE flag "--postgres <version>" help="PostgreSQL version to test against" default="17" {
#USAGE   choices "14" "15" "16" "17"
#USAGE }

set -euo pipefail

POSTGRES_VERSION=${usage_postgres}

echo "=========================================="
echo "Running Complete EQL Test Suite"
echo "PostgreSQL Version: $POSTGRES_VERSION"
echo "=========================================="
echo ""

# Check PostgreSQL is running
"$(dirname "$0")/check-postgres.sh" ${POSTGRES_VERSION}

# Build first
echo "Building EQL..."
mise run build --force

# Run legacy SQL tests
echo ""
echo "=========================================="
echo "1/2: Running Legacy SQL Tests"
echo "=========================================="
mise run test:legacy --postgres ${POSTGRES_VERSION}

# Run SQLx Rust tests
echo ""
echo "=========================================="
echo "2/2: Running SQLx Rust Tests"
echo "=========================================="
mise run test:sqlx

echo ""
echo "=========================================="
echo "✅ ALL TESTS PASSED"
echo "=========================================="
echo ""
echo "Summary:"
echo "  ✓ Legacy SQL tests"
echo "  ✓ SQLx Rust tests"
echo ""
