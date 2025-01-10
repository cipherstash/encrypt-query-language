#!/usr/bin/env bash
#MISE description="Build SQL into single release file"
#MISE sources=["sql/*.sql"]
#MISE outputs=["release/cipherstash-encrypt.sql","release/cipherstash-encrypt-uninstall.sql"]

#!/bin/bash

set -euxo pipefail

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
