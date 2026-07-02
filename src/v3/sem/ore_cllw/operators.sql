-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/sem/ore_cllw/types.sql
-- REQUIRE: src/v3/sem/ore_cllw/functions.sql

--! @file v3/sem/ore_cllw/operators.sql
--! @brief Comparison operators on the eql_v3_internal.ore_cllw composite type.
--!
--! Each backing function reduces to a single SELECT over
--! eql_v3_internal.compare_ore_cllw_term(a, b) and is inlinable so the planner can fold
--! it through to functional-index matching. The inner comparator is plpgsql
--! (per-byte loop) and is not inlined — fine for index *match*.
--!
--! @note Deliberately no HASHES / MERGES — the CLLW protocol gives ordering,
--!       not a hash; there is no merge-joinable opclass on the other side.
--! @see eql_v3_internal.compare_ore_cllw_term

--! @brief Equality backing function for eql_v3_internal.ore_cllw.
--! @internal
--!
--! @param a eql_v3_internal.ore_cllw Left operand
--! @param b eql_v3_internal.ore_cllw Right operand
--! @return boolean True if the CLLW ORE terms are equal
--!
--! @see eql_v3_internal.compare_ore_cllw_term
CREATE FUNCTION eql_v3_internal.ore_cllw_eq(a eql_v3_internal.ore_cllw, b eql_v3_internal.ore_cllw)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3_internal.compare_ore_cllw_term(a, b) = 0
$$;

--! @brief Not-equal backing function for eql_v3_internal.ore_cllw.
--! @internal
--!
--! @param a eql_v3_internal.ore_cllw Left operand
--! @param b eql_v3_internal.ore_cllw Right operand
--! @return boolean True if the CLLW ORE terms are not equal
--!
--! @see eql_v3_internal.compare_ore_cllw_term
CREATE FUNCTION eql_v3_internal.ore_cllw_neq(a eql_v3_internal.ore_cllw, b eql_v3_internal.ore_cllw)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3_internal.compare_ore_cllw_term(a, b) <> 0
$$;

--! @brief Less-than backing function for eql_v3_internal.ore_cllw.
--! @internal
--!
--! @param a eql_v3_internal.ore_cllw Left operand
--! @param b eql_v3_internal.ore_cllw Right operand
--! @return boolean True if the left operand is less than the right operand
--!
--! @see eql_v3_internal.compare_ore_cllw_term
CREATE FUNCTION eql_v3_internal.ore_cllw_lt(a eql_v3_internal.ore_cllw, b eql_v3_internal.ore_cllw)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3_internal.compare_ore_cllw_term(a, b) = -1
$$;

--! @brief Less-than-or-equal backing function for eql_v3_internal.ore_cllw.
--! @internal
--!
--! @param a eql_v3_internal.ore_cllw Left operand
--! @param b eql_v3_internal.ore_cllw Right operand
--! @return boolean True if the left operand is less than or equal to the right operand
--!
--! @see eql_v3_internal.compare_ore_cllw_term
CREATE FUNCTION eql_v3_internal.ore_cllw_lte(a eql_v3_internal.ore_cllw, b eql_v3_internal.ore_cllw)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3_internal.compare_ore_cllw_term(a, b) <> 1
$$;

--! @brief Greater-than backing function for eql_v3_internal.ore_cllw.
--! @internal
--!
--! @param a eql_v3_internal.ore_cllw Left operand
--! @param b eql_v3_internal.ore_cllw Right operand
--! @return boolean True if the left operand is greater than the right operand
--!
--! @see eql_v3_internal.compare_ore_cllw_term
CREATE FUNCTION eql_v3_internal.ore_cllw_gt(a eql_v3_internal.ore_cllw, b eql_v3_internal.ore_cllw)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3_internal.compare_ore_cllw_term(a, b) = 1
$$;

--! @brief Greater-than-or-equal backing function for eql_v3_internal.ore_cllw.
--! @internal
--!
--! @param a eql_v3_internal.ore_cllw Left operand
--! @param b eql_v3_internal.ore_cllw Right operand
--! @return boolean True if the left operand is greater than or equal to the right operand
--!
--! @see eql_v3_internal.compare_ore_cllw_term
CREATE FUNCTION eql_v3_internal.ore_cllw_gte(a eql_v3_internal.ore_cllw, b eql_v3_internal.ore_cllw)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3_internal.compare_ore_cllw_term(a, b) <> -1
$$;


CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.ore_cllw_eq,
  LEFTARG = eql_v3_internal.ore_cllw,
  RIGHTARG = eql_v3_internal.ore_cllw,
  COMMUTATOR = =,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.ore_cllw_neq,
  LEFTARG = eql_v3_internal.ore_cllw,
  RIGHTARG = eql_v3_internal.ore_cllw,
  COMMUTATOR = <>,
  NEGATOR = =,
  RESTRICT = neqsel,
  JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.ore_cllw_lt,
  LEFTARG = eql_v3_internal.ore_cllw,
  RIGHTARG = eql_v3_internal.ore_cllw,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.ore_cllw_lte,
  LEFTARG = eql_v3_internal.ore_cllw,
  RIGHTARG = eql_v3_internal.ore_cllw,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.ore_cllw_gt,
  LEFTARG = eql_v3_internal.ore_cllw,
  RIGHTARG = eql_v3_internal.ore_cllw,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.ore_cllw_gte,
  LEFTARG = eql_v3_internal.ore_cllw,
  RIGHTARG = eql_v3_internal.ore_cllw,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalargesel,
  JOIN = scalargejoinsel
);
