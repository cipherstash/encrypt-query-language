--! @file pin_search_path.sql
--! @brief Post-install: pin search_path on every eql_v2.* and eql_v3.* function
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
  WHERE (
    n.nspname = 'eql_v2'
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
      -- Inner ORE-CLLW comparison helpers backing the `<`, `<=`, `=`,
      -- `>=`, `>`, `<>` operators on `eql_v2.ore_cllw` (the composite
      -- type, registered via `eql_v2.ore_cllw_ops` opclass — #221). Same
      -- precedent as the `ore_block_u64_8_256_*` helpers above: PG only
      -- carries the inlined operator wrapper through to functional-index
      -- match if the inner backing function is also inlinable. Pinning
      -- these would break the index match for `ORDER BY eql_v2.ore_cllw
      -- (value -> '<selector>'::text)` and the matching `WHERE` form.
      OR (p.pronargs = 2
        AND p.proname IN ('ore_cllw_eq', 'ore_cllw_neq',
                          'ore_cllw_lt', 'ore_cllw_lte',
                          'ore_cllw_gt', 'ore_cllw_gte'))
      -- `->` selector lookup: inlinable SQL post the type flip
      -- (returns `eql_v2.ste_vec_entry`). Must stay unpinned so the
      -- planner can fold `col -> '<selector>'` into the calling query
      -- — without this, the chained recipe
      -- `WHERE col -> 'sel' = $1::ste_vec_entry` would not match a
      -- functional hash index on `eql_v2.eq_term(col -> 'sel')`.
      OR (p.proname = '->'
        AND p.pronargs = 2
        AND p.proargtypes[0] = enc_oid
        AND (p.proargtypes[1] = text_oid
             OR p.proargtypes[1] = enc_oid
             OR p.proargtypes[1] = (SELECT t.oid FROM pg_catalog.pg_type t
                                     JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
                                     WHERE n.nspname = 'pg_catalog' AND t.typname = 'int4')))
      -- Equality-term and order-term extractors — `eq_term` / `ord_term`
      -- on a ste_vec entry and on the encrypted-domain family. Must
      -- inline so `eql_v2.eq_term(col)` / `eql_v2.ord_term(col)` fold
      -- into the calling query and match a functional index built on the
      -- same expression. Name-only match (any arity-1 overload). The
      -- encrypted-domain overloads are also covered by the identity
      -- predicate's structural skip in the pin loop; these name-only
      -- clauses are kept as belt-and-suspenders.
      OR (p.pronargs = 1 AND p.proname = 'eq_term')
      OR (p.pronargs = 1 AND p.proname = 'ord_term')
      -- Type-safe `@>` / `<@` overloads with typed needles
      -- (`stevec_query`, `ste_vec_entry`). Inline to the existing
      -- `ste_vec_contains` machinery — must stay unpinned to engage
      -- the GIN index on `eql_v2.ste_vec(col)` structurally for
      -- bare-form containment.
      OR (p.pronargs = 2
        AND p.proname IN ('@>', '<@')
        AND p.proargtypes[0] = enc_oid
        AND (p.proargtypes[1] = entry_oid
             OR p.proargtypes[1] = (SELECT t.oid FROM pg_catalog.pg_type t
                                     JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
                                     WHERE n.nspname = 'eql_v2' AND t.typname = 'stevec_query')))
      OR (p.pronargs = 2
        AND p.proname IN ('@>', '<@')
        AND p.proargtypes[1] = enc_oid
        AND (p.proargtypes[0] = entry_oid
             OR p.proargtypes[0] = (SELECT t.oid FROM pg_catalog.pg_type t
                                     JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
                                     WHERE n.nspname = 'eql_v2' AND t.typname = 'stevec_query')))
    )
  )
  OR (
    -- eql_v3 SEM index-term functions (self-contained fork). These mirror the
    -- eql_v2 ore_block / hmac_256 inline-critical clauses above: the
    -- comparison-wrapper inlining for the eql_v3 *_ord domains and eq_term only
    -- reaches functional-index matching if these inner functions stay inlinable
    -- (no SET, IMMUTABLE). The generated extractors/wrappers themselves are
    -- spared by the jsonb-DOMAIN structural skip below; these SEM functions take
    -- a composite (ore_block) or raw jsonb (hmac_256, bloom_filter) arg, so they
    -- need an explicit entry here.
    n.nspname = 'eql_v3'
    AND (
      (p.pronargs = 2
        AND p.proname IN ('ore_block_256_eq', 'ore_block_256_neq',
                          'ore_block_256_lt', 'ore_block_256_lte',
                          'ore_block_256_gt', 'ore_block_256_gte'))
      -- Inner ORE-CLLW comparison helpers backing the `<`, `<=`, `=`, `>=`,
      -- `>`, `<>` operators on the eql_v3.ore_cllw composite type (registered
      -- via the DEFAULT eql_v3.ore_cllw_ops btree opclass). Same precedent as
      -- the ore_block_256_* helpers above and the eql_v2.ore_cllw_*
      -- helpers: PG only carries the inlined operator wrapper through to
      -- functional-index match if the inner backing function is also
      -- inlinable. They take the composite arg (not a jsonb-backed domain),
      -- so the structural skip below does not spare them — they need an
      -- explicit entry here. The plpgsql FUNCTION 1 comparator
      -- (compare_ore_cllw_term) stays pinned by design.
      OR (p.pronargs = 2
        AND p.proname IN ('ore_cllw_eq', 'ore_cllw_neq',
                          'ore_cllw_lt', 'ore_cllw_lte',
                          'ore_cllw_gt', 'ore_cllw_gte'))
      -- Raw-jsonb CLLW extractor / presence helper. Inlinable SQL — pinning
      -- would silently undo the fold of `eql_v3.ore_cllw(col -> 'sel')` into
      -- the calling query and break functional-index match. (These also carry
      -- the `eql-inline-critical` COMMENT marker honoured by the fallback
      -- below; listed here too so the intent is explicit alongside the
      -- operators they support. Single (jsonb) overload in the v3 fork.)
      OR (p.pronargs = 1
        AND p.proname IN ('ore_cllw', 'has_ore_cllw')
        AND p.proargtypes[0] = jsonb_oid)
      OR (p.pronargs = 1
        AND p.proname = 'hmac_256'
        AND p.proargtypes[0] = jsonb_oid)
      OR (p.pronargs = 1
        AND p.proname = 'bloom_filter'
        AND p.proargtypes[0] = jsonb_oid)
    )
  );

  FOR fn_oid IN
    SELECT p.oid
    FROM pg_catalog.pg_proc p
    JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname IN ('eql_v2', 'eql_v3')
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
      -- Encrypted-domain family — structural skip (hybrid primary mechanism).
      -- A new encrypted-domain type needs NO edit here: its inline-critical
      -- extractors and comparison wrappers are recognised by the identity
      -- predicate — LANGUAGE sql, IMMUTABLE, and taking at least one argument
      -- typed as a jsonb-backed DOMAIN of the encrypted-domain families. The
      -- families live in the `eql_v3` schema (e.g. `eql_v3.int4_eq`); the
      -- legacy `public.eql_v2_*` form is kept for any pre-v3 domain. The
      -- predicate is proconfig-independent: the outer loop has already
      -- excluded any function with a pinned `search_path`, so the only
      -- functions reaching here are unpinned. This catches no core function:
      -- `eql_v2_encrypted` is a composite type (not a domain), `ste_vec_entry`
      -- is a domain in `eql_v2` (not `eql_v3`/`public`), and `hmac_256` is a
      -- domain over `text` (not `jsonb`). The eql_v3 blockers are plpgsql, so
      -- the LANGUAGE-sql guard leaves them to be pinned as intended.
      AND NOT (
        p.prolang = (SELECT l.oid FROM pg_catalog.pg_language l
                     WHERE l.lanname = 'sql')
        AND p.provolatile = 'i'
        AND EXISTS (
          SELECT 1
          FROM pg_catalog.unnest(p.proargtypes::oid[]) AS arg(typ)
          JOIN pg_catalog.pg_type dt ON dt.oid = arg.typ
          JOIN pg_catalog.pg_namespace dn ON dn.oid = dt.typnamespace
          WHERE dt.typtype = 'd'
            AND dt.typbasetype = jsonb_oid
            AND (
              dn.nspname = 'eql_v3'
              OR (dn.nspname = 'public' AND dt.typname LIKE 'eql_v2\_%')
            )
        )
      )
      -- Encrypted-domain family — comment-marker fallback. Covers a
      -- hand-written extension function that is inline-critical but takes no
      -- domain argument (invisible to the identity predicate). The generator
      -- does NOT emit this marker — every function it produces takes a domain
      -- argument and is covered by the structural skip above. The marker is a
      -- manual opt-in for hand-written extension functions only.
      AND NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_description d
        WHERE d.objoid = p.oid
          AND d.classoid = 'pg_catalog.pg_proc'::regclass
          AND d.description LIKE 'eql-inline-critical%'
      )
  LOOP
    -- oid::regprocedure renders as `schema.name(argtype, argtype)` and is a
    -- valid target for ALTER FUNCTION regardless of caller search_path.
    EXECUTE pg_catalog.format(
      'ALTER FUNCTION %s SET search_path = pg_catalog, extensions, public',
      fn_oid::regprocedure
    );
  END LOOP;
END $$;
