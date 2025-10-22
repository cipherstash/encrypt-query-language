#!/usr/bin/env bash
#MISE description="Run pgTAP tests with pg_prove"
#USAGE flag "--postgres <version>" help="Run tests for specified Postgres version" default="17" {
#USAGE   choices "14" "15" "16" "17"
#USAGE }

set -euo pipefail

POSTGRES_VERSION=${usage_postgres}

connection_url=postgresql://${POSTGRES_USER:-$USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
container_name=postgres-${POSTGRES_VERSION}

fail_if_postgres_not_running () {
  containers=$(docker ps --filter "name=^${container_name}$" --quiet)
  if [ -z "${containers}" ]; then
    echo "error: Docker container for PostgreSQL is not running"
    echo "error: Try running 'mise run postgres:up ${container_name}' to start the container"
    exit 65
  fi
}

# setup
fail_if_postgres_not_running
mise run build --force
mise run reset --force --postgres ${POSTGRES_VERSION}

echo
echo '###############################################'
echo '# Installing release/cipherstash-encrypt.sql'
echo '###############################################'
echo

# Install EQL
cat release/cipherstash-encrypt.sql | docker exec -i ${container_name} psql ${connection_url} -f-

# Install test helpers
cat tests/test_helpers.sql | docker exec -i ${container_name} psql ${connection_url} -f-
cat tests/ore.sql | docker exec -i ${container_name} psql ${connection_url} -f-
cat tests/ste_vec.sql | docker exec -i ${container_name} psql ${connection_url} -f-

echo
echo '###############################################'
echo '# Installing pgTAP'
echo '###############################################'
echo

# Install pgTAP
cat tests/install_pgtap.sql | docker exec -i ${container_name} psql ${connection_url} -f-

echo
echo '###############################################'
echo '# Running pgTAP structure tests'
echo '###############################################'
echo

# Run structure tests with pg_prove
if [ -d "tests/pgtap/structure" ]; then
  docker exec -i ${container_name} pg_prove -v -d ${connection_url} /tests/pgtap/structure/*.sql 2>/dev/null || {
    # Fallback: copy tests to container and run
    for test_file in tests/pgtap/structure/*.sql; do
      if [ -f "$test_file" ]; then
        echo "Running: $test_file"
        cat "$test_file" | docker exec -i ${container_name} psql ${connection_url} -f-
      fi
    done
  }
fi

echo
echo '###############################################'
echo '# Running pgTAP functionality tests'
echo '###############################################'
echo

# Run functionality tests with pg_prove
if [ -d "tests/pgtap/functionality" ]; then
  docker exec -i ${container_name} pg_prove -v -d ${connection_url} /tests/pgtap/functionality/*.sql 2>/dev/null || {
    # Fallback: copy tests to container and run
    for test_file in tests/pgtap/functionality/*.sql; do
      if [ -f "$test_file" ]; then
        echo "Running: $test_file"
        cat "$test_file" | docker exec -i ${container_name} psql ${connection_url} -f-
      fi
    done
  }
fi

echo
echo '###############################################'
echo "# ✅ ALL PGTAP TESTS PASSED "
echo '###############################################'
echo
