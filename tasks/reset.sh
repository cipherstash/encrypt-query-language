#!/bin/bash
#MISE description="Uninstall and install EQL to local postgres"

set -euxo pipefail

connection_url=postgresql://${POSTGRES_USER:-$USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
container_name=postgres-${POSTGRES_VERSION}

# Uninstall
cat release/cipherstash-encrypt-uninstall.sql | docker exec -i ${container_name} psql ${connection_url} -f-

# Install
cat release/cipherstash-encrypt.sql | docker exec -i ${container_name} psql ${connection_url} -f-
