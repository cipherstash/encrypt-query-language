#!/usr/bin/env bash
set -euo pipefail

# Ensure PostgreSQL is running
if ! pg_isready -h localhost -p 7432 -U cipherstash > /dev/null 2>&1; then
    echo "❌ PostgreSQL not running on localhost:7432"
    echo "   Start it with: mise run postgres:up"
    exit 1
fi

# Ensure release SQL is built
if [ ! -f "../release/cipherstash-encrypt.sql" ]; then
    echo "📦 Building EQL release..."
    (cd .. && mise run build)
fi

echo "🧪 Running SQLx tests..."
cargo test "$@"
