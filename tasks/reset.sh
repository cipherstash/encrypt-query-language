  #!/usr/bin/env bash
  #MISE description="Clean install of EQL"
  set -euxo pipefail

#   PGPASSWORD=$CS_DATABASE__PASSWORD dropdb --force --if-exists --username ${CS_DATABASE__USERNAME:-$USER} --port $CS_DATABASE__PORT $CS_DATABASE__NAME
#   PGPASSWORD=$CS_DATABASE__PASSWORD createdb --username ${CS_DATABASE__USERNAME:-$USER} --port $CS_DATABASE__PORT $CS_DATABASE__NAME

  connection_url=postgresql://${CS_DATABASE__USERNAME:-$USER}:@localhost:$CS_DATABASE__PORT/$CS_DATABASE__NAME

  PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f release/cipherstash-encrypt.sql