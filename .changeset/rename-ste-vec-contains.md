---
'@cipherstash/eql': patch
---

**`eql_v3.ste_vec_contains` is renamed to `eql_v3.jsonb_document_contains`.** This
consolidates the last `ste_vec_*`-named public object into the `jsonb_*` family,
matching the earlier renames of the SteVec entry/query surface (`jsonb_entry`,
`jsonb_query`). The `@>` / `<@` containment operators are untouched, and so are
the raw-jsonb function-form entry points, `eql_v3.jsonb_contains(jsonb, jsonb)`
and `eql_v3.jsonb_contained_by(jsonb, jsonb)` — a PostgREST deployment calling
those by name sees no change.

What breaks is hand-written SQL that names `ste_vec_contains` directly: queries,
views, and RLS policies that call it, and any per-function `GRANT EXECUTE ON
FUNCTION eql_v3.ste_vec_contains(...)`. The schema-wide grant recipes in
`docs/reference/permissions.md` (`GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA
eql_v3 ...`) pick the new name up automatically on their next run; a stale
per-function grant referencing the old name fails loudly at apply time
(`function eql_v3.ste_vec_contains(...) does not exist`) rather than silently
granting nothing. And underneath all of it: the installer opens with `DROP
SCHEMA IF EXISTS eql_v3 CASCADE`, so every EQL install already drops and
recreates grants, functional indexes, and dependent views on upgrade — that is
not new behaviour introduced by this rename.
