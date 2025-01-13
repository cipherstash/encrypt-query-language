#!/usr/bin/env bash
#MISE description="Build, reset and run test"

#!/bin/bash

set -eo pipefail

if [ -z "${POSTGRES_VERSION}" ]; then
  echo "error: POSTGRES_VERSION not set"
  echo "Please re-run with a version set:"
  echo
  echo "POSTGRES_VERSION=16 mise run test"
  echo
  exit 1
fi

set -u

mise run build
mise run reset

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
