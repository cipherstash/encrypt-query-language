#!/usr/bin/env bash
# Verify that GitHub accepts a pushed commit's signature as valid.
set -euo pipefail

release_alpha_verify_commit_signature() {
  local commit_sha="$1" repo verification verified reason
  repo="${GITHUB_REPOSITORY:?}"

  verification="$(
    gh api "repos/${repo}/commits/${commit_sha}" \
      --jq '.commit.verification | "\(.verified) \(.reason)"'
  )"
  read -r verified reason <<< "$verification"

  if [[ "$verified" != "true" || "$reason" != "valid" ]]; then
    echo "error: commit ${commit_sha} is not GitHub-verified (verified=${verified:-<empty>} reason=${reason:-<empty>})" >&2
    return 1
  fi

  echo "GitHub verified signed commit ${commit_sha} (${reason})"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  release_alpha_verify_commit_signature "${1:?commit sha required}"
fi
