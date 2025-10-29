#!/usr/bin/env bash
#MISE description="Check if PostgreSQL container is running"

set -euo pipefail

POSTGRES_VERSION=${1:-${POSTGRES_VERSION:-17}}
container_name=postgres-${POSTGRES_VERSION}

containers=$(docker ps --filter "name=^${container_name}$" --quiet)
if [ -z "${containers}" ]; then
  echo "error: Docker container for PostgreSQL is not running"
  echo "error: Try running 'mise run postgres:up postgres-${POSTGRES_VERSION}' to start the container"
  exit 65
fi

echo "✓ PostgreSQL ${POSTGRES_VERSION} container is running"
