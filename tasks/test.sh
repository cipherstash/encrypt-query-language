#!/usr/bin/env bash
#MISE description="Build, reset and run tests"
#USAGE flag "--test <test>" help="Test to run" default="false"
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
  echo "# Running Test: ${1}"
  echo '###############################################'
  echo

  cat $1 | docker exec -i ${container_name} psql --variable ON_ERROR_STOP=1 $connection_url -f-
}

# setup
fail_if_postgres_not_running
mise run build --force
mise run reset --force --postgres ${POSTGRES_VERSION}


# Install
# cat release/cipherstash-encrypt.sql | docker exec -i ${container_name} psql ${connection_url} -f-
if cat release/cipherstash-encrypt.sql | docker exec -i ${container_name} psql ${connection_url} -f- | grep -q "ERROR"; then
  echo
  echo '******************************************************'
  echo '* ❌ ERROR installing release/cipherstash-encrypt.sql'
  echo '******************************************************'
  echo

  exit 1
fi


cat tests/test_helpers.sql | docker exec -i ${container_name} psql ${connection_url} -f-
cat tests/ore.sql | docker exec -i ${container_name} psql ${connection_url} -f-

if [ $usage_test = "false" ]; then
  find src -type f -path "*_test.sql" | while read -r sql_file; do
    echo $sql_file
    run_test $sql_file
  done
else
  find src -type f -path "*$usage_test*" | while read -r sql_file; do
    run_test $sql_file
  done
fi

echo
echo '###############################################'
echo "# ✅ALL TESTS PASSED "
echo '###############################################'
echo
