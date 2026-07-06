#!/usr/bin/env bash
# Integration-style tests for release-alpha-pin-bindings.sh in a temp git repo.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${here}/release-alpha-pin-bindings.sh"
set +e

fail=0

setup_repo() {
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/bin" "$tmp/repo/crates/eql-bindings"
  cat > "$tmp/bin/release-plz" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >> "$RELEASE_PLZ_LOG"
if [[ "${RELEASE_PLZ_TOUCH:-}" == "1" ]]; then
  printf '[package]\nname = "eql-bindings"\nversion = "%s"\n' "${2#eql-bindings@}" > crates/eql-bindings/Cargo.toml
fi
SCRIPT
  chmod +x "$tmp/bin/release-plz"
  (
    cd "$tmp/repo" || exit 1
    git init -q
    git config user.email test@example.com
    git config user.name "Release Test"
    git config commit.gpgsign false
    printf '[package]\nname = "eql-bindings"\nversion = "0.0.0"\n' > crates/eql-bindings/Cargo.toml
    printf '# changelog\n' > crates/eql-bindings/CHANGELOG.md
    printf '# lock\n' > Cargo.lock
    git add crates/eql-bindings/Cargo.toml crates/eql-bindings/CHANGELOG.md Cargo.lock
    git commit -q -m initial
    git branch -M test-branch
    git init -q --bare "$tmp/origin.git"
    git remote add origin "$tmp/origin.git"
  )
}

check_noop() {
  local before after output status
  setup_repo
  before="$(cd "$tmp/repo" && git rev-parse HEAD)"
  output="$(
    cd "$tmp/repo" || exit 1
    set -euo pipefail
    PATH="$tmp/bin:$PATH" RELEASE_PLZ_LOG="$tmp/log" RELEASE_ALPHA_COMMIT_SIGN=false \
      release_alpha_pin_bindings 3.0.0-alpha.1 test-branch 2>&1
  )"
  status=$?
  after="$(cd "$tmp/repo" && git rev-parse HEAD)"
  if [[ "$status" -eq 0 && "$before" == "$after" && "$output" == *"commit_sha=${before}"* && "$(cat "$tmp/log")" == "set-version eql-bindings@3.0.0-alpha.1" ]]; then
    echo "ok: noop emits existing commit"
  else
    echo "FAIL: noop status=$status before=$before after=$after output='$output'"
    fail=1
  fi
  rm -rf "$tmp"
}

check_commit() {
  local before after subject output status version
  setup_repo
  before="$(cd "$tmp/repo" && git rev-parse HEAD)"
  output="$(
    cd "$tmp/repo" || exit 1
    set -euo pipefail
    PATH="$tmp/bin:$PATH" RELEASE_PLZ_LOG="$tmp/log" RELEASE_PLZ_TOUCH=1 RELEASE_ALPHA_COMMIT_SIGN=false \
      release_alpha_pin_bindings 3.0.0-alpha.2 test-branch 2>&1
  )"
  status=$?
  after="$(cd "$tmp/repo" && git rev-parse HEAD)"
  subject="$(cd "$tmp/repo" && git log -1 --format=%s)"
  version="$(sed -n 's/^version = "\(.*\)"/\1/p' "$tmp/repo/crates/eql-bindings/Cargo.toml")"
  if [[ "$status" -eq 0 && "$before" != "$after" && "$subject" == "chore(release): pin eql-bindings to 3.0.0-alpha.2" && "$version" == "3.0.0-alpha.2" && "$output" == *"commit_sha=${after}"* ]]; then
    echo "ok: changed version commits and emits new commit"
  else
    echo "FAIL: commit status=$status before=$before after=$after subject='$subject' version='$version' output='$output'"
    fail=1
  fi
  rm -rf "$tmp"
}

check_push_target_keeps_token_out_of_url() {
  local output
  output="$(
    GH_TOKEN=super-secret-token GITHUB_REPOSITORY=cipherstash/encrypt-query-language \
      release_alpha_pin_push_target
  )"
  if [[ "$output" == "https://github.com/cipherstash/encrypt-query-language.git" && "$output" != *"super-secret-token"* ]]; then
    echo "ok: authenticated push target keeps token out of URL"
  else
    echo "FAIL: push target exposed token or used unexpected URL: '$output'"
    fail=1
  fi
}

check_noop
check_commit
check_push_target_keeps_token_out_of_url

exit "$fail"
