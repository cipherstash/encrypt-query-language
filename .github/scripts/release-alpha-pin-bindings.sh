#!/usr/bin/env bash
# Pin eql-bindings to a prerelease identity, commit the metadata change, and
# push the selected branch.
set -euo pipefail

release_alpha_pin_emit_commit_sha() {
  local commit_sha="$1"
  echo "commit_sha=${commit_sha}" | tee -a "${GITHUB_OUTPUT:-/dev/null}"
}

release_alpha_pin_push_target() {
  if [[ -n "${GH_TOKEN:-}" && -n "${GITHUB_REPOSITORY:-}" ]]; then
    printf 'https://github.com/%s.git\n' "$GITHUB_REPOSITORY"
  else
    printf 'origin\n'
  fi
}

release_alpha_pin_push() {
  local branch="$1" push_target
  push_target="$(release_alpha_pin_push_target)"
  if [[ -n "${GH_TOKEN:-}" && -n "${GITHUB_REPOSITORY:-}" ]]; then
    git -c "http.https://github.com/.extraheader=AUTHORIZATION: bearer ${GH_TOKEN}" push "$push_target" "HEAD:${branch}"
  else
    git push "$push_target" "HEAD:${branch}"
  fi
}

release_alpha_pin_bindings() {
  local identity="$1" branch="$2"
  local commit_sha
  local commit_args=()

  release-plz set-version "eql-bindings@${identity}"

  if git diff --quiet && git diff --cached --quiet; then
    echo "set-version produced no changes (already pinned to ${identity}); skipping commit/push"
  else
    git config user.name "github-actions[bot]"
    git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
    git add crates/eql-bindings/Cargo.toml crates/eql-bindings/CHANGELOG.md Cargo.lock
    if [[ "${RELEASE_ALPHA_COMMIT_SIGN:-true}" == "true" ]]; then
      commit_args=(-S)
    fi
    git commit "${commit_args[@]}" -m "chore(release): pin eql-bindings to ${identity}"
    release_alpha_pin_push "$branch"
  fi

  commit_sha="$(git rev-parse HEAD)"
  release_alpha_pin_emit_commit_sha "$commit_sha"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  release_alpha_pin_bindings "${IDENTITY:?}" "${BRANCH:?}"
fi
