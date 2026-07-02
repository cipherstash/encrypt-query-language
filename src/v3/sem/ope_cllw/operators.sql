-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/sem/ope_cllw/types.sql
-- REQUIRE: src/v3/sem/ope_cllw/functions.sql

--! @file v3/sem/ope_cllw/operators.sql
--! @brief Comparison operators on the eql_v3.ope_cllw composite type.
--!
--! Each backing function reduces to a single native bytea comparison of the
--! decoded terms (the CLLW OPE ciphertext is order-preserving under plain
--! byte comparison — no custom protocol) and is inlinable so the planner can
--! fold it through to functional-index matching.
--!
--! @note Deliberately no HASHES / MERGES — mirrors eql_v3.ore_cllw: there is
--!       no merge-joinable opclass on the other side.
--! @see eql_v3.compare_ope_cllw_term

--! @brief Equality backing function for eql_v3.ope_cllw.
--! @internal
--!
--! @param a eql_v3.ope_cllw Left operand
--! @param b eql_v3.ope_cllw Right operand
--! @return boolean True if the CLLW OPE terms are equal
--!
--! @see eql_v3.compare_ope_cllw_term
CREATE FUNCTION eql_v3.ope_cllw_eq(a eql_v3.ope_cllw, b eql_v3.ope_cllw)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT a.bytes = b.bytes
$$;

--! @brief Not-equal backing function for eql_v3.ope_cllw.
--! @internal
--!
--! @param a eql_v3.ope_cllw Left operand
--! @param b eql_v3.ope_cllw Right operand
--! @return boolean True if the CLLW OPE terms are not equal
--!
--! @see eql_v3.compare_ope_cllw_term
CREATE FUNCTION eql_v3.ope_cllw_neq(a eql_v3.ope_cllw, b eql_v3.ope_cllw)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT a.bytes <> b.bytes
$$;

--! @brief Less-than backing function for eql_v3.ope_cllw.
--! @internal
--!
--! @param a eql_v3.ope_cllw Left operand
--! @param b eql_v3.ope_cllw Right operand
--! @return boolean True if the left operand is less than the right operand
--!
--! @see eql_v3.compare_ope_cllw_term
CREATE FUNCTION eql_v3.ope_cllw_lt(a eql_v3.ope_cllw, b eql_v3.ope_cllw)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT a.bytes < b.bytes
$$;

--! @brief Less-than-or-equal backing function for eql_v3.ope_cllw.
--! @internal
--!
--! @param a eql_v3.ope_cllw Left operand
--! @param b eql_v3.ope_cllw Right operand
--! @return boolean True if the left operand is less than or equal to the right operand
--!
--! @see eql_v3.compare_ope_cllw_term
CREATE FUNCTION eql_v3.ope_cllw_lte(a eql_v3.ope_cllw, b eql_v3.ope_cllw)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT a.bytes <= b.bytes
$$;

--! @brief Greater-than backing function for eql_v3.ope_cllw.
--! @internal
--!
--! @param a eql_v3.ope_cllw Left operand
--! @param b eql_v3.ope_cllw Right operand
--! @return boolean True if the left operand is greater than the right operand
--!
--! @see eql_v3.compare_ope_cllw_term
CREATE FUNCTION eql_v3.ope_cllw_gt(a eql_v3.ope_cllw, b eql_v3.ope_cllw)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT a.bytes > b.bytes
$$;

--! @brief Greater-than-or-equal backing function for eql_v3.ope_cllw.
--! @internal
--!
--! @param a eql_v3.ope_cllw Left operand
--! @param b eql_v3.ope_cllw Right operand
--! @return boolean True if the left operand is greater than or equal to the right operand
--!
--! @see eql_v3.compare_ope_cllw_term
CREATE FUNCTION eql_v3.ope_cllw_gte(a eql_v3.ope_cllw, b eql_v3.ope_cllw)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT a.bytes >= b.bytes
$$;


CREATE OPERATOR = (
  FUNCTION = eql_v3.ope_cllw_eq,
  LEFTARG = eql_v3.ope_cllw,
  RIGHTARG = eql_v3.ope_cllw,
  COMMUTATOR = =,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.ope_cllw_neq,
  LEFTARG = eql_v3.ope_cllw,
  RIGHTARG = eql_v3.ope_cllw,
  COMMUTATOR = <>,
  NEGATOR = =,
  RESTRICT = neqsel,
  JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.ope_cllw_lt,
  LEFTARG = eql_v3.ope_cllw,
  RIGHTARG = eql_v3.ope_cllw,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.ope_cllw_lte,
  LEFTARG = eql_v3.ope_cllw,
  RIGHTARG = eql_v3.ope_cllw,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.ope_cllw_gt,
  LEFTARG = eql_v3.ope_cllw,
  RIGHTARG = eql_v3.ope_cllw,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.ope_cllw_gte,
  LEFTARG = eql_v3.ope_cllw,
  RIGHTARG = eql_v3.ope_cllw,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalargesel,
  JOIN = scalargejoinsel
);
