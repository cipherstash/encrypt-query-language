#!/usr/bin/env bash
#MISE description="Build SQL into single release file"
#MISE alias="b"
#MISE sources=["src/v3/**/*.sql", "src/v3/version.template", "tasks/pin_search_path_v3.sql", "tasks/uninstall-v3.sql", "crates/eql-domains/src/**/*.rs", "crates/eql-codegen/src/**/*.rs"]
#MISE outputs=["release/cipherstash-encrypt.sql","release/cipherstash-encrypt-uninstall.sql"]
#USAGE flag "--version <version>" help="Specify release version of EQL" default="DEV"

#!/bin/bash

set -euo pipefail

source tasks/build/ordering.sh

# Regenerate encrypted-domain SQL from the Rust catalog before building.
# The generated files (src/v3/scalars/<T>/<T>_*.sql) are COMMITTED in place and
# drift-gated by `mise run codegen:parity`; only src/v3/version.sql and the
# src/deps*-v3.txt build intermediates are gitignored. The catalog at
# crates/eql-domains/src (eql-domains::CATALOG) is the source of truth, rendered
# by the eql-codegen binary.
#
# eql-codegen owns orphan removal: it writes every current file first (each via
# an atomic temp+rename), then prunes stale generated SQL across ALL
# src/v3/scalars/* type dirs — marker-aware, so a type dropped from the catalog
# can't leave orphans the `src/**/*.sql` build glob would pick up, and a
# hand-written *_extensions.sql (no AUTO-GENERATED marker) is never deleted.
# Because deletion happens only after every write succeeds, an aborted run never
# leaves the tree stripped (unlike the old filename-pattern `find -delete`, which
# deleted before regenerating and was blind to the AUTO-GENERATED marker).
#
# The plaintext fixture lists are not generated — the SQLx tests read them
# straight from the catalog (eql_domains::INT4_VALUES / …).
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
# "<dep> <file>" (dependency FIRST); self-edges (dep == file) are skipped, every
# other dep target (field 1) must start with src/v3/.
verify_v3_self_contained() {
  local dep_file=$1
  local offending=0
  while IFS=' ' read -r dep src; do
    [[ -z "$src" ]] && continue
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

# Truncate the build intermediates we APPEND to below. The generated-*.txt files
# are (re)written wholesale by eql-codegen above, so they are NOT removed here.
rm -f src/deps-v3.txt src/deps-ordered-v3.txt src/handwritten-deps-v3.txt src/handwritten-ordered-v3.txt
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
find src/v3 -type f -path "*.sql" ! -path "*_test.sql" -print0 \
  | LC_ALL=C sort -z \
  | while IFS= read -r -d '' sql_file; do
      IFS= read -r first < "$sql_file" || first=""
      # Generated scalar files are ordered by eql-codegen (src/generated-order-v3.txt);
      # only hand-written files are parsed here. The classifier is the EXACT
      # period-terminated marker ("-- AUTOMATICALLY GENERATED FILE."): generated
      # scalars carry it, but src/v3/version.sql carries a period-LESS marker and
      # IS hand-written (it has an authored -- REQUIRE: edge to schema.sql and is
      # not part of the codegen manifest), so it must be parsed, not skipped.
      [[ "$first" == "-- AUTOMATICALLY GENERATED FILE."* ]] && continue
      echo "$sql_file $sql_file" >> src/handwritten-deps-v3.txt   # self-edge
      while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*--\ REQUIRE: ]]; then
          deps=${line#*-- REQUIRE: }
          for dep in $deps; do
            echo "$dep $sql_file" >> src/handwritten-deps-v3.txt  # dependency first
          done
        fi
      done < "$sql_file"
    done

# Union edge set for the whole-surface verifiers (hand-written + generated).
cat src/handwritten-deps-v3.txt src/generated-deps-v3.txt > src/deps-v3.txt

# Whole-surface cycle gate (verification only) — tsort output discarded.
verify_v3_self_contained src/deps-v3.txt
run_tsort_or_die src/deps-v3.txt /dev/null

# Phase A: order the ~25 hand-written files from their authored edges.
run_tsort_or_die src/handwritten-deps-v3.txt src/handwritten-ordered-v3.txt

# Phase B: hand-written order, then the codegen-emitted generated order. Valid
# because NO hand-written file depends on a generated file (verified), so every
# generated->hand-written edge points backward into the already-emitted block.
cat src/handwritten-ordered-v3.txt src/generated-order-v3.txt > src/deps-ordered-v3.txt

verify_deps_exist src/deps-ordered-v3.txt
verify_linearization src/deps-v3.txt src/deps-ordered-v3.txt
bash tasks/test/verify_symbol_order_v3.sh src/deps-ordered-v3.txt

: > release/cipherstash-encrypt.sql
while IFS= read -r f; do
  strip_require_lines "$f" >> release/cipherstash-encrypt.sql
done < src/deps-ordered-v3.txt
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
