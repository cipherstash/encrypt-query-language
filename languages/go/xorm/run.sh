#!/usr/bin/env bash

# exits when a command fails
# exits when script tries to use undeclared variables
# exit status is the value of the last command to exit with a non-zero status, or zero if all commands exit successfully
set -euo pipefail

if [[ -n "${DEBUG_RUN_SH:-}" ]]; then
  set -x # trace what gets executed (useful for debugging)
fi

if [ "${BASH_SOURCE[0]}" != "./run.sh" ]; then
  echo "Please run this script as ./run.sh"
  exit 1
fi

subproject_setup() {
  # start postgres and proxy
  docker compose up -d
  # setup table, install eql, constraints and indexes
  go run . setupDev
}

subproject_teardown() {
  # start postgres
  docker compose down
}

subproject_examples() {
  # reset db
  go run . setupDev

  # run examples queries
  go run . runExamples
}

subproject_tests(){
   # start postgres and proxy
  docker compose up -d
  # reset db
  go run . setupDev
  #  run e2e tests
  make gotest
  #  run goeql tests
  cd ../goeql
  go test
}

subproject_start_proxy() {
 docker run --env-file .env -p 6432:6432 cipherstash/cipherstash-proxy:latest
}

subcommand="${1:-test}"
case $subcommand in
  setup)
    subproject_setup
    ;;

  teardown)
    subproject_teardown
    ;;

  examples)
    subproject_examples
    ;;

  tests)
    subproject_tests
    ;;

  *)
    echo "Unknown run subcommand '$subcommand'"
    exit 1
    ;;
esac
