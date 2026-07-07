#!/usr/bin/env bash
#MISE description="CI-oriented helper: pin language binding package versions to an identity, commit, and push"
#USAGE flag "--identity <identity>" help="Exact prerelease identity, e.g. 3.0.0-alpha.2"
#USAGE flag "--branch <branch>" help="Branch to push the pin commit to"
#USAGE flag "--publish-rust <publish_rust>" help="Pin the Rust eql-bindings crate (true/false)" default="true"
#USAGE flag "--publish-typescript <publish_typescript>" help="Pin the TypeScript @cipherstash/eql package (true/false)" default="true"

set -euo pipefail

root="$(git rev-parse --show-toplevel)"
identity="${usage_identity:-}"
branch="${usage_branch:-}"
publish_rust="${usage_publish_rust:-true}"
publish_typescript="${usage_publish_typescript:-true}"

[[ -n "$identity" ]] || { echo "error: --identity is required" >&2; exit 1; }
[[ -n "$branch" ]] || { echo "error: --branch is required" >&2; exit 1; }

IDENTITY="$identity" BRANCH="$branch" PUBLISH_RUST="$publish_rust" PUBLISH_TYPESCRIPT="$publish_typescript" \
  "${root}/.github/scripts/release-alpha-pin-bindings.sh"
