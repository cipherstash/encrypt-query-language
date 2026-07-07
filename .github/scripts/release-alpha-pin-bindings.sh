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
  local identity="$1" branch="$2" publish_rust="$3" publish_typescript="$4"
  local commit_sha
  local commit_args=()

  if [[ "$publish_rust" == "true" ]]; then
    release-plz set-version "eql-bindings@${identity}"
  fi

  if [[ "$publish_typescript" == "true" ]]; then
    node -e "const fs=require('fs'); const p='packages/eql/package.json'; const j=JSON.parse(fs.readFileSync(p,'utf8')); j.version=process.argv[1]; fs.writeFileSync(p, JSON.stringify(j,null,2)+'\n')" "$identity"
    pnpm install --lockfile-only
  fi

  if [[ "$publish_rust" == "true" || "$publish_typescript" == "true" ]]; then
    mise run release:prepare_bindings_assets --version "$identity"
  fi

  if git diff --quiet && git diff --cached --quiet; then
    echo "package versions already pinned to ${identity}; skipping commit/push"
  else
    git config user.name "github-actions[bot]"
    git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
    if [[ "$publish_rust" == "true" ]]; then
      git add crates/eql-bindings/Cargo.toml crates/eql-bindings/CHANGELOG.md Cargo.lock crates/eql-bindings/sql
    fi
    if [[ "$publish_typescript" == "true" ]]; then
      git add packages/eql/package.json pnpm-lock.yaml packages/eql/sql packages/eql/src/generated/release-manifest.ts
    fi
    if [[ "${RELEASE_ALPHA_COMMIT_SIGN:-true}" == "true" ]]; then
      commit_args=(-S)
    fi
    git commit "${commit_args[@]}" -m "chore(release): pin language bindings to ${identity}"
    release_alpha_pin_push "$branch"
  fi

  commit_sha="$(git rev-parse HEAD)"
  release_alpha_pin_emit_commit_sha "$commit_sha"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  release_alpha_pin_bindings "${IDENTITY:?}" "${BRANCH:?}" "${PUBLISH_RUST:?}" "${PUBLISH_TYPESCRIPT:?}"
fi
