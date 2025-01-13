#!/usr/bin/env bash
#MISE description="Build, reset and run test"

#!/bin/bash

set -euxo pipefail

mise run build
mise run reset

connection_url=postgresql://${POSTGRES_USER:-$USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
container_name=postgres-${POSTGRES_VERSION}

# # tests
# PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f tests/core.sql
# PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f tests/core-functions.sql
# PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f tests/config.sql
# PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f tests/encryptindex.sql
cat tests/operators.sql | docker exec -i ${container_name} psql ${connection_url} -f-
