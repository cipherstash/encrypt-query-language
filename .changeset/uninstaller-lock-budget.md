---
'@cipherstash/eql': patch
---

**Documented: the uninstaller's lock footprint now exceeds Postgres's default budget.** The single-transaction uninstaller (`DROP SCHEMA eql_v3 CASCADE` + `DROP SCHEMA eql_v3_internal CASCADE`) takes one lock per dropped object — 6,433 measured on this release — against the 6,400 slots a default `max_locks_per_transaction = 64` cluster affords cluster-wide. A lone uninstall on a quiet cluster succeeds (the lock table overflows into spare shared memory), but under concurrent load it can fail with `out of shared memory / You might need to increase max_locks_per_transaction`, whose remedy requires a server restart. See upgrade note U-009 in `docs/upgrading/v3.0.md` for the quiet-window / raise-ahead-of-time guidance and a way to preview the footprint without dropping anything. Installation is unaffected — `CREATE` takes no per-object lock.
