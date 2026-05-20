--! @file pin_search_path.sql
--! @brief Post-install: pin search_path on every eql_v2.* function
--!
--! This file is appended verbatim by `tasks/build.sh` to the end of every
--! release variant (main, supabase, protect/stack), AFTER all `src/**/*.sql`
--! files have been concatenated. It lives outside `src/` so it stays out of
--! the dependency graph entirely — each variant has a different leaf set
--! (supabase excludes `**/*operator_class.sql`; protect excludes `src/config/*`
--! and `src/encryptindex/*`), and threading REQUIREs to be ordered last in
--! every variant simultaneously is fragile.
--!
--! Iterates over functions in the `eql_v2` schema and applies a fixed
--! `search_path` via `ALTER FUNCTION ... SET search_path = ...`. This is the
--! only way to satisfy Supabase splinter's `function_search_path_mutable`
--! lint, which checks `pg_proc.proconfig` directly.
--!
--! @note A SET clause disables PostgreSQL's SQL-function inlining (see
--!       inline_function() in src/backend/optimizer/util/clauses.c). For most
--!       eql_v2 helpers this is irrelevant. The exceptions are wrappers that
--!       must inline to expose `eql_v2.jsonb_array(col) @> ...` to the planner
--!       so the GIN index on `jsonb_array(e)` can be matched. Those are
--!       deliberately skipped here and allowlisted in `tasks/test/splinter.sh`.
--!
--! @see tasks/test/splinter.sh
--! @see tasks/build.sh

DO $$
DECLARE
  fn_oid oid;
  inline_critical_oids oid[];
  enc_oid oid;
  jsonb_oid oid;
  text_oid oid;
  entry_oid oid;
