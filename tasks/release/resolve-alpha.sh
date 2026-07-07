#!/usr/bin/env bash
#MISE description="Resolve and validate release-alpha.yml identity/tag guards locally"
#USAGE flag "--target <target>" help="Release target: all | eql | bindings | rust | typescript" default="all"
#USAGE flag "--version <version>" help="Base SemVer, e.g. 3.0.0" default="3.0.0"
#USAGE flag "--channel <channel>" help="Preview channel: alpha | beta | rc" default="alpha"
#USAGE flag "--pre <pre>" help="Exact identity (e.g. 3.0.0-alpha.2), bypassing N derivation" default=""
#USAGE flag "--ref-type <ref_type>" help="GitHub ref type: branch | tag" default=""
#USAGE flag "--ref-name <ref_name>" help="GitHub ref name" default=""

set -euo pipefail

root="$(git rev-parse --show-toplevel)"
target="${usage_target:-all}"
version="${usage_version:-3.0.0}"
channel="${usage_channel:-alpha}"
pre="${usage_pre:-}"
ref_type="${usage_ref_type:-}"
ref_name="${usage_ref_name:-}"

if [[ -z "$ref_name" ]]; then
  ref_name="$(git rev-parse --abbrev-ref HEAD)"
fi

if [[ -z "$ref_type" ]]; then
  if [[ "$ref_name" == "HEAD" ]]; then
    ref_type="tag"
  else
    ref_type="branch"
  fi
fi

TARGET="$target" \
VERSION="$version" \
CHANNEL="$channel" \
PRE="$pre" \
REF_TYPE="$ref_type" \
REF_NAME="$ref_name" \
  "${root}/.github/scripts/release-alpha-resolve.sh"
