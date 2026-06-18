# shellcheck shell=bash
# DB-free stub preamble for the `encrypted_domain` test binary.
#
# `encrypted_domain` `include_str!`s its per-type fixtures (the gitignored,
# generated `tests/sqlx/fixtures/eql_v2_<T>.sql`) at COMPILE time, so a bare
# worktree without CipherStash creds (the no-creds `matrix-coverage` /
# `macro-coverage` CI jobs, or any local checkout that hasn't run
# `mise run test:sqlx:prep`) cannot even compile it for `--list`. These
# inventory/coverage gates never RUN tests — they only need the binary to
# compile and emit its test-name list — so empty stub files satisfy
# `include_str!` perfectly.
#
# SOURCE this (don't execute it): it must set its cleanup trap and export the
# `listing` variable into the caller's shell. It creates only the files rustc
# reports missing (one error pass lists them all) and removes exactly those on
# exit, leaving any real generated fixtures untouched.
#
# Inputs (set before sourcing):
#   EQL_ROOT  - repo root (mise `{{config_root}}`). Falls back to two levels up
#               from the task's `tests/sqlx` working directory.
# Output:
#   listing   - the binary's `--list` output, stripped of the `: test` suffix.
#
# Bash 3.2 compatible (macOS): no mapfile/arrays; created stubs are tracked in a
# temp file. Keep this in lockstep with `tasks/test/sqlx-archive.sh` /
# `test:sqlx:prep`, which produce the REAL fixtures for the jobs that run tests.

__eql_stub_root="${EQL_ROOT:-$(cd ../.. && pwd)}"

__eql_stub_created=$(mktemp)
trap 'while IFS= read -r f; do [ -n "$f" ] && rm -f "$f"; done < "$__eql_stub_created"; rm -f "$__eql_stub_created"' EXIT

__eql_stub_err=$(mktemp)
__eql_stub_i=0
while :; do
  if listing=$(cargo test --no-default-features --test encrypted_domain -- --list 2>"$__eql_stub_err"); then
    break
  fi
  # Missing include_str! targets are the *.sql paths in the compile errors
  # (repo-root-relative, may contain `..`). Match path chars only.
  __eql_stub_missing=$(grep -oE "[A-Za-z0-9_./-]+\.sql" "$__eql_stub_err" | LC_ALL=C sort -u || true)
  if [ -z "$__eql_stub_missing" ]; then
    echo "encrypted_domain failed to list for a non-fixture reason:" >&2
    cat "$__eql_stub_err" >&2
    rm -f "$__eql_stub_err"; exit 1
  fi
  while IFS= read -r __eql_stub_m; do
    [ -n "$__eql_stub_m" ] || continue
    __eql_stub_p="${__eql_stub_root}/${__eql_stub_m}"
    if [ ! -e "$__eql_stub_p" ]; then
      mkdir -p "$(dirname "$__eql_stub_p")"
      : > "$__eql_stub_p"
      echo "$__eql_stub_p" >> "$__eql_stub_created"
    fi
  done <<< "$__eql_stub_missing"
  __eql_stub_i=$((__eql_stub_i + 1))
  [ "$__eql_stub_i" -lt 12 ] || { echo "stub loop exceeded 12 iterations" >&2; cat "$__eql_stub_err" >&2; rm -f "$__eql_stub_err"; exit 1; }
done
rm -f "$__eql_stub_err"
[ -n "$listing" ] || { echo "No tests listed from the encrypted_domain binary." >&2; exit 1; }
listing=$(printf '%s\n' "$listing" | sed -n 's/: test$//p')
