-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/json/types.sql
-- REQUIRE: src/v3/json/functions.sql
-- REQUIRE: src/v3/sem/ope_cllw/types.sql

--! @file v3/json/operators.sql
--! @brief Operators on public.eql_v3_json_search and public.eql_v3_json_entry.

------------------------------------------------------------------------------
-- -> field accessor (returns jsonb_entry)
------------------------------------------------------------------------------

--! @brief -> operator with text selector.
--!
--! Returns the sv entry whose `s` equals @p selector, with root `i`/`v` merged
--! in. Inlinable: `WHERE col -> 'sel' = $1` reduces structurally to
--! `eql_v3.eq_term(col -> 'sel') = eql_v3.eq_term($1)` and matches a functional
--! index on `eql_v3.eq_term(col -> 'sel')`.
--!
--! @warning The selector operand MUST carry a known type — a text-typed
--!   parameter (`$1`, the Proxy interface) or an explicit cast (`col -> 'sel'::%text`).
--!   A bare untyped literal (`col -> 'sel'`) resolves to the NATIVE `jsonb -> %text`
--!   operator and silently returns native jsonb semantics (a root-key lookup,
--!   typically NULL), NOT this operator: PostgreSQL reduces the `public.eql_v3_json_search`
--!   domain to its base type `jsonb` when resolving an unknown-typed RHS, and the
--!   native base-type operator wins the exact-match tiebreak. This is intrinsic to
--!   the domain type-kind and applies to the native-jsonb blockers too. See
--!   the "Typed operands" caveat in docs/reference/json-support.md.
--!
--! @param e public.eql_v3_json_search Root encrypted payload.
--! @param selector text Selector hash.
--! @return public.eql_v3_json_entry Matching entry merged with root meta, or NULL.
CREATE FUNCTION eql_v3."->"(e public.eql_v3_json_search, selector text)
  RETURNS public.eql_v3_json_entry
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT (
    eql_v3.meta_data(e) ||
    jsonb_path_query_first(
      e,
      '$.sv[*] ? (@.s == $sel)'::jsonpath,
      jsonb_build_object('sel', selector)
    )
  )::public.eql_v3_json_entry
$$;

CREATE OPERATOR ->(
  FUNCTION=eql_v3."->",
  LEFTARG=public.eql_v3_json_search,
  RIGHTARG=text
);

--! @brief -> operator with integer array index (0-based, JSONB convention).
--! @param e public.eql_v3_json_search Encrypted sv-array payload.
--! @param selector integer Array index.
--! @return public.eql_v3_json_entry Matching entry merged with root meta, or NULL.
CREATE FUNCTION eql_v3."->"(e public.eql_v3_json_search, selector integer)
  RETURNS public.eql_v3_json_entry
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT CASE
    WHEN eql_v3_internal.is_ste_vec_array(e) THEN
      -- NOTE: `e::jsonb` makes the native-jsonb traversal explicit. `'sv'` is an
      -- unknown-typed literal, so `e -> 'sv'` already flattens `public.eql_v3_json_search` to
      -- its base type and binds native `jsonb -> text` (see the @warning above) —
      -- the custom `->(public.eql_v3_json_search, text)` operator does NOT capture a bare
      -- untyped literal. The cast documents that intent and guards the `-> selector`
      -- (integer) hop from ever resolving to the v3 `->(public.eql_v3_json_search, integer)`
      -- operator instead of native array access.
      (eql_v3.meta_data(e) || (e::jsonb -> 'sv' -> selector))::public.eql_v3_json_entry
    ELSE NULL
  END
$$;

CREATE OPERATOR ->(
  FUNCTION=eql_v3."->",
  LEFTARG=public.eql_v3_json_search,
  RIGHTARG=integer
);

------------------------------------------------------------------------------
-- ->> field accessor (alias of -> coerced to text)
------------------------------------------------------------------------------

--! @brief ->> operator with text selector. Inlinable alias of -> coerced to
--!        text.
--!
--! Intentional v2 parity: this serializes the entire matched jsonb_entry
--! object as JSON text. It does not decrypt or return scalar plaintext like
--! native `jsonb ->>`.
--! @param e public.eql_v3_json_search Encrypted payload.
--! @param selector text Field selector hash.
--! @return text The matching entry as text.
CREATE FUNCTION eql_v3."->>"(e public.eql_v3_json_search, selector text)
  RETURNS text
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3."->"(e, selector)::jsonb::text
$$;

