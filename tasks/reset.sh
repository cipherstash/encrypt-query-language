#!/bin/bash
#MISE description="Uninstall and install EQL to local postgres"
#USAGE flag "--postgres <version>" help="Run tests for specified Postgres version" default="17" {
#USAGE   choices "14" "15" "16" "17"
#USAGE }

set -euxo pipefail

POSTGRES_VERSION=${usage_postgres}

connection_url=postgresql://${POSTGRES_USER:-$USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
container_name=postgres-${POSTGRES_VERSION}

# Uninstall
cat release/cipherstash-encrypt-uninstall.sql | docker exec -i ${container_name} psql ${connection_url} -f-

# Install
cat release/cipherstash-encrypt.sql | docker exec -i ${container_name} psql ${connection_url} -f-