BEGIN
  -- Resolve type oids without depending on caller search_path. The encrypted
  -- composite type is created in `public`; jsonb / text are in `pg_catalog`;
  -- the ste_vec_entry DOMAIN lives in `eql_v2`.
  SELECT t.oid INTO enc_oid
  FROM pg_catalog.pg_type t
  JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
  WHERE n.nspname = 'public' AND t.typname = 'eql_v2_encrypted';

  IF enc_oid IS NULL THEN
    RAISE EXCEPTION 'pin_search_path: type public.eql_v2_encrypted not found — '
      'this script must run after all EQL src/**/*.sql files have been loaded';
  END IF;

  SELECT t.oid INTO jsonb_oid
  FROM pg_catalog.pg_type t
  JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
  WHERE n.nspname = 'pg_catalog' AND t.typname = 'jsonb';

  IF jsonb_oid IS NULL THEN
    RAISE EXCEPTION 'pin_search_path: type pg_catalog.jsonb not found';
  END IF;

  SELECT t.oid INTO text_oid
  FROM pg_catalog.pg_type t
  JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
  WHERE n.nspname = 'pg_catalog' AND t.typname = 'text';

  IF text_oid IS NULL THEN
    RAISE EXCEPTION 'pin_search_path: type pg_catalog.text not found';
  END IF;

  SELECT t.oid INTO entry_oid
  FROM pg_catalog.pg_type t
  JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
  WHERE n.nspname = 'eql_v2' AND t.typname = 'ste_vec_entry';

  IF entry_oid IS NULL THEN
    RAISE EXCEPTION 'pin_search_path: type eql_v2.ste_vec_entry not found';
  END IF;

  -- Wrappers that must remain inlinable for functional-index matching.
  -- Verified empirically: with SET, EXPLAIN drops to Seq Scan; without,
  -- it uses Bitmap Index Scan / Index Scan.
  --
  -- Phase 1 operator inlining (#193): `=`, `<>`, `~~`, `~~*`, `@>`, `<@`
  -- on `eql_v2_encrypted` and the cross-type (encrypted, jsonb) /
  -- (jsonb, encrypted) overloads emitted by ORMs that bind parameters
  -- as jsonb (Drizzle, PostgREST, encryptedSupabase). The implementation
  -- functions reduce to `extractor(a) op extractor(b)` and must inline
  -- to match the documented functional indexes
  -- (`eql_v2.hmac_256(col)`, `eql_v2.bloom_filter(col)`,
  -- `eql_v2.ste_vec(col)`).
  --
  -- For `~~` / `~~*` the planner must inline two layers — the operator
  -- function `eql_v2."~~"` and the helper `eql_v2.like` / `eql_v2.ilike`
  -- — to reach the canonical `eql_v2.bloom_filter(a) @> eql_v2.bloom_filter(b)`
  -- form that the documented functional index matches. The helpers are
  -- allowlisted alongside the operator wrappers below; pinning either
  -- layer breaks the chain and reverts to Seq Scan.
  --
  -- Note: pg_proc.proargtypes is an oidvector with 0-based bounds, so we
  -- compare elements individually rather than using array equality (which
  -- requires matching bounds, not just contents).
  SELECT pg_catalog.array_agg(p.oid) INTO inline_critical_oids
  FROM pg_catalog.pg_proc p
  JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'eql_v2'
    AND (
      -- Same-type (encrypted, encrypted) operators that must inline.
      -- `like`/`ilike` are the SQL helpers that `~~`/`~~*` delegate to;
      -- both layers must inline to reach `bloom_filter(a) @> bloom_filter(b)`.
      -- `<`, `<=`, `>`, `>=` inline to `ore_block_u64_8_256(a) op
      -- ore_block_u64_8_256(b)`; they must reach the functional ORE index
      -- expression `eql_v2.ore_block_u64_8_256(col)` for bare range
      -- queries to engage Index Scan.
      (p.pronargs = 2
        AND p.proname IN ('=', '<>', '<', '<=', '>', '>=',
                          '~~', '~~*', '@>', '<@',
                          'jsonb_contains', 'jsonb_contained_by',
                          'like', 'ilike')
        AND p.proargtypes[0] = enc_oid AND p.proargtypes[1] = enc_oid)
      -- Cross-type (encrypted, jsonb).
      OR (p.pronargs = 2
        AND p.proname IN ('=', '<>', '<', '<=', '>', '>=',
                          '~~', '~~*',
                          'jsonb_contains', 'jsonb_contained_by')
        AND p.proargtypes[0] = enc_oid AND p.proargtypes[1] = jsonb_oid)
      -- Cross-type (jsonb, encrypted).
      OR (p.pronargs = 2
        AND p.proname IN ('=', '<>', '<', '<=', '>', '>=',
                          '~~', '~~*',
                          'jsonb_contains', 'jsonb_contained_by')
        AND p.proargtypes[0] = jsonb_oid AND p.proargtypes[1] = enc_oid)
      -- Root-level HMAC extractor (#205): all 1-arg overloads are now
      -- inlinable SQL. Must stay unpinned so the planner can fold extractor
      -- calls inside the inlined equality operator bodies into the calling
      -- query, preserving the functional-index match.
      OR (p.pronargs = 1
        AND p.proname = 'hmac_256'
        AND (p.proargtypes[0] = enc_oid OR p.proargtypes[0] = jsonb_oid))
      -- Field-level equality extractor (#205): the inlinable counterpart to
      -- the root-level `eql_v2.hmac_256(col)`. Must inline so the planner
      -- can fold `eql_v2.hmac_256(col, '<selector>')` into the calling
      -- query for WHERE / GROUP BY / DISTINCT / hash-join, matching a
      -- functional hash index on the same expression.
      OR (p.pronargs = 2
        AND p.proname = 'hmac_256'
        AND p.proargtypes[0] = enc_oid AND p.proargtypes[1] = text_oid)
      -- Field-level HMAC terms aggregate (#205): GIN-indexable jsonb array
      -- of `{s, hm}` pairs. Must inline so
      -- `eql_v2.hmac_256_terms(col) @> $1::jsonb` engages the GIN index on
      -- the same expression.
      OR (p.pronargs = 1
        AND p.proname = 'hmac_256_terms'
        AND p.proargtypes[0] = enc_oid)
      -- Field-level JSONB extractors (#205): inlinable SQL replacements for
      -- the previous plpgsql bodies. Inlining lets the planner fold the
      -- `jsonb_array_elements(...) WHERE elem->>'s' = selector` body into
      -- the calling query, eliminating per-row function call overhead on
      -- large ste_vec scans.
      OR (p.pronargs = 2
        AND p.proname IN ('jsonb_path_query',
                          'jsonb_path_query_first',
                          'jsonb_path_exists'))
      -- Inner ORE-block comparison helpers backing the `<`, `<=`, `>`, `>=`
      -- operators on `eql_v2.ore_block_u64_8_256`. The outer operators on
      -- `eql_v2_encrypted` inline to `ore_block(a) <op> ore_block(b)`, and
      -- PG only carries the inlined form through to index matching if the
      -- inner operator function is also inlinable (no SET, IMMUTABLE).
      -- Pinning these would prevent the planner from structurally matching
      -- predicates against a functional `eql_v2.ore_block_u64_8_256(col)`
      -- index. The inner functions are deterministic comparisons of
      -- composite type bytes, declared IMMUTABLE STRICT PARALLEL SAFE.
      OR (p.pronargs = 2
        AND p.proname IN ('ore_block_u64_8_256_eq', 'ore_block_u64_8_256_neq',
                          'ore_block_u64_8_256_lt', 'ore_block_u64_8_256_lte',
                          'ore_block_u64_8_256_gt', 'ore_block_u64_8_256_gte'))
      -- Hash operator class FUNCTION 1: called once per row by HashAggregate,
      -- hash joins, DISTINCT. Inlinable SQL avoids the per-row plpgsql
      -- interpreter overhead — without this, `GROUP BY value` on
      -- `eql_v2_encrypted` at 1M rows degrades super-linearly because the
      -- plpgsql cost compounds with HashAggregate work_mem spillage.
      OR (p.pronargs = 1
        AND p.proname = 'hash_encrypted'
        AND p.proargtypes[0] = enc_oid)
      -- Consolidated ORE-CLLW extractor (U-006). Inlinable SQL — pinning
      -- would silently undo it and prevent the planner from folding
      -- `eql_v2.ore_cllw(col)` calls into the calling query. The
      -- `compare_ore_cllw_term` comparator stays plpgsql by design (per-byte
      -- protocol can't be expressed as a single inlinable SELECT), so it is
      -- NOT on this list. The (jsonb) form is a RHS-parameter helper for
      -- comparisons against literal jsonb; the (eql_v2.ste_vec_entry) form
      -- is the typed extractor for the result of `col -> '<selector>'`.
      OR (p.pronargs = 1
        AND p.proname IN ('ore_cllw', 'has_ore_cllw')
        AND (p.proargtypes[0] = jsonb_oid OR p.proargtypes[0] = entry_oid))
      -- Typed HMAC extractor on a ste_vec entry (#219 strict separation).
      -- Same rationale as `ore_cllw(ste_vec_entry)` — must inline so
      -- `eql_v2.hmac_256(col -> 'sel')` folds into the calling query and
      -- matches a functional hash index built on the same expression.
      OR (p.pronargs = 1
        AND p.proname IN ('hmac_256', 'has_hmac_256', 'selector')
        AND p.proargtypes[0] = entry_oid)
      -- `eql_v2.ste_vec_entry × eql_v2.ste_vec_entry` operators (#219).
      -- Inline to `hmac_256(a) = hmac_256(b)` (equality) or
      -- `ore_cllw(a) <op> ore_cllw(b)` (ordering); both chains must remain
      -- unpinned for functional-index match through extractor form.
      OR (p.pronargs = 2
        AND p.proname IN ('=', '<>', '<', '<=', '>', '>=',
                          'eq', 'neq', 'lt', 'lte', 'gt', 'gte')
        AND p.proargtypes[0] = entry_oid AND p.proargtypes[1] = entry_oid)
    );

  FOR fn_oid IN
    SELECT p.oid
    FROM pg_catalog.pg_proc p
    JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'eql_v2'
      -- Only normal functions ('f') and window functions ('w') accept
      -- ALTER FUNCTION ... SET. Aggregates ('a') would be rejected by
      -- ALTER ROUTINE/FUNCTION, and procedures ('p') would need ALTER
      -- PROCEDURE. The 3 affected aggregates (min, max, grouped_value)
      -- are allowlisted in splinter.
      AND p.prokind IN ('f', 'w')
      AND NOT EXISTS (
        SELECT 1 FROM pg_catalog.unnest(coalesce(p.proconfig, '{}'::text[])) c
        WHERE c LIKE 'search_path=%'
      )
      AND NOT (p.oid = ANY (coalesce(inline_critical_oids, '{}'::oid[])))
  LOOP
    -- oid::regprocedure renders as `schema.name(argtype, argtype)` and is a
    -- valid target for ALTER FUNCTION regardless of caller search_path.
    EXECUTE pg_catalog.format(
      'ALTER FUNCTION %s SET search_path = pg_catalog, extensions, public',
      fn_oid::regprocedure
    );
  END LOOP;
END $$;
