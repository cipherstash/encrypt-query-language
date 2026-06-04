#!/usr/bin/env bash
#MISE description="Build SQL into single release file"
#MISE alias="b"
#USAGE flag "--version <version>" help="Specify release version of EQL" default="DEV"

#!/bin/bash

set -euo pipefail

# Regenerate encrypted-domain SQL from the Rust catalog before building.
# Generated files (src/v3/scalars/<T>/<T>_*.sql) are gitignored; the
# catalog at crates/eql-scalars/src (eql-scalars::CATALOG) is the source of
# truth, rendered by the eql-codegen binary.
#
# Nuke every generated file first so a type removed from the catalog can't
# leave orphans in src/ that the `src/**/*.sql` build glob would silently
# pick up. eql-codegen cleans within a directory it regenerates, but never
# runs for a type no longer in the catalog. Hand-written *_extensions.sql is
# preserved by the name patterns; -mindepth 2 keeps the type-agnostic
# src/v3/scalars/functions.sql safe.
find src/v3/scalars -mindepth 2 -type f \
  \( -name '*_types.sql' -o -name '*_functions.sql' -o -name '*_operators.sql' \
     -o -name '*_aggregates.sql' \) \
  -delete 2>/dev/null || true

# Regenerate every type — the catalog (eql-scalars::CATALOG) is the single
# source of truth for the enumeration; eql-codegen renders all SQL in one
# deterministic run. The plaintext fixture lists are not generated — the SQLx
# tests read them straight from the catalog (eql_scalars::INT4_VALUES / …). The
# orphan sweep above still handles the catalog-removed case the generator cannot.
cargo run -p eql-codegen

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

# Fail loudly if any v3 REQUIRE edge points OUTSIDE src/v3. The v3-only build
# must be self-contained (no eql_v2 coupling); a stray `-- REQUIRE: src/...`
# edge to a non-v3 file would silently pull eql_v2 SQL into the v3 artefact (or
# tsort would drop it), breaking self-containment. Each line in deps-v3.txt is
# "<file> <dep>"; self-edges (file == dep) are skipped, every other dep target
# must start with src/v3/.
verify_v3_self_contained() {
  local dep_file=$1
  local offending=0
  while IFS=' ' read -r src dep; do
    [[ -z "$dep" ]] && continue
    [[ "$src" == "$dep" ]] && continue
    if [[ "$dep" != src/v3/* ]]; then
      echo "ERROR: v3 REQUIRE edge points outside src/v3: $src -- REQUIRE: $dep" >&2
      offending=1
    fi
  done < "$dep_file"
  if [[ $offending -ne 0 ]]; then
    echo "ERROR: v3-only build is not self-contained — a -- REQUIRE: target lives outside src/v3 (see above)." >&2
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

rm -f release/cipherstash-encrypt-v3.sql
rm -f release/cipherstash-encrypt-v3-uninstall.sql

rm -f dbdev/eql--0.0.0.sql

rm -f src/version.sql
rm -f src/deps.txt
rm -f src/deps-ordered.txt
rm -f src/deps-supabase.txt
rm -f src/deps-ordered-supabase.txt
rm -f src/deps-protect.txt
rm -f src/deps-ordered-protect.txt
rm -f src/deps-v3.txt
rm -f src/deps-ordered-v3.txt


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


# v3-only build (design D9): the self-contained eql_v3 surface — schema, SEM
# types, scalar domains — globbed from src/v3 ONLY. This is the unit the
# self-containment gate greps; it is the only artifact that can be "free of
# eql_v2", because the combined variants glob all of src/. It deliberately does
# NOT append tasks/pin_search_path.sql (D11): that script is eql_v2-coupled
# (raises if public.eql_v2_encrypted / eql_v2.ste_vec_entry are absent and only
# ever pins eql_v2 functions), so appending it would both fail a clean v3
# install and break the self-containment grep.
find src/v3 -type f -path "*.sql" ! -path "*_test.sql" | while IFS= read -r sql_file; do
    echo "$sql_file"

    echo "$sql_file $sql_file" >> src/deps-v3.txt

    while IFS= read -r line; do
        if [[ "$line" == *"-- REQUIRE:"* ]]; then
            deps=${line#*-- REQUIRE: }
            for dep in $deps; do
                echo "$sql_file $dep" >> src/deps-v3.txt
            done
        fi
    done < "$sql_file"
done

verify_v3_self_contained src/deps-v3.txt

cat src/deps-v3.txt | tsort | tac > src/deps-ordered-v3.txt
verify_deps_exist src/deps-ordered-v3.txt

cat src/deps-ordered-v3.txt | xargs cat | grep -v REQUIRE >> release/cipherstash-encrypt-v3.sql

cat tasks/uninstall-v3.sql >> release/cipherstash-encrypt-v3-uninstall.sql


echo
echo '###############################################'
echo "# ✅Build succeeded"
echo '###############################################'
echo
echo 'Installer:'
echo '    release/cipherstash-encrypt.sql'
echo '    release/cipherstash-encrypt-supabase.sql'
echo '    release/cipherstash-encrypt-protect.sql'
echo '    release/cipherstash-encrypt-v3.sql'
echo
echo 'Uninstaller:'
echo '    release/cipherstash-encrypt-uninstall.sql'
echo '    release/cipherstash-encrypt-uninstall-supabase.sql'
echo '    release/cipherstash-encrypt-protect-uninstall.sql'
echo '    release/cipherstash-encrypt-v3-uninstall.sql'
