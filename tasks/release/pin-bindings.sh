#!/usr/bin/env bash
#MISE description="CI-oriented helper: pin eql-bindings to an identity, commit, and push"
#USAGE flag "--identity <identity>" help="Exact prerelease identity, e.g. 3.0.0-alpha.2"
#USAGE flag "--branch <branch>" help="Branch to push the pin commit to"

set -euo pipefail

root="$(git rev-parse --show-toplevel)"
identity="${usage_identity:-}"
branch="${usage_branch:-}"

[[ -n "$identity" ]] || { echo "error: --identity is required" >&2; exit 1; }
[[ -n "$branch" ]] || { echo "error: --branch is required" >&2; exit 1; }

IDENTITY="$identity" BRANCH="$branch" "${root}/.github/scripts/release-alpha-pin-bindings.sh"
