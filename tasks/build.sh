#!/usr/bin/env bash
#MISE description="Build SQL into single release file"
#MISE alias="b"
#MISE sources=["sql/*.sql"]
#MISE outputs=["release/cipherstash-encrypt.sql","release/cipherstash-encrypt-uninstall.sql"]
#USAGE flag "--version <version>" help="Specify release version of EQL" default="DEV"

#!/bin/bash

set -euxo pipefail

mkdir -p release

rm -f release/cipherstash-encrypt-uninstall.sql
rm -f release/cipherstash-encrypt.sql

rm -f sql/000-version.sql

RELEASE_VERSION=${usage_version}
sed "s/\$RELEASE_VERSION/$RELEASE_VERSION/g" tasks/000-version-template.sql > sql/000-version.sql


# Collect all the drops
# In reverse order (tac) so that we drop the constraints before the tables
grep -h -E '^(DROP)' sql/0*-*.sql | tac > release/cipherstash-encrypt-tmp-drop-install.sql
# types are always last
cat sql/666-drop_types.sql >> release/cipherstash-encrypt-tmp-drop-install.sql


# Build cipherstash-encrypt.sql
# drop everything first
cat sql/666-drop-operators.sql > release/cipherstash-encrypt.sql
cat release/cipherstash-encrypt-tmp-drop-install.sql >> release/cipherstash-encrypt.sql
# cat the rest of the sql files
cat sql/0*-*.sql >> release/cipherstash-encrypt.sql

# Collect all the drops
# In reverse order (tac) so that we drop the constraints before the tables
grep -h -E '^(DROP|ALTER DOMAIN [^ ]+ DROP CONSTRAINT)' sql/0*-*.sql | tac > release/cipherstash-encrypt-tmp-drop-uninstall.sql
# types are always last
cat sql/666-drop_types.sql >> release/cipherstash-encrypt-tmp-drop-uninstall.sql


# Build cipherstash-encrypt-uninstall.sql
# prepend the drops to the main sql file
cat sql/666-drop-operators.sql >> release/cipherstash-encrypt-uninstall.sql
cat release/cipherstash-encrypt-tmp-drop-uninstall.sql >> release/cipherstash-encrypt-uninstall.sql


# uninstall renames configuration table
cat sql/666-rename_configuration_table.sql >> release/cipherstash-encrypt-uninstall.sql

# remove the drop file
rm release/cipherstash-encrypt-tmp-drop-install.sql
rm release/cipherstash-encrypt-tmp-drop-uninstall.sql

set +x
echo
echo '###############################################'
echo "# ✅Build succeeded"
echo '###############################################'
echo
echo 'Installer:   release/cipherstash-encrypt.sql'
echo 'Uninstaller: release/cipherstash-encrypt-uninstall.sql'