CREATE OPERATOR ->> (
  FUNCTION=eql_v3."->>",
  LEFTARG=public.eql_v3_json_search,
  RIGHTARG=text
);

--! @brief ->> operator with integer array index. Inlinable alias of
--!        ->(json, integer) coerced to text.
--! @param e public.eql_v3_json_search Encrypted sv-array payload.
--! @param selector integer Array index.
--! @return text The matching entry as text.
CREATE FUNCTION eql_v3."->>"(e public.eql_v3_json_search, selector integer)
  RETURNS text
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3."->"(e, selector)::jsonb::text
$$;

CREATE OPERATOR ->> (
  FUNCTION=eql_v3."->>",
  LEFTARG=public.eql_v3_json_search,
  RIGHTARG=integer
);

------------------------------------------------------------------------------
-- @> containment
------------------------------------------------------------------------------

--! @brief @> contains operator (document, document).
--! @param a public.eql_v3_json_search Container.
--! @param b public.eql_v3_json_search Contained value.
--! @return boolean True if a contains b.
--! @see eql_v3.ste_vec_contains
CREATE FUNCTION eql_v3."@>"(a public.eql_v3_json_search, b public.eql_v3_json_search)
RETURNS boolean
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3.ste_vec_contains(a, b)
$$;

CREATE OPERATOR @>(
  FUNCTION=eql_v3."@>",
  LEFTARG=public.eql_v3_json_search,
  RIGHTARG=public.eql_v3_json_search
);

--! @brief @> contains operator with an query_json needle.
--!
--! Inlines to native `jsonb @>` over `eql_v3.to_ste_vec_query(a)::jsonb`, so a
--! functional GIN index on the same expression engages.
--!
--! @param a public.eql_v3_json_search Container.
--! @param b eql_v3.query_json Query payload.
--! @return boolean True if a contains b.
CREATE FUNCTION eql_v3."@>"(a public.eql_v3_json_search, b eql_v3.query_json)
RETURNS boolean
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3.to_ste_vec_query(a)::jsonb @> b::jsonb
$$;

CREATE OPERATOR @>(
  FUNCTION=eql_v3."@>",
  LEFTARG=public.eql_v3_json_search,
  RIGHTARG=eql_v3.query_json
);

--! @brief @> contains operator with a single jsonb_entry needle.
--!
--! Wraps the entry into a single-element sv array (stripping `c`) and reduces
--! to the same `to_ste_vec_query(a)::jsonb @> needle::jsonb` form.
--!
--! @param a public.eql_v3_json_search Container.
--! @param b public.eql_v3_json_entry Single entry.
--! @return boolean True if a contains an sv entry matching b.
CREATE FUNCTION eql_v3."@>"(a public.eql_v3_json_search, b public.eql_v3_json_entry)
RETURNS boolean
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3.to_ste_vec_query(a)::jsonb
       @> jsonb_build_object(
            'sv',
            jsonb_build_array(
              jsonb_strip_nulls(
                jsonb_build_object(
                  's',  b -> 's',
                  'hm', b -> 'hm',
                  'op', b -> 'op'
                )
              )
            )
          )
$$;

CREATE OPERATOR @>(
  FUNCTION=eql_v3."@>",
  LEFTARG=public.eql_v3_json_search,
  RIGHTARG=public.eql_v3_json_entry
);

------------------------------------------------------------------------------
-- <@ contained-by (reverse of @>)
------------------------------------------------------------------------------

--! @brief <@ contained-by operator (document, document).
--! @param a public.eql_v3_json_search Contained value.
--! @param b public.eql_v3_json_search Container.
--! @return boolean True if a is contained by b.
CREATE FUNCTION eql_v3."<@"(a public.eql_v3_json_search, b public.eql_v3_json_search)
RETURNS boolean
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3.ste_vec_contains(b, a)
$$;

CREATE OPERATOR <@(
  FUNCTION=eql_v3."<@",
  LEFTARG=public.eql_v3_json_search,
  RIGHTARG=public.eql_v3_json_search
);

--! @brief <@ contained-by operator with an query_json LHS.
--! @param a eql_v3.query_json Query payload.
--! @param b public.eql_v3_json_search Container.
--! @return boolean True if b contains a.
CREATE FUNCTION eql_v3."<@"(a eql_v3.query_json, b public.eql_v3_json_search)
RETURNS boolean
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3."@>"(b, a)
$$;

CREATE OPERATOR <@(
  FUNCTION=eql_v3."<@",
  LEFTARG=eql_v3.query_json,
  RIGHTARG=public.eql_v3_json_search
);

