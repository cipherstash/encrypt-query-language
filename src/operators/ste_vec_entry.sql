-- REQUIRE: src/schema.sql
-- REQUIRE: src/ste_vec/types.sql
-- REQUIRE: src/hmac_256/types.sql
-- REQUIRE: src/hmac_256/functions.sql
-- REQUIRE: src/ore_cllw/types.sql
-- REQUIRE: src/ore_cllw/functions.sql

--! @file src/operators/ste_vec_entry.sql
--! @brief Comparison operators on `eql_v2.ste_vec_entry`
--!
--! Equality (`=`, `<>`) reduces to `hmac_256(a) = hmac_256(b)`. Ordering
--! (`<`, `<=`, `>`, `>=`) reduces to `ore_cllw(a) <op> ore_cllw(b)`. Each
--! backing function is inlinable single-statement SQL, so the planner can
--! fold the operator body into the calling query — `WHERE col -> 'sel' = $1`
--! and `WHERE col -> 'sel' < $1` therefore match functional indexes built on
--! `eql_v2.hmac_256(col -> 'sel')` / `eql_v2.ore_cllw(col -> 'sel')` without
--! per-query rewriting.
--!
--! Same convention as the `eql_v2_encrypted` operators (#193 / #211): the
--! operator-class function-matching layer is what makes index match work
--! structurally, the backing functions just need to inline cleanly through
--! to the extractor calls.
--!
--! @see eql_v2.hmac_256(eql_v2.ste_vec_entry)
--! @see eql_v2.ore_cllw(eql_v2.ste_vec_entry)
--! @see src/operators/=.sql
--! @see src/operators/<.sql

--! @brief Equality backing function for `eql_v2.ste_vec_entry`
--! @internal
--! @param a eql_v2.ste_vec_entry Left operand
--! @param b eql_v2.ste_vec_entry Right operand
--! @return boolean True if both entries share an HMAC
CREATE FUNCTION eql_v2.eq(a eql_v2.ste_vec_entry, b eql_v2.ste_vec_entry)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.hmac_256(a) = eql_v2.hmac_256(b)
$$;

CREATE OPERATOR = (
  FUNCTION = eql_v2.eq,
  LEFTARG  = eql_v2.ste_vec_entry,
  RIGHTARG = eql_v2.ste_vec_entry,
  COMMUTATOR = =,
  NEGATOR  = <>,
  RESTRICT = eqsel,
  JOIN     = eqjoinsel,
  HASHES,
  MERGES
);


--! @brief Inequality backing function for `eql_v2.ste_vec_entry`
--! @internal
--! @param a eql_v2.ste_vec_entry Left operand
--! @param b eql_v2.ste_vec_entry Right operand
--! @return boolean True if the HMACs differ
CREATE FUNCTION eql_v2.neq(a eql_v2.ste_vec_entry, b eql_v2.ste_vec_entry)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.hmac_256(a) <> eql_v2.hmac_256(b)
$$;

CREATE OPERATOR <> (
  FUNCTION = eql_v2.neq,
  LEFTARG  = eql_v2.ste_vec_entry,
  RIGHTARG = eql_v2.ste_vec_entry,
  COMMUTATOR = <>,
  NEGATOR  = =,
  RESTRICT = neqsel,
  JOIN     = neqjoinsel
);


--! @brief Less-than backing function for `eql_v2.ste_vec_entry`
--! @internal
--! @param a eql_v2.ste_vec_entry Left operand
--! @param b eql_v2.ste_vec_entry Right operand
--! @return boolean True if `a`'s CLLW ORE term sorts before `b`'s
CREATE FUNCTION eql_v2.lt(a eql_v2.ste_vec_entry, b eql_v2.ste_vec_entry)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.ore_cllw(a) < eql_v2.ore_cllw(b)
$$;

CREATE OPERATOR < (
  FUNCTION = eql_v2.lt,
  LEFTARG  = eql_v2.ste_vec_entry,
  RIGHTARG = eql_v2.ste_vec_entry,
  COMMUTATOR = >,
  NEGATOR  = >=,
  RESTRICT = scalarltsel,
  JOIN     = scalarltjoinsel
);


--! @brief Less-than-or-equal backing function for `eql_v2.ste_vec_entry`
--! @internal
--! @param a eql_v2.ste_vec_entry Left operand
--! @param b eql_v2.ste_vec_entry Right operand
--! @return boolean True if `a`'s CLLW ORE term sorts before or equal to `b`'s
CREATE FUNCTION eql_v2.lte(a eql_v2.ste_vec_entry, b eql_v2.ste_vec_entry)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.ore_cllw(a) <= eql_v2.ore_cllw(b)
$$;

CREATE OPERATOR <= (
  FUNCTION = eql_v2.lte,
  LEFTARG  = eql_v2.ste_vec_entry,
  RIGHTARG = eql_v2.ste_vec_entry,
  COMMUTATOR = >=,
  NEGATOR  = >,
  RESTRICT = scalarlesel,
  JOIN     = scalarlejoinsel
);


--! @brief Greater-than backing function for `eql_v2.ste_vec_entry`
--! @internal
--! @param a eql_v2.ste_vec_entry Left operand
--! @param b eql_v2.ste_vec_entry Right operand
--! @return boolean True if `a`'s CLLW ORE term sorts after `b`'s
CREATE FUNCTION eql_v2.gt(a eql_v2.ste_vec_entry, b eql_v2.ste_vec_entry)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.ore_cllw(a) > eql_v2.ore_cllw(b)
$$;

CREATE OPERATOR > (
  FUNCTION = eql_v2.gt,
  LEFTARG  = eql_v2.ste_vec_entry,
  RIGHTARG = eql_v2.ste_vec_entry,
  COMMUTATOR = <,
  NEGATOR  = <=,
  RESTRICT = scalargtsel,
  JOIN     = scalargtjoinsel
);


--! @brief Greater-than-or-equal backing function for `eql_v2.ste_vec_entry`
--! @internal
--! @param a eql_v2.ste_vec_entry Left operand
--! @param b eql_v2.ste_vec_entry Right operand
--! @return boolean True if `a`'s CLLW ORE term sorts after or equal to `b`'s
CREATE FUNCTION eql_v2.gte(a eql_v2.ste_vec_entry, b eql_v2.ste_vec_entry)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.ore_cllw(a) >= eql_v2.ore_cllw(b)
$$;

CREATE OPERATOR >= (
  FUNCTION = eql_v2.gte,
  LEFTARG  = eql_v2.ste_vec_entry,
  RIGHTARG = eql_v2.ste_vec_entry,
  COMMUTATOR = <=,
  NEGATOR  = <,
  RESTRICT = scalargesel,
  JOIN     = scalargejoinsel
);
