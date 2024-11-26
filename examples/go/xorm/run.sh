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
  # constraints and indexes
  go run . setupDev
}

subproject_tests(){
  #  run e2e tests
  make gotest
}

subcommand="${1:-test}"
case $subcommand in
  setup)
    subproject_setup
    ;;

  tests)
    subproject_tests
    ;;

  *)
    echo "Unknown run subcommand '$subcommand'"
    exit 1
    ;;
esac
