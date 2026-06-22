-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/jsonb/types.sql
-- REQUIRE: src/v3/jsonb/functions.sql
-- REQUIRE: src/v3/sem/ore_cllw/operators.sql

--! @file v3/jsonb/operators.sql
--! @brief Operators on eql_v3.json and eql_v3.ste_vec_entry.

------------------------------------------------------------------------------
-- -> field accessor (returns ste_vec_entry)
------------------------------------------------------------------------------

--! @brief -> operator with text selector.
--!
--! Returns the sv entry whose `s` equals @p selector, with root `i`/`v` merged
--! in. Inlinable: `WHERE col -> 'sel' = $1` reduces structurally to
--! `eql_v3.eq_term(col -> 'sel') = eql_v3.eq_term($1)` and matches a functional
--! index on `eql_v3.eq_term(col -> 'sel')`.
--!
--! @warning The selector operand MUST carry a known type — a text-typed
--!   parameter (`$1`, the Proxy interface) or an explicit cast (`col -> 'sel'::text`).
--!   A bare untyped literal (`col -> 'sel'`) resolves to the NATIVE `jsonb -> text`
--!   operator and silently returns native jsonb semantics (a root-key lookup,
--!   typically NULL), NOT this operator: PostgreSQL reduces the `eql_v3.json`
--!   domain to its base type `jsonb` when resolving an unknown-typed RHS, and the
--!   native base-type operator wins the exact-match tiebreak. This is intrinsic to
--!   the domain type-kind and applies to the native-jsonb blockers too. See
--!   the "Typed operands" caveat in docs/reference/json-support.md.
--!
--! @param e eql_v3.json Root encrypted payload.
--! @param selector text Selector hash.
--! @return eql_v3.ste_vec_entry Matching entry merged with root meta, or NULL.
CREATE FUNCTION eql_v3."->"(e eql_v3.json, selector text)
  RETURNS eql_v3.ste_vec_entry
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT (
    eql_v3.meta_data(e) ||
    jsonb_path_query_first(
      e,
      '$.sv[*] ? (@.s == $sel)'::jsonpath,
      jsonb_build_object('sel', selector)
    )
  )::eql_v3.ste_vec_entry
$$;

CREATE OPERATOR ->(
  FUNCTION=eql_v3."->",
  LEFTARG=eql_v3.json,
  RIGHTARG=text
);

--! @brief -> operator with integer array index (0-based, JSONB convention).
--! @param e eql_v3.json Encrypted sv-array payload.
--! @param selector integer Array index.
--! @return eql_v3.ste_vec_entry Matching entry merged with root meta, or NULL.
CREATE FUNCTION eql_v3."->"(e eql_v3.json, selector integer)
  RETURNS eql_v3.ste_vec_entry
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT CASE
    WHEN eql_v3.is_ste_vec_array(e) THEN
      -- NOTE: `e::jsonb` is REQUIRED. `e` is eql_v3.json and the custom
      -- `->(eql_v3.json, text)` operator is already created earlier in
      -- this file, so a bare `e -> 'sv'` would resolve to that selector-lookup
      -- operator (searching for an sv entry with selector 'sv') instead of
      -- native jsonb array access. Casting to jsonb forces native `->`.
      (eql_v3.meta_data(e) || (e::jsonb -> 'sv' -> selector))::eql_v3.ste_vec_entry
    ELSE NULL
  END
$$;

CREATE OPERATOR ->(
  FUNCTION=eql_v3."->",
  LEFTARG=eql_v3.json,
  RIGHTARG=integer
);

------------------------------------------------------------------------------
-- ->> field accessor (alias of -> coerced to text)
------------------------------------------------------------------------------

--! @brief ->> operator with text selector. Inlinable alias of -> coerced to
--!        text.
--!
--! Intentional v2 parity: this serializes the entire matched ste_vec_entry
--! object as JSON text. It does not decrypt or return scalar plaintext like
--! native `jsonb ->>`.
--! @param e eql_v3.json Encrypted payload.
--! @param selector text Field selector hash.
--! @return text The matching entry as text.
CREATE FUNCTION eql_v3."->>"(e eql_v3.json, selector text)
  RETURNS text
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3."->"(e, selector)::jsonb::text
$$;

CREATE OPERATOR ->> (
  FUNCTION=eql_v3."->>",
  LEFTARG=eql_v3.json,
  RIGHTARG=text
);

