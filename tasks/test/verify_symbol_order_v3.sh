#!/usr/bin/env bash
#MISE description="Cross-check that every eql_v3/eql_v3_internal/public-domain symbol referenced in a file is defined by a file ordered earlier"
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

ORDERED="${1:-src/deps-ordered-v3.txt}"
ALLOW="tasks/test/symbol_order_allowlist.txt"
test -f "$ORDERED" || { echo "ERROR: ordered file $ORDERED missing (run mise run build)" >&2; exit 2; }

awk -v allowfile="$ALLOW" '
  BEGIN {
    idx = 0
    while ((getline a < allowfile) > 0) {
      sub(/#.*/, "", a); gsub(/[ \t]+/, "", a)
      if (a != "") allow[a] = 1
    }
  }
  # $0 here is a path from the ordered list.
  {
    idx++
    file = $0
    # Fail loudly on an UNREADABLE path rather than silently treating it as an
    # empty (zero-definition) file: getline returns -1 on error but 0 at EOF for
    # a genuinely empty file, so only -1 is a fault. This guards both passes — a
    # file flagged here sets bad=1, and the END block exits non-zero.
    if ((getline probe < file) < 0) {
      printf("ERROR: cannot read %s (listed in the ordered file)\n", file) > "/dev/stderr"
      bad = 1
    }
    close(file)
    # First pass over the file: record DEFINITIONS with this index (min index kept).
    while ((getline line < file) > 0) {
      # Strip trailing line comments so prose/doxygen never counts as code.
      sub(/--.*/, "", line)
      # CREATE [OR REPLACE] FUNCTION|AGGREGATE eql_v3(_internal).<name|"op">
      if (match(line, /CREATE[ \t]+(OR[ \t]+REPLACE[ \t]+)?(FUNCTION|AGGREGATE)[ \t]+(eql_v3_internal|eql_v3)\.("[^"]+"|[a-z0-9_]+)/)) {
        s = substr(line, RSTART, RLENGTH); sub(/.*(eql_v3_internal|eql_v3)\./, "", s)
        schema = (index(substr(line,RSTART,RLENGTH), "eql_v3_internal.") ? "eql_v3_internal." : "eql_v3.")
        key = schema s
        if (!(key in defined)) defined[key] = idx
      }
      # CREATE DOMAIN (eql_v3_internal|public).<name>. Both schemas: the SEM
      # index-term types split across DDL forms — hmac_256/ope_cllw/bloom_filter
      # are `CREATE DOMAIN eql_v3_internal.<name>` (over text/bytea/smallint[]),
      # NOT `CREATE TYPE`. Capturing only `public.` here would leave the three
      # most-referenced foundational types (~165 refs) reporting "defined
      # nowhere" — a real gap, not an allowlist case. Only `public.` domains feed
      # isdomain[] (that gates which `public.*` REFERENCES are checked).
      if (match(line, /CREATE[ \t]+DOMAIN[ \t]+(eql_v3_internal|public)\.[a-z0-9_]+/)) {
        seg = substr(line, RSTART, RLENGTH)
        if (seg ~ /eql_v3_internal\./) { sub(/.*eql_v3_internal\./, "", seg); key = "eql_v3_internal." seg }
        else                          { sub(/.*public\./, "", seg);          key = "public." seg; isdomain[seg] = 1 }
        if (!(key in defined)) defined[key] = idx
      }
      # CREATE TYPE eql_v3_internal.<name> (the composite SEM types: ore_block_256, ore_cllw)
      if (match(line, /CREATE[ \t]+TYPE[ \t]+eql_v3_internal\.[a-z0-9_]+/)) {
        s = substr(line, RSTART, RLENGTH); sub(/.*eql_v3_internal\./, "", s)
        key = "eql_v3_internal." s; if (!(key in defined)) defined[key] = idx
      }
      # CREATE OPERATOR CLASS|FAMILY (eql_v3_internal|eql_v3).<name>. The conditional
      # SEM ordered-index opclasses (ore_block_256_operator_class/_family,
      # ore_cllw_ops), created via EXECUTE / plpgsql for superusers. Each is fully
      # self-contained in its own operator_class.sql — the only other mentions are
      # RAISE NOTICE string-literal prose in the SAME file — so recognising this
      # definition form (like CREATE TYPE/DOMAIN above) keeps them from reading as
      # "defined nowhere", while still catching a genuine cross-file mis-order.
      if (match(line, /CREATE[ \t]+OPERATOR[ \t]+(CLASS|FAMILY)[ \t]+(eql_v3_internal|eql_v3)\.[a-z0-9_]+/)) {
        s = substr(line, RSTART, RLENGTH)
        schema = (index(s, "eql_v3_internal.") ? "eql_v3_internal." : "eql_v3.")
        sub(/.*(eql_v3_internal|eql_v3)\./, "", s)
        key = schema s; if (!(key in defined)) defined[key] = idx
      }
    }
    close(file)
    order[idx] = file
  }
  END {
    # Second pass: for every file, collect REFERENCES (code only) and check them.
    for (i = 1; i <= idx; i++) {
      file = order[i]
      while ((getline line < file) > 0) {
        sub(/--.*/, "", line)               # drop comments
        rest = line
        # eql_v3.<name> and eql_v3_internal.<name|"op">
        while (match(rest, /(eql_v3_internal|eql_v3)\.("[^"]+"|[a-z0-9_]+)/)) {
          tok = substr(rest, RSTART, RLENGTH)
          rest = substr(rest, RSTART + RLENGTH)
          check(tok, i, file)
        }
        # public.<domain> — ONLY names we saw defined as a domain (avoids public tables/builtins).
        rest = line
        while (match(rest, /public\.[a-z0-9_]+/)) {
          tok = substr(rest, RSTART, RLENGTH); rest = substr(rest, RSTART + RLENGTH)
          name = tok; sub(/public\./, "", name)
          if (name in isdomain) check(tok, i, file)
        }
      }
      close(file)
    }
    if (bad) { print "symbol-order cross-check FAILED" > "/dev/stderr"; exit 1 }
    print "symbol-order cross-check OK (" idx " files)"
  }
  function check(tok, i, file) {
    if (tok in allow) return
    if (!(tok in defined)) {
      # Referenced owned-schema symbol never defined anywhere: a real hole.
      printf("ERROR: %s references %s which is defined nowhere in the installer\n", file, tok) > "/dev/stderr"
      bad = 1; return
    }
    if (defined[tok] > i) {
      printf("ERROR: %s references %s defined later (at #%d, used at #%d)\n", file, tok, defined[tok], i) > "/dev/stderr"
      bad = 1
    }
  }
' "$ORDERED"
