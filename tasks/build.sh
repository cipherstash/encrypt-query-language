#!/usr/bin/env bash
#MISE description="Build SQL into single release file"
#MISE alias="b"
#MISE sources=["src/**/*.sql", "tasks/pin_search_path.sql", "tasks/uninstall.sql", "tasks/uninstall-protect.sql"]
#MISE outputs=["release/cipherstash-encrypt.sql","release/cipherstash-encrypt-uninstall.sql","release/cipherstash-encrypt-protect.sql","release/cipherstash-encrypt-protect-uninstall.sql"]
#USAGE flag "--version <version>" help="Specify release version of EQL" default="DEV"

#!/bin/bash

set -euo pipefail

# Fail loudly if any file referenced in a tsorted dep list doesn't exist.
# Without this, `xargs cat` would print `cat: foo.sql: No such file or directory`
# and continue — silently producing an incomplete release artefact.
verify_deps_exist() {
  local dep_file=$1
  local missing=0
  while IFS= read -r f; do
    if [[ ! -f "$f" ]]; then
      echo "ERROR: $dep_file references missing file: $f" >&2
      missing=1
    fi
  done < "$dep_file"
  if [[ $missing -ne 0 ]]; then
    echo "ERROR: dependency graph references missing files (see above). Check -- REQUIRE: directives." >&2
    exit 1
  fi
}

mkdir -p release

rm -f release/cipherstash-encrypt-uninstall.sql
rm -f release/cipherstash-encrypt.sql

rm -f release/cipherstash-encrypt-uninstall-supabase.sql
rm -f release/cipherstash-encrypt-supabase.sql

rm -f release/cipherstash-encrypt-protect.sql
rm -f release/cipherstash-encrypt-protect-uninstall.sql

rm -f dbdev/eql--0.0.0.sql

rm -f src/version.sql
rm -f src/deps.txt
rm -f src/deps-ordered.txt
rm -f src/deps-supabase.txt
rm -f src/deps-ordered-supabase.txt
rm -f src/deps-protect.txt
rm -f src/deps-ordered-protect.txt


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
verify_deps_exist src/deps-ordered.txt

cat src/deps-ordered.txt | xargs cat | grep -v REQUIRE >> release/cipherstash-encrypt.sql
cat tasks/pin_search_path.sql >> release/cipherstash-encrypt.sql

cat tasks/uninstall.sql >> release/cipherstash-encrypt-uninstall.sql


# Supabase specific build which excludes operator classes as they are not supported
find src -type f -path "*.sql" ! -path "*_test.sql" ! -path "**/*operator_class.sql" | while IFS= read -r sql_file; do
    echo $sql_file

    echo "$sql_file $sql_file" >> src/deps-supabase.txt

    while IFS= read -r line; do
        # echo $line
        # Check if the line contains "-- REQUIRE:"
        if [[ "$line" == *"-- REQUIRE:"* ]]; then
            # Extract the required file(s) after "-- REQUIRE:"
            deps=${line#*-- REQUIRE: }

            # Split multiple REQUIRE declarations if present
            for dep in $deps; do
                echo "$sql_file $dep" >> src/deps-supabase.txt
            done
        fi
    done < "$sql_file"
done


cat src/deps-supabase.txt | tsort | tac > src/deps-ordered-supabase.txt
verify_deps_exist src/deps-ordered-supabase.txt

cat src/deps-ordered-supabase.txt | xargs cat | grep -v REQUIRE >> release/cipherstash-encrypt-supabase.sql
cat tasks/pin_search_path.sql >> release/cipherstash-encrypt-supabase.sql

cat src/deps-ordered-supabase.txt | xargs cat | grep -v REQUIRE >> dbdev/eql--0.0.0.sql
cat tasks/pin_search_path.sql >> dbdev/eql--0.0.0.sql

cat tasks/uninstall.sql >> release/cipherstash-encrypt-uninstall-supabase.sql


# Protect variant build - excludes config management and encryptindex
find src -type f -path "*.sql" ! -path "*_test.sql" ! -path "**/config/*" ! -path "**/encryptindex/*" | while IFS= read -r sql_file; do
    echo $sql_file

    echo "$sql_file $sql_file" >> src/deps-protect.txt

    while IFS= read -r line; do
        if [[ "$line" == *"-- REQUIRE:"* ]]; then
            deps=${line#*-- REQUIRE: }
            for dep in $deps; do
                echo "$sql_file $dep" >> src/deps-protect.txt
            done
        fi
    done < "$sql_file"
done

cat src/deps-protect.txt | tsort | tac > src/deps-ordered-protect.txt
verify_deps_exist src/deps-ordered-protect.txt

cat src/deps-ordered-protect.txt | xargs cat | grep -v REQUIRE >> release/cipherstash-encrypt-protect.sql
cat tasks/pin_search_path.sql >> release/cipherstash-encrypt-protect.sql

cat tasks/uninstall-protect.sql >> release/cipherstash-encrypt-protect-uninstall.sql


echo
echo '###############################################'
echo "# ✅Build succeeded"
echo '###############################################'
echo
echo 'Installer:'
echo '    release/cipherstash-encrypt.sql'
echo '    release/cipherstash-encrypt-supabase.sql'
echo '    release/cipherstash-encrypt-protect.sql'
echo
echo 'Uninstaller:'
echo '    release/cipherstash-encrypt-uninstall.sql'
echo '    release/cipherstash-encrypt-uninstall-supabase.sql'
echo '    release/cipherstash-encrypt-protect-uninstall.sql'