--! @brief ->> operator with integer array index. Inlinable alias of
--!        ->(json, integer) coerced to text.
--! @param e eql_v3.json Encrypted sv-array payload.
--! @param selector integer Array index.
--! @return text The matching entry as text.
CREATE FUNCTION eql_v3."->>"(e eql_v3.json, selector integer)
  RETURNS text
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3."->"(e, selector)::jsonb::text
$$;

CREATE OPERATOR ->> (
  FUNCTION=eql_v3."->>",
  LEFTARG=eql_v3.json,
  RIGHTARG=integer
);

------------------------------------------------------------------------------
-- @> containment
------------------------------------------------------------------------------

--! @brief @> contains operator (document, document).
--! @param a eql_v3.json Container.
--! @param b eql_v3.json Contained value.
--! @return boolean True if a contains b.
--! @see eql_v3.ste_vec_contains
CREATE FUNCTION eql_v3."@>"(a eql_v3.json, b eql_v3.json)
RETURNS boolean
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3.ste_vec_contains(a, b)
$$;

CREATE OPERATOR @>(
  FUNCTION=eql_v3."@>",
  LEFTARG=eql_v3.json,
  RIGHTARG=eql_v3.json
);

--! @brief @> contains operator with an ste_vec_query needle.
--!
--! Inlines to native `jsonb @>` over `eql_v3.to_ste_vec_query(a)::jsonb`, so a
--! functional GIN index on the same expression engages.
--!
--! @param a eql_v3.json Container.
--! @param b eql_v3.ste_vec_query Query payload.
--! @return boolean True if a contains b.
CREATE FUNCTION eql_v3."@>"(a eql_v3.json, b eql_v3.ste_vec_query)
RETURNS boolean
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3.to_ste_vec_query(a)::jsonb @> b::jsonb
$$;

CREATE OPERATOR @>(
  FUNCTION=eql_v3."@>",
  LEFTARG=eql_v3.json,
  RIGHTARG=eql_v3.ste_vec_query
);

--! @brief @> contains operator with a single ste_vec_entry needle.
--!
--! Wraps the entry into a single-element sv array (stripping `c`) and reduces
--! to the same `to_ste_vec_query(a)::jsonb @> needle::jsonb` form.
--!
--! @param a eql_v3.json Container.
--! @param b eql_v3.ste_vec_entry Single entry.
--! @return boolean True if a contains an sv entry matching b.
CREATE FUNCTION eql_v3."@>"(a eql_v3.json, b eql_v3.ste_vec_entry)
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
                  'oc', b -> 'oc'
                )
              )
            )
          )
$$;

CREATE OPERATOR @>(
  FUNCTION=eql_v3."@>",
  LEFTARG=eql_v3.json,
  RIGHTARG=eql_v3.ste_vec_entry
);

------------------------------------------------------------------------------
-- <@ contained-by (reverse of @>)
------------------------------------------------------------------------------

--! @brief <@ contained-by operator (document, document).
--! @param a eql_v3.json Contained value.
--! @param b eql_v3.json Container.
--! @return boolean True if a is contained by b.
CREATE FUNCTION eql_v3."<@"(a eql_v3.json, b eql_v3.json)
RETURNS boolean
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3.ste_vec_contains(b, a)
$$;

CREATE OPERATOR <@(
  FUNCTION=eql_v3."<@",
  LEFTARG=eql_v3.json,
  RIGHTARG=eql_v3.json
);

--! @brief <@ contained-by operator with an ste_vec_query LHS.
--! @param a eql_v3.ste_vec_query Query payload.
--! @param b eql_v3.json Container.
--! @return boolean True if b contains a.
CREATE FUNCTION eql_v3."<@"(a eql_v3.ste_vec_query, b eql_v3.json)
RETURNS boolean
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3."@>"(b, a)
$$;

CREATE OPERATOR <@(
  FUNCTION=eql_v3."<@",
  LEFTARG=eql_v3.ste_vec_query,
  RIGHTARG=eql_v3.json
);

--! @brief <@ contained-by operator with a ste_vec_entry LHS.
--! @param a eql_v3.ste_vec_entry Single entry.
--! @param b eql_v3.json Container.
--! @return boolean True if b contains a.
CREATE FUNCTION eql_v3."<@"(a eql_v3.ste_vec_entry, b eql_v3.json)
RETURNS boolean
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3."@>"(b, a)
$$;

CREATE OPERATOR <@(
  FUNCTION=eql_v3."<@",
  LEFTARG=eql_v3.ste_vec_entry,
  RIGHTARG=eql_v3.json
);

