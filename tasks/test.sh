#!/usr/bin/env bash
#MISE description="Build, reset and run tests"
#USAGE flag "--postgres <version>" help="Run tests for specified Postgres version" default="17" {
#USAGE   choices "14" "15" "16" "17"
#USAGE }

#!/bin/bash

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

run_test () {
  echo
  echo '###############################################'
  echo "# ${1}"
  echo '###############################################'
  echo
  cat $1 | docker exec -i ${container_name} psql $connection_url -f-
}

# setup
fail_if_postgres_not_running
mise run build
mise run reset --postgres ${POSTGRES_VERSION}

# tests
run_test tests/core.sql
run_test tests/core-functions.sql
run_test tests/config.sql
run_test tests/encryptindex.sql
run_test tests/operators-eq.sql
run_test tests/operators-match.sql
run_test tests/operators-ore.sql

echo
echo '###############################################'
echo "# ✅ALL TESTS PASSED "
echo '###############################################'
echo
