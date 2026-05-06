-- REQUIRE: src/schema.sql

--! @brief EQL lint: detect non-inlinable operator implementation functions
--!
--! Returns one row per violation found in the installed EQL surface. The
--! Postgres planner can only inline a function during index matching when:
--!
--!   * `LANGUAGE sql` (plpgsql / C / etc. cannot be inlined)
--!   * `IMMUTABLE` or `STABLE` volatility (VOLATILE cannot be inlined into
--!     index expressions)
--!   * No `SET` clauses (e.g. `SET search_path = ...`)
--!   * Not `SECURITY DEFINER`
--!   * Single-statement SELECT body
--!
--! Operators on encrypted types (`eql_v2_encrypted`, `eql_v2.bloom_filter`,
--! `eql_v2.ore_*`, etc.) whose implementation functions fail any of these
--! rules silently fall back to seq scan when the documented functional
--! indexes (`eql_v2.hmac_256(col)`, `eql_v2.bloom_filter(col)`,
--! `eql_v2.ste_vec(col)`) are in place. This lint surfaces every such case.
--!
--! Severity:
--!   `error`   — fixable, blocks index matching, ship-blocking.
--!   `warning` — likely-fixable, may not block matching but signals intent.
--!   `info`    — observational; useful for review, not a defect on its own.
--!
--! Categories:
--!   `inlinability_language`   — implementation function isn't `LANGUAGE sql`.
--!   `inlinability_volatility` — implementation function is VOLATILE.
--!   `inlinability_set_clause` — implementation function has a `SET` clause.
--!   `inlinability_secdef`     — implementation function is `SECURITY DEFINER`.
--!   `inlinability_transitive` — implementation function is itself inlinable
--!                                but its body invokes a non-inlinable function
--!                                (depth 1; the planner can't peek through
--!                                that boundary).
--!
--! @example
--! ```
--! SELECT severity, category, object_name, message
--!   FROM eql_v2.lints()
--!  WHERE severity = 'error'
--!  ORDER BY category, object_name;
--! ```
--!
--! @return SETOF record (severity text, category text, object_name text, message text)
CREATE OR REPLACE FUNCTION eql_v2.lints()
RETURNS TABLE (
  severity text,
  category text,
  object_name text,
  message text
)
LANGUAGE sql STABLE
AS $$
  WITH
  -- All operators where at least one operand involves an EQL type. Limits
  -- the scope of the lint to the operator surface customers actually hit
  -- via SQL (`col = val`, `col LIKE '...'`, `col @> '...'` and friends).
  eql_operators AS (
    SELECT
      op.oid              AS oprid,
      op.oprname          AS opname,
      op.oprcode          AS implfunc,
      op.oprleft::regtype AS lhs,
      op.oprright::regtype AS rhs,
      op.oprcode::regprocedure AS impl_signature
    FROM pg_operator op
    WHERE EXISTS (
        SELECT 1 FROM pg_type t
         WHERE t.oid IN (op.oprleft, op.oprright)
           AND (t.typname LIKE 'eql_v2%'
             OR t.typnamespace = 'eql_v2'::regnamespace)
      )
  ),

  -- Cross-join with each operator's implementation function metadata.
  -- One row per operator; columns describe the inlinability of the impl.
  op_impl AS (
    SELECT
      eo.opname,
      eo.lhs,
      eo.rhs,
      eo.impl_signature::text                       AS impl_signature,
      lang_l.lanname                                AS lang,
      p.provolatile                                 AS volatility,
      p.proconfig                                   AS config,
      p.prosecdef                                   AS secdef,
      p.prosrc                                      AS body
    FROM eql_operators eo
    JOIN pg_proc p ON p.oid = eo.implfunc
    JOIN pg_language lang_l ON lang_l.oid = p.prolang
  )

  -- ┌─────────────────────────────────────────────────────────────────┐
  -- │ Direct inlinability checks: each row examines one operator's    │
  -- │ implementation function and emits a violation if any rule is    │
  -- │ broken. Multiple violations on the same function become         │
  -- │ multiple rows (developers see every reason it doesn't inline).  │
  -- └─────────────────────────────────────────────────────────────────┘

  SELECT
    'error'                                                             AS severity,
    'inlinability_language'                                             AS category,
    format('operator %s(%s, %s) -> %s',
           opname, lhs, rhs, impl_signature)                            AS object_name,
    format(
      'Operator implementation function is `LANGUAGE %s`; only `LANGUAGE sql` functions can be inlined by the planner. Bare `col %s val` queries fall back to seq scan even when a matching functional index exists.',
      lang, opname)                                                     AS message
  FROM op_impl
  WHERE lang <> 'sql'

  UNION ALL

  SELECT
    'error',
    'inlinability_volatility',
    format('operator %s(%s, %s) -> %s', opname, lhs, rhs, impl_signature),
    format(
      'Operator implementation function is `VOLATILE`. The Postgres planner refuses to inline volatile functions into index expressions, so functional indexes never engage. Mark the function `IMMUTABLE` (or `STABLE` if it depends on session state).',
      opname)
  FROM op_impl
  WHERE volatility = 'v'

  UNION ALL

  SELECT
    'error',
    'inlinability_set_clause',
    format('operator %s(%s, %s) -> %s', opname, lhs, rhs, impl_signature),
    format(
      'Operator implementation function has a `SET` clause (e.g. `SET search_path = ...`). Per Postgres function-inlining rules, any `SET` clause blocks inlining. Use schema-qualified identifiers in the body and remove the `SET` clause to allow the planner to inline.')
  FROM op_impl
  WHERE config IS NOT NULL

  UNION ALL

  SELECT
    'error',
    'inlinability_secdef',
    format('operator %s(%s, %s) -> %s', opname, lhs, rhs, impl_signature),
    'Operator implementation function is `SECURITY DEFINER`. Such functions cannot be inlined; remove `SECURITY DEFINER` or use a non-inlinable wrapper layer.'
  FROM op_impl
  WHERE secdef

  -- ┌─────────────────────────────────────────────────────────────────┐
  -- │ Transitive inlinability: an operator implementation function    │
  -- │ that's itself inlinable can still fail to inline if its body    │
  -- │ calls a non-inlinable function. Walk one level via pg_depend.   │
  -- │                                                                 │
  -- │ Postgres records function-to-function dependencies in           │
  -- │ pg_depend with deptype 'n' (normal) when one function references│
  -- │ another in its body — but only at CREATE time and only for      │
  -- │ direct calls. This is good enough for v1; deeper transitive     │
  -- │ analysis is a follow-up.                                        │
  -- └─────────────────────────────────────────────────────────────────┘

  UNION ALL

  SELECT
    'error',
    'inlinability_transitive',
    format('operator %s(%s, %s) -> %s', oi.opname, oi.lhs, oi.rhs,
           oi.impl_signature),
    format(
      'Operator implementation function is inlinable but invokes non-inlinable function `%s` (lang=%s, volatility=%s%s). The chain blocks at depth 1: the planner inlines the outer call but cannot reduce the inner call into an index expression.',
      called.proname,
      called_lang.lanname,
      CASE called.provolatile
        WHEN 'i' THEN 'IMMUTABLE'
        WHEN 's' THEN 'STABLE'
        WHEN 'v' THEN 'VOLATILE'
      END,
      CASE WHEN called.proconfig IS NOT NULL
           THEN ', has SET clause'
           ELSE '' END)
  FROM op_impl oi
  -- Only worth the transitive check if the outer function is otherwise
  -- inlinable — otherwise the direct lints above already report it.
  JOIN pg_proc outer_p ON outer_p.oid = oi.impl_signature::regprocedure
  JOIN pg_depend d
    ON d.classid = 'pg_proc'::regclass
   AND d.objid = outer_p.oid
   AND d.refclassid = 'pg_proc'::regclass
   AND d.deptype = 'n'
  JOIN pg_proc called ON called.oid = d.refobjid
  JOIN pg_language called_lang ON called_lang.oid = called.prolang
  WHERE oi.lang = 'sql'
    AND oi.volatility IN ('i', 's')
    AND oi.config IS NULL
    AND NOT oi.secdef
    AND called.oid <> outer_p.oid
    AND (
         called_lang.lanname <> 'sql'
      OR called.provolatile = 'v'
      OR called.proconfig IS NOT NULL
      OR called.prosecdef
    )

  ORDER BY 1, 2, 3;
$$;

COMMENT ON FUNCTION eql_v2.lints() IS
  'EQL lint: returns one row per non-inlinable operator implementation. '
  'Run `SELECT * FROM eql_v2.lints() WHERE severity = ''error''` for a '
  'CI-gateable check that all operator implementations on EQL types are '
  'eligible for planner inlining.';
