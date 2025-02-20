#!/usr/bin/env bash
#MISE description="Build SQL into single release file"
#MISE alias="b"
#MISE sources=["sql/*.sql"]
#MISE outputs=["release/cipherstash-encrypt.sql","release/cipherstash-encrypt-uninstall.sql"]

#!/bin/bash

set -euxo pipefail

mkdir -p release

rm -f release/cipherstash-encrypt-uninstall.sql
rm -f release/cipherstash-encrypt.sql



# ========================================================
# Drop all operators first
cat sql/666-drop-operators.sql > release/cipherstash-encrypt-tmp-drop.sql

# Collect all the drops into a single file
# In reverse order (tac) so that we drop the constraints before the tables
grep -h -E '^(DROP|ALTER DOMAIN [^ ]+ DROP CONSTRAINT)' sql/0*-*.sql | tac >> release/cipherstash-encrypt-tmp-drop.sql

# Drop types last
cat sql/666-drop-types.sql >> release/cipherstash-encrypt-tmp-drop.sql


# ========================================================
# Create cipherstash-encrypt.sql
# Drop everything first
cat release/cipherstash-encrypt-tmp-drop.sql >> release/cipherstash-encrypt.sql

# Cat all the files
cat sql/0*-*.sql >> release/cipherstash-encrypt.sql


# ========================================================
# Create uninstall
cat release/cipherstash-encrypt-tmp-drop.sql >> release/cipherstash-encrypt-uninstall.sql

# Adding configuration table rename
cat sql/666-rename_configuration_table.sql >> release/cipherstash-encrypt-uninstall.sql


# ========================================================
# remove the tmp drop file
rm release/cipherstash-encrypt-tmp-drop.sql

set +x
echo
echo '###############################################'
echo "# ✅Build succeeded"
echo '###############################################'
echo
echo 'Installer:   release/cipherstash-encrypt.sql'
echo 'Uninstaller: release/cipherstash-encrypt-uninstall.sql'
