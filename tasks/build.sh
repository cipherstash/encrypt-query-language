#!/usr/bin/env bash
#MISE description="Build SQL into single release file"
#MISE alias="b"
#MISE sources=["src/v3/**/*.sql", "src/v3/version.template", "tasks/pin_search_path_v3.sql", "tasks/uninstall-v3.sql", "crates/eql-scalars/src/**/*.rs", "crates/eql-codegen/src/**/*.rs"]
#MISE outputs=["release/cipherstash-encrypt.sql","release/cipherstash-encrypt-uninstall.sql"]
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

rm -f release/cipherstash-encrypt.sql
rm -f release/cipherstash-encrypt-uninstall.sql

rm -f src/deps-v3.txt
rm -f src/deps-ordered-v3.txt
rm -f src/v3/version.sql


# Bake the release version into eql_v3.version() (and the eql_v3 schema
# comment) before the glob below picks it up. The version is supplied via
# `mise run build --version <semver>` (the `usage_version` env var mise derives
# from the #USAGE flag); local builds with no flag fall back to DEV. The
# generated src/v3/version.sql is gitignored, like the other generated v3 SQL.
RELEASE_VERSION=${usage_version:-DEV}
sed "s/\$RELEASE_VERSION/$RELEASE_VERSION/g" src/v3/version.template > src/v3/version.sql


# The self-contained eql_v3 surface — schema, SEM types, scalar domains —
# globbed from src/v3 ONLY. This is the sole EQL artifact: it owns no eql_v2
# dependency (CI-gated by verify_v3_self_contained below + test:self_contained_v3),
# and it is written under the canonical release name now that the combined v2
# build that previously produced that name is gone.
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

cat src/deps-ordered-v3.txt | xargs cat | grep -v REQUIRE >> release/cipherstash-encrypt.sql
cat tasks/pin_search_path_v3.sql >> release/cipherstash-encrypt.sql

cat tasks/uninstall-v3.sql >> release/cipherstash-encrypt-uninstall.sql


echo
echo '###############################################'
echo "# ✅Build succeeded"
echo '###############################################'
echo
echo 'Installer:'
echo '    release/cipherstash-encrypt.sql'
echo
echo 'Uninstaller:'
echo '    release/cipherstash-encrypt-uninstall.sql'