--! @brief <@ contained-by operator with a jsonb_entry LHS.
--! @param a public.eql_v3_json_entry Single entry.
--! @param b public.eql_v3_json_search Container.
--! @return boolean True if b contains a.
CREATE FUNCTION eql_v3."<@"(a public.eql_v3_json_entry, b public.eql_v3_json_search)
RETURNS boolean
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3."@>"(b, a)
$$;

CREATE OPERATOR <@(
  FUNCTION=eql_v3."<@",
  LEFTARG=public.eql_v3_json_entry,
  RIGHTARG=public.eql_v3_json_search
);

------------------------------------------------------------------------------
-- jsonb_entry comparisons
------------------------------------------------------------------------------

--! @brief Equality on jsonb_entry via eq_term (hm-or-op byte equality).
--! @param a public.eql_v3_json_entry Left operand
--! @param b public.eql_v3_json_entry Right operand
--! @return boolean True if the entries are equal
CREATE FUNCTION eql_v3.eq(a public.eql_v3_json_entry, b public.eql_v3_json_entry)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b)
$$;

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG  = public.eql_v3_json_entry,
  RIGHTARG = public.eql_v3_json_entry,
  COMMUTATOR = =,
  NEGATOR  = <>,
  RESTRICT = eqsel,
  JOIN     = eqjoinsel
);

--! @brief Inequality on jsonb_entry via eq_term.
--! @param a public.eql_v3_json_entry Left operand
--! @param b public.eql_v3_json_entry Right operand
--! @return boolean True if the entries are not equal
CREATE FUNCTION eql_v3.neq(a public.eql_v3_json_entry, b public.eql_v3_json_entry)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b)
$$;

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG  = public.eql_v3_json_entry,
  RIGHTARG = public.eql_v3_json_entry,
  COMMUTATOR = <>,
  NEGATOR  = =,
  RESTRICT = neqsel,
  JOIN     = neqjoinsel
);

--! @brief Less-than on jsonb_entry via the CLLW OPE term (native bytea order).
--! @param a public.eql_v3_json_entry Left operand
--! @param b public.eql_v3_json_entry Right operand
--! @return boolean True if a is less than b
CREATE FUNCTION eql_v3.lt(a public.eql_v3_json_entry, b public.eql_v3_json_entry)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b)
$$;

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG  = public.eql_v3_json_entry,
  RIGHTARG = public.eql_v3_json_entry,
  COMMUTATOR = >,
  NEGATOR  = >=,
  RESTRICT = scalarltsel,
  JOIN     = scalarltjoinsel
);

--! @brief Less-than-or-equal on jsonb_entry via the CLLW OPE term.
--! @param a public.eql_v3_json_entry Left operand
--! @param b public.eql_v3_json_entry Right operand
--! @return boolean True if a is less than or equal to b
CREATE FUNCTION eql_v3.lte(a public.eql_v3_json_entry, b public.eql_v3_json_entry)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b)
$$;

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG  = public.eql_v3_json_entry,
  RIGHTARG = public.eql_v3_json_entry,
  COMMUTATOR = >=,
  NEGATOR  = >,
  RESTRICT = scalarlesel,
  JOIN     = scalarlejoinsel
);

--! @brief Greater-than on jsonb_entry via the CLLW OPE term.
--! @param a public.eql_v3_json_entry Left operand
--! @param b public.eql_v3_json_entry Right operand
--! @return boolean True if a is greater than b
CREATE FUNCTION eql_v3.gt(a public.eql_v3_json_entry, b public.eql_v3_json_entry)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b)
$$;

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG  = public.eql_v3_json_entry,
  RIGHTARG = public.eql_v3_json_entry,
  COMMUTATOR = <,
  NEGATOR  = <=,
  RESTRICT = scalargtsel,
  JOIN     = scalargtjoinsel
);

--! @brief Greater-than-or-equal on jsonb_entry via the CLLW OPE term.
--! @param a public.eql_v3_json_entry Left operand
--! @param b public.eql_v3_json_entry Right operand
--! @return boolean True if a is greater than or equal to b
CREATE FUNCTION eql_v3.gte(a public.eql_v3_json_entry, b public.eql_v3_json_entry)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b)
$$;

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG  = public.eql_v3_json_entry,
  RIGHTARG = public.eql_v3_json_entry,
  COMMUTATOR = <=,
  NEGATOR  = <,
  RESTRICT = scalargesel,
  JOIN     = scalargejoinsel
);
