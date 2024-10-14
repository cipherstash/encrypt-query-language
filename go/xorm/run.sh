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

subproject_start_postgres() {
  docker compose up -d
}

subproject_stop_postgres() {
  docker compose down
}

subproject_start_proxy() {
  cd ../../../packages/cipherstash-proxy
  cargo run
}

subcommand="${1:-test}"
case $subcommand in
  start_postgres)
    subproject_start_postgres
    ;;

  stop_postgres)
    subproject_stop_postgres
    ;;

  install_eql)
    subproject_install_eql
    ;;

  start_proxy)
    subproject_start_proxy
    ;;

  *)
    echo "Unknown run subcommand '$subcommand'"
    exit 1
    ;;
esac
