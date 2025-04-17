#!/usr/bin/env bash
#MISE description="Build SQL into single release file"
#MISE alias="b"
#MISE sources=["sql/*.sql"]
#MISE outputs=["release/cipherstash-encrypt.sql","release/cipherstash-encrypt-uninstall.sql"]
#USAGE flag "--version <version>" help="Specify release version of EQL" default="DEV"

#!/bin/bash

# set -euxo pipefail

mkdir -p release

rm -f release/cipherstash-encrypt-uninstall.sql
rm -f release/cipherstash-encrypt.sql

rm -f src/version.sql
rm -f src/deps.txt
rm -f src/deps-ordered.txt


RELEASE_VERSION=${usage_version:-DEV}
sed "s/\$RELEASE_VERSION/$RELEASE_VERSION/g" src/version.template > src/version.sql


find src -type f -path "*.sql" ! -path "*_test.sql" | while IFS= read -r sql_file; do
    echo $sql_file

    echo "$sql_file $sql_file" >> src/deps.txt

    while IFS= read -r line; do
        # echo $line
        # Check if the line contains "-- REQUIRE:"
        if [[ "$line" == *"-- REQUIRE:"* ]]; then
            # Extract the required file(s) after "-- REQUIRE:"
            deps=${line#*-- REQUIRE: }

            # Split multiple REQUIRE declarations if present
            for dep in $deps; do
                echo "$sql_file $dep" >> src/deps.txt
            done
        fi
    done < "$sql_file"
done

cat src/deps.txt | tsort | tac > src/deps-ordered.txt

cat src/deps-ordered.txt | xargs cat | grep -v REQUIRE >> release/cipherstash-encrypt.sql

cat tasks/uninstall.sql >> release/cipherstash-encrypt-uninstall.sql

set +x
echo
echo '###############################################'
echo "# ✅Build succeeded"
echo '###############################################'
echo
echo 'Installer:   release/cipherstash-encrypt.sql'
echo 'Uninstaller: release/cipherstash-encrypt-uninstall.sql'
