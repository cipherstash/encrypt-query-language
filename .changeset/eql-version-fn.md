---
'@cipherstash/eql': minor
---

**`eql_v3.version()` — version introspection on the self-contained `eql_v3` surface.** `SELECT eql_v3.version()` returns the installed EQL version as bare-semver text (e.g. `'3.0.0'`, or `'DEV'` for local builds); the same value is published as the `eql_v3` schema comment, so it is also readable via `obj_description('eql_v3'::regnamespace)`. The version is baked in at build time from the release tag via `mise run build --version` (now passed as prefix-stripped semver by both release workflows). This replaces the removed `eql_v2.version()` (dropped with the rest of the `eql_v2` surface — see Removed): the "which EQL is installed?" probe moves to `eql_v3`, consistent with the schema namespace move. Why: the self-contained `eql_v3` surface had no version-introspection point after `eql_v2` was removed.
