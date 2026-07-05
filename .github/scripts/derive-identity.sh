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
  local crate_prefix="eql-bindings-v${version}-${channel}."

  if [[ -n "$pre" ]]; then
    printf '%s\n' "$pre"
    return 0
  fi

  case "$target" in
    all|eql)
      local sql_n crate_n sql_n_dec crate_n_dec n
      sql_n=$(highest_n "$sql_prefix")
      sql_n=${sql_n:-0}
      crate_n=$(highest_n "$crate_prefix")
      crate_n=${crate_n:-0}
      sql_n_dec=$((10#$sql_n))
      crate_n_dec=$((10#$crate_n))
      if (( sql_n_dec >= crate_n_dec )); then
        n=$((sql_n_dec + 1))
      else
        n=$((crate_n_dec + 1))
      fi
      printf '%s\n' "${version}-${channel}.${n}"
      ;;
    bindings)
      local found n
      found=""
      for n in $(matching_suffixes "$sql_prefix" | sort -rn); do
        if ! tag_exists "${crate_prefix}${n}"; then
          found="$n"
          break
        fi
      done
      if [[ -z "$found" ]]; then
        echo "error: no ${sql_prefix}N SQL release is awaiting a crate publish" >&2
        return 1
      fi
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
