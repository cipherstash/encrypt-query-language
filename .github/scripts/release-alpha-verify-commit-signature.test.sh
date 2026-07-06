#!/usr/bin/env bash
# Tests for release-alpha-verify-commit-signature.sh with a stubbed gh CLI.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${here}/release-alpha-verify-commit-signature.sh"
set +e

fail=0

setup_gh() {
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/bin"
  cat > "$tmp/bin/gh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >> "$GH_STUB_LOG"
printf '%s %s\n' "${GH_VERIFIED:-true}" "${GH_REASON:-valid}"
SCRIPT
  chmod +x "$tmp/bin/gh"
}

check_valid_signature() {
  local output status
  setup_gh
  output="$(
    PATH="$tmp/bin:$PATH" GH_STUB_LOG="$tmp/log" GITHUB_REPOSITORY=cipherstash/encrypt-query-language \
      release_alpha_verify_commit_signature abc123 2>&1
  )"
  status=$?
  if [[ "$status" -eq 0 && "$output" == *"GitHub verified signed commit abc123 (valid)"* && "$(cat "$tmp/log")" == *"repos/cipherstash/encrypt-query-language/commits/abc123"* ]]; then
    echo "ok: valid GitHub verification passes"
  else
    echo "FAIL: valid signature status=$status output='$output' log='$(cat "$tmp/log" 2>/dev/null)'"
    fail=1
  fi
  rm -rf "$tmp"
}

check_unverified_signature_fails() {
  local output status
  setup_gh
  output="$(
    PATH="$tmp/bin:$PATH" GH_STUB_LOG="$tmp/log" GITHUB_REPOSITORY=cipherstash/encrypt-query-language \
      GH_VERIFIED=false GH_REASON=unknown_key \
      release_alpha_verify_commit_signature abc123 2>&1
  )"
  status=$?
  if [[ "$status" -ne 0 && "$output" == *"not GitHub-verified"* && "$output" == *"reason=unknown_key"* ]]; then
    echo "ok: unverified GitHub signature fails"
  else
    echo "FAIL: unverified signature status=$status output='$output'"
    fail=1
  fi
  rm -rf "$tmp"
}

check_non_valid_reason_fails() {
  local output status
  setup_gh
  output="$(
    PATH="$tmp/bin:$PATH" GH_STUB_LOG="$tmp/log" GITHUB_REPOSITORY=cipherstash/encrypt-query-language \
      GH_VERIFIED=true GH_REASON=unverified_email \
      release_alpha_verify_commit_signature abc123 2>&1
  )"
  status=$?
  if [[ "$status" -ne 0 && "$output" == *"not GitHub-verified"* && "$output" == *"reason=unverified_email"* ]]; then
    echo "ok: non-valid GitHub verification reason fails"
  else
    echo "FAIL: non-valid reason status=$status output='$output'"
    fail=1
  fi
  rm -rf "$tmp"
}

check_valid_signature
check_unverified_signature_fails
check_non_valid_reason_fails

exit "$fail"
