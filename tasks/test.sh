  #!/usr/bin/env bash
  #MISE description="Build, reset and run test"

  #!/bin/bash

  set -euxo pipefail

  mise run build
  mise run reset

  connection_url=postgresql://${CS_DATABASE__USERNAME:-$USER}:@localhost:$CS_DATABASE__PORT/$CS_DATABASE__NAME

  # tests
  PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f tests/core.sql
  PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f tests/core-functions.sql
  PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f tests/config.sql
  PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f tests/encryptindex.sql
  PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f tests/operators.sql

  # Uninstall
  PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f release/cipherstash-encrypt-uninstall.sql

