#!/usr/bin/env bash
# Dependency-free unit test for derive_identity using a synthetic tag set.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${here}/derive-identity.sh"

FAKE_TAGS=()
# shellcheck disable=SC2329
list_tags() {
  local glob="$1" t
  (( ${#FAKE_TAGS[@]} )) || return 0
  for t in "${FAKE_TAGS[@]}"; do
    # shellcheck disable=SC2254
    case "$t" in $glob) printf '%s\n' "$t" ;; esac
  done
}

# shellcheck disable=SC2329
tag_exists() {
  local want="$1" t
  (( ${#FAKE_TAGS[@]} )) || return 1
  for t in "${FAKE_TAGS[@]}"; do
    [[ "$t" == "$want" ]] && return 0
  done
  return 1
}

fail=0
check() {
  if [[ "$2" == "$3" ]]; then
    echo "ok: $1"
  else
    echo "FAIL: $1 - got '$2' want '$3'"
    fail=1
  fi
}

FAKE_TAGS=()
check "all: empty -> .1" "$(derive_identity all 3.0.0 alpha '')" "3.0.0-alpha.1"

FAKE_TAGS=(eql-3.0.0-alpha.5)
check "all: sql .5 -> .6" "$(derive_identity all 3.0.0 alpha '')" "3.0.0-alpha.6"

FAKE_TAGS=(eql-3.0.0-alpha.2 eql-bindings-v3.0.0-alpha.4)
check "all: crate .4 wins (cross-namespace) -> .5" "$(derive_identity all 3.0.0 alpha '')" "3.0.0-alpha.5"

FAKE_TAGS=(eql-3.0.0-alpha.08)
check "all: leading-zero sql suffix is base-10 -> .9" "$(derive_identity all 3.0.0 alpha '')" "3.0.0-alpha.9"

FAKE_TAGS=(eql-3.0.0-alpha.5 eql-bindings-v3.0.0-alpha.4)
check "bindings: latest sql lacking crate -> .5" "$(derive_identity bindings 3.0.0 alpha '')" "3.0.0-alpha.5"

# bindings now means ALL language bindings: it only errors once every language
# tag exists for the newest SQL release.
FAKE_TAGS=(eql-3.0.0-alpha.5 eql-bindings-v3.0.0-alpha.5 eql-typescript-v3.0.0-alpha.5)
if derive_identity bindings 3.0.0 alpha '' >/dev/null 2>&1; then
  echo "FAIL: bindings should error when all language tags exist"
  fail=1
else
  echo "ok: bindings errors when all language tags exist"
fi

# Fresh identity is one past the highest N across all three tag namespaces.
FAKE_TAGS=(eql-3.0.0-alpha.2 eql-bindings-v3.0.0-alpha.4 eql-typescript-v3.0.0-alpha.6)
check "all derives after all namespaces" "$(derive_identity all 3.0.0 alpha '')" "3.0.0-alpha.7"

FAKE_TAGS=(eql-3.0.0-alpha.5 eql-bindings-v3.0.0-alpha.5)
check "typescript finds sql lacking ts package" "$(derive_identity typescript 3.0.0 alpha '')" "3.0.0-alpha.5"

FAKE_TAGS=(eql-3.0.0-alpha.5 eql-typescript-v3.0.0-alpha.5)
check "rust finds sql lacking rust package" "$(derive_identity rust 3.0.0 alpha '')" "3.0.0-alpha.5"

FAKE_TAGS=(eql-3.0.0-alpha.5 eql-bindings-v3.0.0-alpha.5)
check "bindings finds sql lacking one language package" "$(derive_identity bindings 3.0.0 alpha '')" "3.0.0-alpha.5"

check "pre passthrough" "$(derive_identity all 3.0.0 alpha 3.0.0-alpha.9)" "3.0.0-alpha.9"

FAKE_TAGS=(eql-3.0.0-beta.7)
check "all: beta.7 does not affect alpha -> .1" "$(derive_identity all 3.0.0 alpha '')" "3.0.0-alpha.1"

exit "$fail"
