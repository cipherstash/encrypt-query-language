#!/usr/bin/env bash
#MISE description="Build, reset and run tests"
#USAGE flag "--postgres <version>" help="Run tests for specified Postgres version" default="17" {
#USAGE   choices "14" "15" "16" "17"
#USAGE }

#!/bin/bash

set -euo pipefail

POSTGRES_VERSION=${usage_postgres}

mise run build
mise run reset --postgres ${POSTGRES_VERSION}

connection_url=postgresql://${POSTGRES_USER:-$USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
container_name=postgres-${POSTGRES_VERSION}

run_test () {
  echo
  echo '###############################################'
  echo "# ${1}"
  echo '###############################################'
  echo
  cat $1 | docker exec -i ${container_name} psql $connection_url -f-
}

# tests
run_test tests/core.sql
run_test tests/core-functions.sql
run_test tests/config.sql
run_test tests/encryptindex.sql
run_test tests/operators.sql

echo
echo '###############################################'
echo "# ✅ALL TESTS PASSED "
echo '###############################################'
echo
