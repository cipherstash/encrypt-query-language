#!/usr/bin/env bash
#MISE description="Doxygen input filter for SQL files"
set -euo pipefail

# Doxygen always calls an INPUT_FILTER with exactly one filename. Guard it so a
# stray invocation fails fast instead of `awk` blocking on stdin and hanging the
# docs job.
if [ "$#" -ne 1 ]; then
  echo "usage: $(basename "$0") <file.sql>" >&2
  exit 2
fi

# Prepares SQL for Doxygen's C++ parser. Two transforms:
#
#  1. `--!` doc comments -> `//!` so Doxygen sees them.
#  2. Strip dollar-quoted function bodies (`$$ ... $$`), leaving just the
#     declaration and its trailing clauses. Doxygen parses SQL heuristically as
#     C++, and body SQL derails it: a `::type` cast reads as C++ scope
#     resolution and drops the whole enclosing CREATE FUNCTION memberdef (this
#     silently lost jsonb_path_query and ~hundreds of generated extractor
#     overloads), while keywords/calls in bodies (`SELECT`, `RETURN NEXT`,
#     `array_length(...)`) get mis-parsed as spurious functions. Bodies carry no
#     documentation, so removing them is lossless for the generated reference
#     and leaves Doxygen only clean `CREATE FUNCTION name(args) RETURNS ...`
#     declarations to read. Only bare `$$` quoting is used in this codebase.
awk '
  /^--!/ { print "//!" substr($0, 4); next }
  {
    out = ""
    s = $0
    while (length(s) > 0) {
      p = index(s, "$$")
      if (inbody) {
        if (p == 0) { s = ""; break }        # whole remainder is body: drop
        s = substr(s, p + 2)                  # resume after the closing $$
        inbody = 0
      } else {
        if (p == 0) { out = out s; break }    # no body marker: keep as-is
        out = out substr(s, 1, p - 1)         # keep code before opening $$
        s = substr(s, p + 2)
        inbody = 1
      }
    }
    # Regular SQL `--` comments read as C++ code to Doxygen (e.g.
    # `-- per-entry overloads (...)` mints a phantom `overloads(...)` function),
    # so neutralize them to C++ line comments on the (body-stripped) code.
    gsub(/--/, "//", out)
    print out
  }
' "$1"
