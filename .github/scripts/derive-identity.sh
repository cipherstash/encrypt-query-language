#!/usr/bin/env bash
# Identity derivation for release-alpha.yml. The git seams are overridable by
# derive-identity.test.sh so this logic can be tested without a repository.
set -euo pipefail

list_tags() { git tag --list "$1"; }

tag_exists() { git rev-parse -q --verify "refs/tags/$1" >/dev/null; }

matching_suffixes() {
  local prefix="$1" esc
  esc="${prefix//./\\.}"
  list_tags "${prefix}*" \
    | sed -n "s/^${esc}\([0-9]\{1,\}\)$/\1/p"
}

highest_n() {
  local prefix="$1"
  matching_suffixes "$prefix" \
    | sort -n \
    | tail -1
}

derive_identity() {
  local target="$1" version="$2" channel="$3" pre="$4"
  local sql_prefix="eql-${version}-${channel}."
  local rust_prefix="eql-bindings-v${version}-${channel}."
  local typescript_prefix="eql-typescript-v${version}-${channel}."

  if [[ -n "$pre" ]]; then
    printf '%s\n' "$pre"
    return 0
  fi

  case "$target" in
    all|eql)
      # Fresh identity = one past the highest N across ALL tag namespaces
      # (SQL, Rust, TypeScript) so a new release never reuses an N that any
      # language package already claimed.
      local sql_n rust_n typescript_n n
      sql_n=$(highest_n "$sql_prefix"); sql_n=${sql_n:-0}
      rust_n=$(highest_n "$rust_prefix"); rust_n=${rust_n:-0}
      typescript_n=$(highest_n "$typescript_prefix"); typescript_n=${typescript_n:-0}
      n=$((10#$sql_n))
      if (( 10#$rust_n > n )); then n=$((10#$rust_n)); fi
      if (( 10#$typescript_n > n )); then n=$((10#$typescript_n)); fi
      printf '%s\n' "${version}-${channel}.$((n + 1))"
      ;;
    rust)
      # Newest SQL release still missing a Rust binding tag.
      local found n
      found=""
      for n in $(matching_suffixes "$sql_prefix" | sort -rn); do
        if ! tag_exists "${rust_prefix}${n}"; then found="$n"; break; fi
      done
      [[ -n "$found" ]] || { echo "error: no ${sql_prefix}N SQL release is awaiting a Rust binding publish" >&2; return 1; }
      printf '%s\n' "${version}-${channel}.${found}"
      ;;
    typescript)
      # Newest SQL release still missing a TypeScript binding tag.
      local found n
      found=""
      for n in $(matching_suffixes "$sql_prefix" | sort -rn); do
        if ! tag_exists "${typescript_prefix}${n}"; then found="$n"; break; fi
      done
      [[ -n "$found" ]] || { echo "error: no ${sql_prefix}N SQL release is awaiting a TypeScript binding publish" >&2; return 1; }
      printf '%s\n' "${version}-${channel}.${found}"
      ;;
    bindings)
      # Newest SQL release still missing ANY language binding tag.
      local found n
      found=""
      for n in $(matching_suffixes "$sql_prefix" | sort -rn); do
        if ! tag_exists "${rust_prefix}${n}" || ! tag_exists "${typescript_prefix}${n}"; then found="$n"; break; fi
      done
      [[ -n "$found" ]] || { echo "error: no ${sql_prefix}N SQL release is awaiting a language binding publish" >&2; return 1; }
      printf '%s\n' "${version}-${channel}.${found}"
      ;;
    *)
      echo "error: unknown target '$target'" >&2
      return 1
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  derive_identity "$@"
fi
