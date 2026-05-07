--! @file pin_search_path.sql
--! @brief Post-install: opt-in pinner for eql_v2.* functions
--!
--! Appended verbatim by `tasks/build.sh` to the end of every release variant
--! (main, supabase, protect/stack), AFTER all `src/**/*.sql` files have been
--! concatenated. Lives outside `src/` so it stays out of the dependency
--! graph entirely — each variant has a different leaf set, and threading
--! REQUIREs to be ordered last in every variant simultaneously is fragile.
--!
--! ## Opt-in semantics
--!
--! This pinner only ALTERs functions that are **explicitly tagged** with
--! `@noinline` in their PostgreSQL `COMMENT ON FUNCTION ...` description.
--! The default is to leave functions alone — so adding a new SQL function
--! cannot silently disable inlining and the perf regressions that follow.
--!
--! Two ways for an author to make a plpgsql (or otherwise non-inlinable)
--! function splinter-compliant:
--!
--! 1. **Inline `SET search_path = pg_catalog, extensions, public`** in the
--!    function definition itself. Preferred for new code — it lives next to
--!    the body and survives builds even if this pinner is removed.
--! 2. **`COMMENT ON FUNCTION ... IS '@noinline'`** as a sibling statement
--!    after the `CREATE FUNCTION`. Useful for templated/generated code where
--!    inline `SET` is awkward, or when the comment is needed for other
--!    reasons (e.g. documentation).
--!
--! Inlinable SQL functions (`@>`, `<@`, `jsonb_contains`, `=`, `<>`, `~~`,
--! `order_by_ope`, etc.) **must not** carry `@noinline` — they need
--! `proconfig` to stay NULL so the planner can inline their bodies into
--! query expressions and match the relevant functional indexes. Splinter
--! will flag them; cover them in `tasks/test/splinter.sh`'s allowlist with
--! a justification.
--!
--! ## Why opt-in
--!
--! The previous opt-out model (pin everything except an explicit denylist)
--! had a silent failure mode: any new SQL function authors flipped from
--! plpgsql to inlinable SQL would be re-pinned at install time, killing
--! inlining without any test failure. See issue #199 for the redesign
--! discussion that produced this file.
--!
--! @see tasks/test/splinter.sh
--! @see tasks/build.sh

DO $$
DECLARE
  fn_oid oid;
BEGIN
  FOR fn_oid IN
    SELECT p.oid
    FROM pg_catalog.pg_proc p
    JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    LEFT JOIN pg_catalog.pg_description d
      ON d.objoid = p.oid AND d.classoid = 'pg_catalog.pg_proc'::regclass AND d.objsubid = 0
    WHERE n.nspname = 'eql_v2'
      -- Only normal functions ('f') and window functions ('w') accept
      -- ALTER FUNCTION ... SET. Aggregates ('a') would be rejected by
      -- ALTER ROUTINE/FUNCTION, and procedures ('p') would need ALTER
      -- PROCEDURE. The 3 affected aggregates (min, max, grouped_value)
      -- are allowlisted in splinter.
      AND p.prokind IN ('f', 'w')
      -- Skip functions that already have search_path pinned in source
      -- (preferred convention for plpgsql functions).
      AND NOT EXISTS (
        SELECT 1 FROM pg_catalog.unnest(coalesce(p.proconfig, '{}'::text[])) c
        WHERE c LIKE 'search_path=%'
      )
      -- Opt-in: only pin functions tagged @noinline. Without this the
      -- previous version pinned everything by default and silently broke
      -- inlining for any newly-authored SQL function (issue #199).
      AND coalesce(d.description, '') LIKE '%@noinline%'
  LOOP
    -- oid::regprocedure renders as `schema.name(argtype, argtype)` and is a
    -- valid target for ALTER FUNCTION regardless of caller search_path.
    EXECUTE pg_catalog.format(
      'ALTER FUNCTION %s SET search_path = pg_catalog, extensions, public',
      fn_oid::regprocedure
    );
  END LOOP;
END $$;
