---
'@cipherstash/eql': major
---

**The self-contained `eql_v3` installer is now the sole release artifact, shipped under the canonical name `release/cipherstash-encrypt.sql` (+ `cipherstash-encrypt-uninstall.sql`).** The combined, Supabase, and Protect build variants are removed; `mise run build` now produces only the `eql_v3` surface, written under the canonical name that the combined build previously used — so existing install URLs keep working. Why: with `eql_v2` removed (see below), there is a single SQL surface to build, install, and test.
