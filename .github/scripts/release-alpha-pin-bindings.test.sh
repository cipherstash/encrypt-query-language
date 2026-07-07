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
  mkdir -p "$tmp/bin" "$tmp/repo/crates/eql-bindings" "$tmp/repo/packages/eql"
  cat > "$tmp/bin/release-plz" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >> "$RELEASE_PLZ_LOG"
if [[ "${RELEASE_PLZ_TOUCH:-}" == "1" ]]; then
  printf '[package]\nname = "eql-bindings"\nversion = "%s"\n' "${2#eql-bindings@}" > crates/eql-bindings/Cargo.toml
fi
SCRIPT
  chmod +x "$tmp/bin/release-plz"
  # Fake pnpm: the pin script runs `pnpm install --lockfile-only` for a
  # TypeScript pin. Just record the call so we don't touch the network.
  cat > "$tmp/bin/pnpm" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >> "$PNPM_LOG"
SCRIPT
  chmod +x "$tmp/bin/pnpm"
  # Fake mise: the pin script runs `mise run release:prepare_bindings_assets`.
  # The real SQL-asset build is covered elsewhere; here we only need a no-op so
  # the git commit/version-pin logic is what's under test.
  cat > "$tmp/bin/mise" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >> "$MISE_LOG"
SCRIPT
  chmod +x "$tmp/bin/mise"
  (
    cd "$tmp/repo" || exit 1
    git init -q
    git config user.email test@example.com
    git config user.name "Release Test"
    git config commit.gpgsign false
    printf '[package]\nname = "eql-bindings"\nversion = "0.0.0"\n' > crates/eql-bindings/Cargo.toml
    printf '# changelog\n' > crates/eql-bindings/CHANGELOG.md
    printf '# lock\n' > Cargo.lock
    # Asset directories the pin script `git add`s must exist to be added.
    mkdir -p crates/eql-bindings/sql packages/eql/src/generated
    printf -- '-- placeholder\n' > crates/eql-bindings/sql/cipherstash-encrypt.sql
    mkdir -p packages/eql/sql
    printf -- '-- placeholder\n' > packages/eql/sql/cipherstash-encrypt.sql
    printf '{\n  "name": "@cipherstash/eql",\n  "version": "0.0.0"\n}\n' > packages/eql/package.json
    printf 'lockfileVersion: "9.0"\n' > pnpm-lock.yaml
    printf "export const releaseManifest = { eqlVersion: 'DEV' } as const\n" > packages/eql/src/generated/release-manifest.ts
    git add -A
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
    PATH="$tmp/bin:$PATH" RELEASE_PLZ_LOG="$tmp/log" MISE_LOG="$tmp/mise-log" PNPM_LOG="$tmp/pnpm-log" RELEASE_ALPHA_COMMIT_SIGN=false \
      release_alpha_pin_bindings 3.0.0-alpha.1 test-branch true false 2>&1
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
    PATH="$tmp/bin:$PATH" RELEASE_PLZ_LOG="$tmp/log" MISE_LOG="$tmp/mise-log" PNPM_LOG="$tmp/pnpm-log" RELEASE_PLZ_TOUCH=1 RELEASE_ALPHA_COMMIT_SIGN=false \
      release_alpha_pin_bindings 3.0.0-alpha.2 test-branch true false 2>&1
  )"
  status=$?
  after="$(cd "$tmp/repo" && git rev-parse HEAD)"
  subject="$(cd "$tmp/repo" && git log -1 --format=%s)"
  version="$(sed -n 's/^version = "\(.*\)"/\1/p' "$tmp/repo/crates/eql-bindings/Cargo.toml")"
  if [[ "$status" -eq 0 && "$before" != "$after" && "$subject" == "chore(release): pin language bindings to 3.0.0-alpha.2" && "$version" == "3.0.0-alpha.2" && "$output" == *"commit_sha=${after}"* ]]; then
    echo "ok: changed version commits and emits new commit"
  else
    echo "FAIL: commit status=$status before=$before after=$after subject='$subject' version='$version' output='$output'"
    fail=1
  fi
  rm -rf "$tmp"
}

check_typescript_commit() {
  local before after subject output status version
  setup_repo
  before="$(cd "$tmp/repo" && git rev-parse HEAD)"
  output="$(
    cd "$tmp/repo" || exit 1
    set -euo pipefail
    PATH="$tmp/bin:$PATH" RELEASE_PLZ_LOG="$tmp/log" MISE_LOG="$tmp/mise-log" PNPM_LOG="$tmp/pnpm-log" RELEASE_ALPHA_COMMIT_SIGN=false \
      release_alpha_pin_bindings 3.0.0-alpha.3 test-branch false true 2>&1
  )"
  status=$?
  after="$(cd "$tmp/repo" && git rev-parse HEAD)"
  subject="$(cd "$tmp/repo" && git log -1 --format=%s)"
  version="$(node -e "console.log(require('$tmp/repo/packages/eql/package.json').version)")"
  if [[ "$status" -eq 0 && "$before" != "$after" && "$subject" == "chore(release): pin language bindings to 3.0.0-alpha.3" && "$version" == "3.0.0-alpha.3" ]]; then
    echo "ok: typescript version commits"
  else
    echo "FAIL: typescript commit status=$status before=$before after=$after subject='$subject' version='$version' output='$output'"
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
check_typescript_commit
check_push_target_keeps_token_out_of_url

exit "$fail"
