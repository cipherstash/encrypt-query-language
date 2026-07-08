#!/usr/bin/env bash
# Sourceable dependency-ordering helpers for the eql_v3 build. No side effects on
# source; each function is pure w.r.t. its args. Shared with the staged-installer
# refactor (do not fork strip_require_lines).

# Emit a file's body with anchored `-- REQUIRE:` directive lines removed. Anchored
# (allows leading whitespace) so a body line that merely contains the substring
# "REQUIRE" survives — unlike the old unanchored `grep -v REQUIRE`.
strip_require_lines() {
  grep -vE '^[[:space:]]*-- REQUIRE:' "$1" || true
}

# tsort with a cross-platform cycle gate. Input edges are "<dep> <file>" (one per
# line, dependency FIRST) so plain tsort yields dependency-before-file order with
# no `tac`. BSD/macOS tsort exits 0 on a cycle but writes "tsort: cycle in data"
# to stderr; GNU exits 1. We fail on ANY tsort stderr, catching cycles on both.
# NOTE: the extraction emits a self-edge "<file> <file>" for every file so an
# isolated file still appears in the output. A self-edge is a tsort NO-OP, NOT a
# cycle — `printf 'a a\n' | tsort` prints `a` with empty stderr and exit 0 on
# both BSD and GNU, so self-edges never trip this stderr-based cycle-fail.
run_tsort_or_die() {
  local edges=$1 out=$2 err
  err="$(mktemp)"
  tsort "$edges" > "$out" 2> "$err" || true
  if [[ -s "$err" ]]; then
    echo "ERROR: tsort reported a problem ordering $edges (cycle or malformed edge):" >&2
    cat "$err" >&2
    rm -f "$err"
    return 1
  fi
  rm -f "$err"
}

# Assert the assembled order is a valid linearization: for every "<dep> <file>"
# edge, dep must appear at or before file in <ordered_file>. Self-edges and edges
# whose endpoints are absent from the order are skipped (absence is caught by
# verify_deps_exist). Complements run_tsort_or_die's cycle check with a direct
# check on the FINAL order (the two-phase concat is not produced by one tsort).
verify_linearization() {
  local edges=$1 ordered=$2
  awk '
    NR==FNR { pos[$0]=FNR; next }
    { if ($1=="" || $1==$2) next
      if (!($1 in pos) || !($2 in pos)) next
      if (pos[$1] > pos[$2]) {
        printf("ERROR: %s is required by %s but is ordered AFTER it\n", $1, $2) > "/dev/stderr"
        bad=1
      } }
    END { exit bad ? 1 : 0 }
  ' "$ordered" "$edges"
}
