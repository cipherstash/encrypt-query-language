#!/usr/bin/env bash
# Resolve and validate release-alpha.yml identity/tag state.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${here}/derive-identity.sh"

git_head_sha() { git rev-parse HEAD; }

tag_commit_sha() { git rev-parse "refs/tags/$1^{commit}"; }

release_alpha_error() {
  echo "::error::$*" >&2
}

release_alpha_emit_outputs() {
  local identity="$1" sql_tag="$2" rust_tag="$3" typescript_tag="$4" publish_rust="$5" publish_typescript="$6"
  {
    echo "identity=${identity}"
    echo "sql_tag=${sql_tag}"
    echo "rust_tag=${rust_tag}"
    echo "typescript_tag=${typescript_tag}"
    echo "publish_rust=${publish_rust}"
    echo "publish_typescript=${publish_typescript}"
  } | tee -a "${GITHUB_OUTPUT:-/dev/null}"
}

release_alpha_resolve() {
  local target="$1" version="$2" channel="$3" pre="$4" ref_type="$5" ref_name="$6"
  local identity sql_tag rust_tag typescript_tag head_sha tag_sha
  local publish_rust=false publish_typescript=false

  case "$channel" in
    alpha|beta|rc) ;;
    *) release_alpha_error "invalid channel '$channel'"; return 1 ;;
  esac

  case "$target" in
    all|eql|bindings|rust|typescript) ;;
    *) release_alpha_error "invalid target '$target'"; return 1 ;;
  esac

  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    release_alpha_error "invalid version '$version' (expected X.Y.Z)"
    return 1
  fi

  if [[ -n "$pre" && ! "$pre" =~ ^[0-9]+\.[0-9]+\.[0-9]+-(alpha|beta|rc)\.[0-9]+$ ]]; then
    release_alpha_error "invalid pre '$pre' (expected X.Y.Z-(alpha|beta|rc).N)"
    return 1
  fi

  if [[ -n "$pre" && "$pre" != "${version}-${channel}."* ]]; then
    release_alpha_error "pre '$pre' does not match version '${version}' and channel '${channel}'"
    return 1
  fi

  if [[ "$target" == "all" || "$target" == "bindings" || "$target" == "rust" || "$target" == "typescript" ]]; then
    if [[ "$ref_type" != "branch" ]]; then
      release_alpha_error "target=${target} pins+pushes package versions and requires a branch ref; got ${ref_type} '${ref_name}'. Dispatch with --ref <branch>."
      return 1
    fi
  fi

  identity="$(derive_identity "$target" "$version" "$channel" "$pre")"
  sql_tag="eql-${identity}"
  rust_tag="eql-bindings-v${identity}"
  typescript_tag="eql-typescript-v${identity}"

  case "$target" in
    all|bindings|rust) if ! tag_exists "$rust_tag"; then publish_rust=true; fi ;;
  esac
  case "$target" in
    all|bindings|typescript) if ! tag_exists "$typescript_tag"; then publish_typescript=true; fi ;;
  esac

  case "$target" in
    all)
      if tag_exists "$sql_tag"; then release_alpha_error "${sql_tag} already exists"; return 1; fi
      if tag_exists "$rust_tag"; then release_alpha_error "${rust_tag} already exists"; return 1; fi
      if tag_exists "$typescript_tag"; then release_alpha_error "${typescript_tag} already exists"; return 1; fi
      ;;
    eql)
      if tag_exists "$sql_tag"; then release_alpha_error "${sql_tag} already exists"; return 1; fi
      ;;
    bindings|rust|typescript)
      if ! tag_exists "$sql_tag"; then
        release_alpha_error "${sql_tag} SQL release must exist before publishing language bindings"
        return 1
      fi
      head_sha="$(git_head_sha)"
      tag_sha="$(tag_commit_sha "$sql_tag")"
      if [[ "$head_sha" != "$tag_sha" ]]; then
        release_alpha_error "branch HEAD (${head_sha}) has advanced past ${sql_tag} (${tag_sha}); use target=all for a fresh identity"
        return 1
      fi
      ;;
  esac

  if [[ "$target" != "eql" && "$publish_rust" == false && "$publish_typescript" == false ]]; then
    release_alpha_error "all requested language binding tags already exist for ${identity}"
    return 1
  fi

  release_alpha_emit_outputs "$identity" "$sql_tag" "$rust_tag" "$typescript_tag" "$publish_rust" "$publish_typescript"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  release_alpha_resolve "${TARGET:?}" "${VERSION:?}" "${CHANNEL:?}" "${PRE:-}" "${REF_TYPE:?}" "${REF_NAME:?}"
fi
