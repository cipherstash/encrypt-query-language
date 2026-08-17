---
'@cipherstash/eql': patch
---

**`eql_v3.ste_vec_contains` is renamed to `eql_v3.jsonb_document_contains`.** This
consolidates the last `ste_vec_*`-named public object into the `jsonb_*` family,
matching the earlier renames of the SteVec entry/query surface (`jsonb_entry`,
`jsonb_query`). The old name remains available as a deprecated compatibility
alias, so existing direct callers continue to work; new code should use
`jsonb_document_contains`. The `json` `@>` / `<@` containment operators and the
raw-jsonb function-form entry points, `eql_v3.jsonb_contains(jsonb, jsonb)` and
`eql_v3.jsonb_contained_by(jsonb, jsonb)`, are unchanged.
