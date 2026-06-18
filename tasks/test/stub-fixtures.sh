# shellcheck shell=bash
# Catalog-driven stub preamble for the `encrypted_domain` test binary.
#
# `encrypted_domain` `include_str!`s its per-type fixtures (the gitignored,
# generated `tests/sqlx/fixtures/eql_v2_<T>.sql`) at COMPILE time, so a bare
# worktree without CipherStash creds (the no-creds matrix-coverage CI job, or a
# checkout that has not run `mise run test:sqlx:prep`) cannot compile it for
# `--list`. These inventory/coverage gates never RUN tests — they only need the
# binary to compile and emit its test-name list — so empty stub files satisfy
# `include_str!` perfectly.
#
# SOURCE this (don't execute it): it must set its cleanup trap and export the
# `listing` variable into the caller's shell.
#
# The fixture set is derived from the CATALOG (`eql-codegen list-types`) — the
# single source of truth — one stub per scalar token, `eql_v2_<token>.sql`. This
# deliberately replaces an earlier preamble that discovered the set by parsing
# missing `.sql` paths out of rustc's compile errors and retried in a loop: that
# was brittle (coupled to rustc's error wording, capped at 12 iterations, silent
# if the format changed). A new scalar in the catalog is stubbed automatically;
# if some NEW compile-time `include_str!` target ever appears that is *not*
# `eql_v2_<token>.sql`, the `--list` below fails with rustc's own clear
# "couldn't read <path>" error — add that file's stub here.
#
# Inputs (set before sourcing):
#   EQL_ROOT  - repo root (mise `{{config_root}}`). Falls back to two levels up
#               from the task's `tests/sqlx` working directory.
# Output:
#   listing   - the binary's `--list` output, stripped of the `: test` suffix.
#
# Bash 3.2 compatible (macOS): created stubs are tracked in a temp file. Keep in
# step with `tasks/test/sqlx-archive.sh` / `test:sqlx:prep`, which produce the
# REAL fixtures for the jobs that actually run tests.

__eql_stub_root="${EQL_ROOT:-$(cd ../.. && pwd)}"
__eql_stub_dir="${__eql_stub_root}/tests/sqlx/fixtures"

__eql_stub_created=$(mktemp)
trap 'while IFS= read -r f; do [ -n "$f" ] && rm -f "$f"; done < "$__eql_stub_created"; rm -f "$__eql_stub_created"' EXIT

# Catalog scalar tokens (the source of truth). A failure here aborts under the
# caller's `set -e` with cargo's own error — no silent fallback.
__eql_stub_tokens=$(cd "$__eql_stub_root" && cargo run -q -p eql-codegen -- list-types)

# One empty stub per token, created only when absent — real generated fixtures
# are never in the created list, so the trap leaves them untouched.
mkdir -p "$__eql_stub_dir"
while IFS= read -r __eql_stub_t; do
  [ -n "$__eql_stub_t" ] || continue
  __eql_stub_f="${__eql_stub_dir}/eql_v2_${__eql_stub_t}.sql"
  if [ ! -e "$__eql_stub_f" ]; then
    : > "$__eql_stub_f"
    echo "$__eql_stub_f" >> "$__eql_stub_created"
  fi
done <<EOF
$__eql_stub_tokens
EOF

# Compile + list. On a missing non-token fixture this fails with rustc's own
# "couldn't read <path>" error (see header). Sets `listing` (stripped).
listing=$(cargo test --no-default-features --test encrypted_domain -- --list | sed -n 's/: test$//p')
[ -n "$listing" ] || { echo "No tests listed from the encrypted_domain binary." >&2; exit 1; }
