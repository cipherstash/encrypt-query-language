set dotenv-load
set positional-arguments


test:
  #!/usr/bin/env bash
  set -euxo pipefail
  cd "{{justfile_directory()}}"

  just build
  just reset

  connection_url=postgresql://${CS_DATABASE__USERNAME:-$USER}:@localhost:$CS_DATABASE__PORT/$CS_DATABASE__NAME

  # tests
  PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f tests/core.sql
  PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f tests/config.sql
  PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f tests/encryptindex.sql

  # Uninstall
  PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f release/cipherstash-encrypt-uninstall.sql



build:
  #!/usr/bin/env bash
  set -euxo pipefail
  cd "{{justfile_directory()}}"

  mkdir -p release

  rm -f release/cipherstash-encrypt-uninstall.sql
  rm -f release/cipherstash-encrypt.sql

  # Collect all the drops
  # In reverse order (tac) so that we drop the constraints before the tables
  grep -h -E '^(DROP)' sql/0*-*.sql | tac > release/cipherstash-encrypt-tmp-drop-install.sql
  # types are always last
  cat sql/666-drop_types.sql >> release/cipherstash-encrypt-tmp-drop-install.sql


  # Build cipherstash-encrypt.sql
  # drop everything first
  cat release/cipherstash-encrypt-tmp-drop-install.sql > release/cipherstash-encrypt.sql
  # cat the rest of the sql files
  cat sql/0*-*.sql >> release/cipherstash-encrypt.sql

  # Collect all the drops
  # In reverse order (tac) so that we drop the constraints before the tables
  grep -h -E '^(DROP|ALTER DOMAIN [^ ]+ DROP CONSTRAINT)' sql/0*-*.sql | tac > release/cipherstash-encrypt-tmp-drop-uninstall.sql
  # types are always last
  cat sql/666-drop_types.sql >> release/cipherstash-encrypt-tmp-drop-uninstall.sql


  # Build cipherstash-encrypt-uninstall.sql
  # prepend the drops to the main sql file
  cat release/cipherstash-encrypt-tmp-drop-uninstall.sql >> release/cipherstash-encrypt-uninstall.sql
  # uninstall renames configuration table
  cat sql/666-rename_configuration_table.sql >> release/cipherstash-encrypt-uninstall.sql

  # remove the drop file
  rm release/cipherstash-encrypt-tmp-drop-install.sql
  rm release/cipherstash-encrypt-tmp-drop-uninstall.sql


reset:
  #!/usr/bin/env bash
  set -euxo pipefail
  cd "{{justfile_directory()}}"

  PGPASSWORD=$CS_DATABASE__PASSWORD dropdb --force --if-exists --username ${CS_DATABASE__USERNAME:-$USER} --port $CS_DATABASE__PORT $CS_DATABASE__NAME
  PGPASSWORD=$CS_DATABASE__PASSWORD createdb --username ${CS_DATABASE__USERNAME:-$USER} --port $CS_DATABASE__PORT $CS_DATABASE__NAME

  connection_url=postgresql://${CS_DATABASE__USERNAME:-$USER}:@localhost:$CS_DATABASE__PORT/$CS_DATABASE__NAME

  PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f release/cipherstash-encrypt.sql


psql:
  psql postgresql://$CS_USERNAME:$CS_PASSWORD@localhost:$CS_PORT/$CS_DATABASE__NAME


psql_direct:
  psql --user $CS_DATABASE__USERNAME --dbname $CS_DATABASE__NAME --port $CS_DATABASE__PORT
