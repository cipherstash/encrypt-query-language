set dotenv-load
set positional-arguments


test_dsl:
  #!/usr/bin/env bash
  set -euxo pipefail

  PGPASSWORD=$CS_DATABASE__PASSWORD dropdb --force --if-exists --username $CS_DATABASE__USERNAME --port $CS_DATABASE__PORT cs_migrator_test
  PGPASSWORD=$CS_DATABASE__PASSWORD createdb --username $CS_DATABASE__USERNAME --port $CS_DATABASE__PORT cs_migrator_test

  connection_url=postgresql://$CS_DATABASE__USERNAME:@localhost:$CS_DATABASE__PORT/cs_migrator_test
  PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f sql/dsl-core.sql
  PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f sql/dsl-config-schema.sql
  PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f sql/dsl-config-functions.sql
  PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f sql/dsl-encryptindex.sql

  # tests
  PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f tests/core.sql
  PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f tests/config.sql
  PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f tests/encryptindex.sql

  dropdb --username $CS_DATABASE__USERNAME --port $CS_DATABASE__PORT cs_migrator_test


build:
  #!/usr/bin/env bash
  set -euxo pipefail

  cat sql/database-extensions/postgresql/install.sql sql/dsl-core.sql sql/dsl-config-schema.sql sql/dsl-config-functions.sql sql/dsl-encryptindex.sql > release/cipherstash-encrypt-dsl.sql

  cat sql/dsl-drop.sql > release/cipherstash-encrypt-dsl-uninstall.sql
  grep -h '^DROP' sql/*.sql | tac >> release/cipherstash-encrypt-dsl-uninstall.sql

psql:
  psql postgresql://$CS_USERNAME:$CS_PASSWORD@localhost:$CS_PORT/$CS_DATABASE__NAME


psql_direct:
  psql --user $CS_DATABASE__USERNAME --dbname $CS_DATABASE__NAME --port $CS_DATABASE__PORT
