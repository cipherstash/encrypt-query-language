#!/usr/bin/env bash
#MISE description="Run benchmark / regression / scale SQLx tests (--features bench)"
#USAGE flag "--postgres <version>" help="PostgreSQL version" default="17" {
#USAGE   choices "14" "15" "16" "17"
#USAGE }

set -euo pipefail

POSTGRES_VERSION=${usage_postgres}

echo "=========================================="
echo "Running EQL Bench Suite"
echo "PostgreSQL Version: $POSTGRES_VERSION"
echo "=========================================="

"$(dirname "$0")/../postgres/check_container.sh" "${POSTGRES_VERSION}"

echo "Building EQL..."
mise run --output prefix --force build

echo "Updating SQLx migrations with built EQL..."
cp release/cipherstash-encrypt.sql tests/sqlx/migrations/001_install_eql.sql

echo "Running SQLx migrations..."
(cd tests/sqlx && sqlx migrate run)

echo "Running bench tests (cargo test --features bench)..."
(cd tests/sqlx && cargo test --features bench)
