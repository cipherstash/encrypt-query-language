#!/usr/bin/env bash
#MISE description="Run legacy SQL tests (inline test files)"
#USAGE flag "--test <test>" help="Specific test file pattern to run" default="false"
#USAGE flag "--postgres <version>" help="PostgreSQL version to test against" default="17" {
#USAGE   choices "14" "15" "16" "17"
#USAGE }

set -euo pipefail

POSTGRES_VERSION=${usage_postgres}

connection_url=postgresql://${POSTGRES_USER:-$USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
container_name=postgres-${POSTGRES_VERSION}

# Check postgres is running (script will exit if not)
source "$(dirname "$0")/check-postgres.sh" ${POSTGRES_VERSION}

run_test () {
  echo
  echo '###############################################'
  echo "# Running Test: ${1}"
  echo '###############################################'
  echo

  cat $1 | docker exec -i ${container_name} psql --variable ON_ERROR_STOP=1 $connection_url -f-
}

# Reset database
mise run reset --force --postgres ${POSTGRES_VERSION}

echo
echo '###############################################'
echo '# Installing release/cipherstash-encrypt.sql'
echo '###############################################'
echo

# Install
cat release/cipherstash-encrypt.sql | docker exec -i ${container_name} psql ${connection_url} -f-


cat tests/test_helpers.sql | docker exec -i ${container_name} psql ${connection_url} -f-
cat tests/ore.sql | docker exec -i ${container_name} psql ${connection_url} -f-
cat tests/ste_vec.sql | docker exec -i ${container_name} psql ${connection_url} -f-


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
