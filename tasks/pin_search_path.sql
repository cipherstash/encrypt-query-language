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
BEGIN
  -- Resolve type oids without depending on caller search_path. The encrypted
  -- composite type is created in `public`; jsonb is in `pg_catalog`.
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
      -- Two-arg operator overloads on eql_v2_encrypted / jsonb. The
      -- `pronargs = 2` filter is scoped to these arms because the helpers
      -- below include single-argument extractors (encrypted_int4_ope_key,
      -- encrypted_jsonb_array) that must also remain inlineable.
      ( p.pronargs = 2 AND (
        -- Same-type (encrypted, encrypted) operators that must inline.
        -- `like`/`ilike` are the SQL helpers that `~~`/`~~*` delegate to;
        -- both layers must inline to reach `bloom_filter(a) @> bloom_filter(b)`.
        (p.proname IN ('=', '<>', '~~', '~~*', '@>', '<@',
                       'jsonb_contains', 'jsonb_contained_by',
                       'like', 'ilike')
          AND p.proargtypes[0] = enc_oid AND p.proargtypes[1] = enc_oid)
        -- Cross-type (encrypted, jsonb).
        OR (p.proname IN ('=', '<>', '~~', '~~*',
                          'jsonb_contains', 'jsonb_contained_by')
          AND p.proargtypes[0] = enc_oid AND p.proargtypes[1] = jsonb_oid)
        -- Cross-type (jsonb, encrypted).
        OR (p.proname IN ('=', '<>', '~~', '~~*',
                          'jsonb_contains', 'jsonb_contained_by')
          AND p.proargtypes[0] = jsonb_oid AND p.proargtypes[1] = enc_oid)
      ) )
      -- Domain-type prototype helpers and operator functions
      -- (encrypted_text, encrypted_int4, encrypted_jsonb). These are
      -- LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE and must inline so
      -- that bare operator predicates engage functional indexes on
      -- eql_v2.hmac_256(col::jsonb), eql_v2.bloom_filter(col::jsonb),
      -- eql_v2.encrypted_int4_ope_key(col), and
      -- eql_v2.encrypted_jsonb_array(col). Name-only match (any arity)
      -- because the same proname covers same-domain and cross-type
      -- (domain, jsonb) / (jsonb, domain) overloads, plus the single-arg
      -- extractors used in the functional indexes themselves.
      OR p.proname IN (
        'encrypted_text_eq',
        'encrypted_text_neq',
        'encrypted_text_like',
        'encrypted_int4_eq',
        'encrypted_int4_neq',
        'encrypted_int4_lt',
        'encrypted_int4_lte',
        'encrypted_int4_gt',
        'encrypted_int4_gte',
        'encrypted_int4_ope_key',
        'encrypted_jsonb_eq',
        'encrypted_jsonb_neq',
        'encrypted_jsonb_contains',
        'encrypted_jsonb_contained_by',
        'encrypted_jsonb_arrow',
        'encrypted_jsonb_arrow_text',
        'encrypted_jsonb_arrow_int',
        'encrypted_jsonb_arrow_text_int',
        'encrypted_jsonb_array'
      )
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
