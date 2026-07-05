#!/usr/bin/env bash
# Dependency-free unit tests for release-alpha-resolve.sh using synthetic tags
# and commit ids.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${here}/release-alpha-resolve.sh"
set +e

FAKE_TAGS=()
FAKE_HEAD_SHA="head"
FAKE_TAG_SHA="head"

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

# shellcheck disable=SC2329
git_head_sha() { printf '%s\n' "$FAKE_HEAD_SHA"; }

# shellcheck disable=SC2329
tag_commit_sha() { printf '%s\n' "$FAKE_TAG_SHA"; }

fail=0

check_ok() {
  local name="$1" want="$2" got status
  shift 2
  got="$("$@" 2>/tmp/release-alpha-resolve-test.err)"
  status=$?
  if [[ "$status" -eq 0 && "$got" == "$want" ]]; then
    echo "ok: $name"
  else
    echo "FAIL: $name - status=$status got '$got' want '$want'"
    cat /tmp/release-alpha-resolve-test.err
    fail=1
  fi
}

check_fail() {
  local name="$1" needle="$2" got status
  shift 2
  got="$("$@" 2>&1)"
  status=$?
  if [[ "$status" -ne 0 && "$got" == *"$needle"* ]]; then
    echo "ok: $name"
  else
    echo "FAIL: $name - status=$status output '$got' missing '$needle'"
    fail=1
  fi
}

FAKE_TAGS=()
check_ok "all emits derived identity and tags" \
  $'identity=3.0.0-alpha.1\nsql_tag=eql-3.0.0-alpha.1\ncrate_tag=eql-bindings-v3.0.0-alpha.1' \
  release_alpha_resolve all 3.0.0 alpha "" branch eql_v3

check_fail "rejects invalid target" "invalid target 'bad'" \
  release_alpha_resolve bad 3.0.0 alpha "" branch eql_v3

check_fail "rejects invalid channel" "invalid channel 'preview'" \
  release_alpha_resolve all 3.0.0 preview "" branch eql_v3

check_fail "rejects invalid version" "invalid version '3.0'" \
  release_alpha_resolve all 3.0 alpha "" branch eql_v3

check_fail "rejects invalid pre" "invalid pre '3.0.0-alpha'" \
  release_alpha_resolve all 3.0.0 alpha 3.0.0-alpha branch eql_v3

check_fail "rejects pre with mismatched version" "does not match version '3.0.0' and channel 'alpha'" \
  release_alpha_resolve all 3.0.0 alpha 3.1.0-alpha.1 branch eql_v3

check_fail "rejects pre with mismatched channel" "does not match version '3.0.0' and channel 'alpha'" \
  release_alpha_resolve all 3.0.0 alpha 3.0.0-beta.1 branch eql_v3

check_fail "all requires branch ref" "requires a branch ref" \
  release_alpha_resolve all 3.0.0 alpha "" tag v3.0.0

FAKE_TAGS=(eql-3.0.0-alpha.1)
check_fail "eql rejects existing sql tag" "eql-3.0.0-alpha.1 already exists" \
  release_alpha_resolve eql 3.0.0 alpha 3.0.0-alpha.1 tag eql-3.0.0-alpha.1

FAKE_TAGS=()
check_ok "eql accepts tag ref without branch" \
  $'identity=3.0.0-alpha.1\nsql_tag=eql-3.0.0-alpha.1\ncrate_tag=eql-bindings-v3.0.0-alpha.1' \
  release_alpha_resolve eql 3.0.0 alpha "" tag eql-3.0.0-alpha.1

FAKE_TAGS=(eql-3.0.0-alpha.2)
check_fail "all rejects existing sql tag with explicit pre" "eql-3.0.0-alpha.2 already exists" \
  release_alpha_resolve all 3.0.0 alpha 3.0.0-alpha.2 branch eql_v3

FAKE_TAGS=(eql-bindings-v3.0.0-alpha.2)
check_fail "all rejects existing crate tag with explicit pre" "eql-bindings-v3.0.0-alpha.2 already exists" \
  release_alpha_resolve all 3.0.0 alpha 3.0.0-alpha.2 branch eql_v3

FAKE_TAGS=()
check_fail "bindings rejects missing sql tag" "SQL release must exist before publishing the crate" \
  release_alpha_resolve bindings 3.0.0 alpha 3.0.0-alpha.2 branch eql_v3

FAKE_TAGS=(eql-3.0.0-alpha.2 eql-bindings-v3.0.0-alpha.2)
check_fail "bindings rejects existing crate tag" "eql-bindings-v3.0.0-alpha.2 already exists" \
  release_alpha_resolve bindings 3.0.0 alpha 3.0.0-alpha.2 branch eql_v3

FAKE_TAGS=(eql-3.0.0-alpha.2)
FAKE_HEAD_SHA="newer"
FAKE_TAG_SHA="released"
check_fail "bindings rejects advanced branch" "branch HEAD (newer) has advanced past eql-3.0.0-alpha.2 (released)" \
  release_alpha_resolve bindings 3.0.0 alpha 3.0.0-alpha.2 branch eql_v3

FAKE_HEAD_SHA="released"
FAKE_TAG_SHA="released"
check_ok "bindings accepts same-source sql tag" \
  $'identity=3.0.0-alpha.2\nsql_tag=eql-3.0.0-alpha.2\ncrate_tag=eql-bindings-v3.0.0-alpha.2' \
  release_alpha_resolve bindings 3.0.0 alpha 3.0.0-alpha.2 branch eql_v3

exit "$fail"