------------------------------------------------------------------------------
-- ste_vec_entry comparisons
------------------------------------------------------------------------------

--! @brief Equality on ste_vec_entry via eq_term (hm-or-oc byte equality).
--! @internal
--! @param a eql_v3.ste_vec_entry Left operand
--! @param b eql_v3.ste_vec_entry Right operand
--! @return boolean True if the entries are equal
CREATE FUNCTION eql_v3.eq(a eql_v3.ste_vec_entry, b eql_v3.ste_vec_entry)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b)
$$;

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG  = eql_v3.ste_vec_entry,
  RIGHTARG = eql_v3.ste_vec_entry,
  COMMUTATOR = =,
  NEGATOR  = <>,
  RESTRICT = eqsel,
  JOIN     = eqjoinsel
);

--! @brief Inequality on ste_vec_entry via eq_term.
--! @internal
--! @param a eql_v3.ste_vec_entry Left operand
--! @param b eql_v3.ste_vec_entry Right operand
--! @return boolean True if the entries are not equal
CREATE FUNCTION eql_v3.neq(a eql_v3.ste_vec_entry, b eql_v3.ste_vec_entry)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b)
$$;

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG  = eql_v3.ste_vec_entry,
  RIGHTARG = eql_v3.ste_vec_entry,
  COMMUTATOR = <>,
  NEGATOR  = =,
  RESTRICT = neqsel,
  JOIN     = neqjoinsel
);

--! @brief Less-than on ste_vec_entry via ore_cllw.
--! @internal
--! @param a eql_v3.ste_vec_entry Left operand
--! @param b eql_v3.ste_vec_entry Right operand
--! @return boolean True if a is less than b
CREATE FUNCTION eql_v3.lt(a eql_v3.ste_vec_entry, b eql_v3.ste_vec_entry)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3.ore_cllw(a) < eql_v3.ore_cllw(b)
$$;

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG  = eql_v3.ste_vec_entry,
  RIGHTARG = eql_v3.ste_vec_entry,
  COMMUTATOR = >,
  NEGATOR  = >=,
  RESTRICT = scalarltsel,
  JOIN     = scalarltjoinsel
);

--! @brief Less-than-or-equal on ste_vec_entry via ore_cllw.
--! @internal
--! @param a eql_v3.ste_vec_entry Left operand
--! @param b eql_v3.ste_vec_entry Right operand
--! @return boolean True if a is less than or equal to b
CREATE FUNCTION eql_v3.lte(a eql_v3.ste_vec_entry, b eql_v3.ste_vec_entry)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3.ore_cllw(a) <= eql_v3.ore_cllw(b)
$$;

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG  = eql_v3.ste_vec_entry,
  RIGHTARG = eql_v3.ste_vec_entry,
  COMMUTATOR = >=,
  NEGATOR  = >,
  RESTRICT = scalarlesel,
  JOIN     = scalarlejoinsel
);

--! @brief Greater-than on ste_vec_entry via ore_cllw.
--! @internal
--! @param a eql_v3.ste_vec_entry Left operand
--! @param b eql_v3.ste_vec_entry Right operand
--! @return boolean True if a is greater than b
CREATE FUNCTION eql_v3.gt(a eql_v3.ste_vec_entry, b eql_v3.ste_vec_entry)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3.ore_cllw(a) > eql_v3.ore_cllw(b)
$$;

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG  = eql_v3.ste_vec_entry,
  RIGHTARG = eql_v3.ste_vec_entry,
  COMMUTATOR = <,
  NEGATOR  = <=,
  RESTRICT = scalargtsel,
  JOIN     = scalargtjoinsel
);

--! @brief Greater-than-or-equal on ste_vec_entry via ore_cllw.
--! @internal
--! @param a eql_v3.ste_vec_entry Left operand
--! @param b eql_v3.ste_vec_entry Right operand
--! @return boolean True if a is greater than or equal to b
CREATE FUNCTION eql_v3.gte(a eql_v3.ste_vec_entry, b eql_v3.ste_vec_entry)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3.ore_cllw(a) >= eql_v3.ore_cllw(b)
$$;

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG  = eql_v3.ste_vec_entry,
  RIGHTARG = eql_v3.ste_vec_entry,
  COMMUTATOR = <=,
  NEGATOR  = <,
  RESTRICT = scalargesel,
  JOIN     = scalargejoinsel
);
