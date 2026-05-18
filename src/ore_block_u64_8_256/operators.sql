-- REQUIRE: src/schema.sql
-- REQUIRE: src/ore_block_u64_8_256/types.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql

--! @brief Equality operator for ORE block types
--! @internal
--!
--! Implements the = operator for direct ORE block comparisons.
--!
--! @param a eql_v2.ore_block_u64_8_256 Left operand
--! @param b eql_v2.ore_block_u64_8_256 Right operand
--! @return Boolean True if ORE blocks are equal
--!
--! @see eql_v2.compare_ore_block_u64_8_256_terms
CREATE FUNCTION eql_v2.ore_block_u64_8_256_eq(a eql_v2.ore_block_u64_8_256, b eql_v2.ore_block_u64_8_256)
RETURNS boolean
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.compare_ore_block_u64_8_256_terms(a, b) = 0
$$;



--! @brief Not equal operator for ORE block types
--! @internal
--!
--! Implements the <> operator for direct ORE block comparisons.
--!
--! @param a eql_v2.ore_block_u64_8_256 Left operand
--! @param b eql_v2.ore_block_u64_8_256 Right operand
--! @return Boolean True if ORE blocks are not equal
--!
--! @see eql_v2.compare_ore_block_u64_8_256_terms
CREATE FUNCTION eql_v2.ore_block_u64_8_256_neq(a eql_v2.ore_block_u64_8_256, b eql_v2.ore_block_u64_8_256)
RETURNS boolean
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.compare_ore_block_u64_8_256_terms(a, b) <> 0
$$;



--! @brief Less than operator for ORE block types
--! @internal
--!
--! Implements the < operator for direct ORE block comparisons.
--!
--! @param a eql_v2.ore_block_u64_8_256 Left operand
--! @param b eql_v2.ore_block_u64_8_256 Right operand
--! @return Boolean True if left operand is less than right operand
--!
--! @see eql_v2.compare_ore_block_u64_8_256_terms
CREATE FUNCTION eql_v2.ore_block_u64_8_256_lt(a eql_v2.ore_block_u64_8_256, b eql_v2.ore_block_u64_8_256)
RETURNS boolean
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.compare_ore_block_u64_8_256_terms(a, b) = -1
$$;



--! @brief Less than or equal operator for ORE block types
--! @internal
--!
--! Implements the <= operator for direct ORE block comparisons.
--!
--! @param a eql_v2.ore_block_u64_8_256 Left operand
--! @param b eql_v2.ore_block_u64_8_256 Right operand
--! @return Boolean True if left operand is less than or equal to right operand
--!
--! @see eql_v2.compare_ore_block_u64_8_256_terms
CREATE FUNCTION eql_v2.ore_block_u64_8_256_lte(a eql_v2.ore_block_u64_8_256, b eql_v2.ore_block_u64_8_256)
RETURNS boolean
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.compare_ore_block_u64_8_256_terms(a, b) != 1
$$;



--! @brief Greater than operator for ORE block types
--! @internal
--!
--! Implements the > operator for direct ORE block comparisons.
--!
--! @param a eql_v2.ore_block_u64_8_256 Left operand
--! @param b eql_v2.ore_block_u64_8_256 Right operand
--! @return Boolean True if left operand is greater than right operand
--!
--! @see eql_v2.compare_ore_block_u64_8_256_terms
CREATE FUNCTION eql_v2.ore_block_u64_8_256_gt(a eql_v2.ore_block_u64_8_256, b eql_v2.ore_block_u64_8_256)
RETURNS boolean
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.compare_ore_block_u64_8_256_terms(a, b) = 1
$$;



--! @brief Greater than or equal operator for ORE block types
--! @internal
--!
--! Implements the >= operator for direct ORE block comparisons.
--!
--! @param a eql_v2.ore_block_u64_8_256 Left operand
--! @param b eql_v2.ore_block_u64_8_256 Right operand
--! @return Boolean True if left operand is greater than or equal to right operand
--!
--! @see eql_v2.compare_ore_block_u64_8_256_terms
CREATE FUNCTION eql_v2.ore_block_u64_8_256_gte(a eql_v2.ore_block_u64_8_256, b eql_v2.ore_block_u64_8_256)
RETURNS boolean
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.compare_ore_block_u64_8_256_terms(a, b) != -1
$$;



--! @brief = operator for ORE block types
CREATE OPERATOR = (
  FUNCTION=eql_v2.ore_block_u64_8_256_eq,
  LEFTARG=eql_v2.ore_block_u64_8_256,
  RIGHTARG=eql_v2.ore_block_u64_8_256,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);



--! @brief <> operator for ORE block types
CREATE OPERATOR <> (
  FUNCTION=eql_v2.ore_block_u64_8_256_neq,
  LEFTARG=eql_v2.ore_block_u64_8_256,
  RIGHTARG=eql_v2.ore_block_u64_8_256,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


--! @brief > operator for ORE block types
CREATE OPERATOR > (
  FUNCTION=eql_v2.ore_block_u64_8_256_gt,
  LEFTARG=eql_v2.ore_block_u64_8_256,
  RIGHTARG=eql_v2.ore_block_u64_8_256,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);



--! @brief < operator for ORE block types
CREATE OPERATOR < (
  FUNCTION=eql_v2.ore_block_u64_8_256_lt,
  LEFTARG=eql_v2.ore_block_u64_8_256,
  RIGHTARG=eql_v2.ore_block_u64_8_256,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);



--! @brief <= operator for ORE block types
CREATE OPERATOR <= (
  FUNCTION=eql_v2.ore_block_u64_8_256_lte,
  LEFTARG=eql_v2.ore_block_u64_8_256,
  RIGHTARG=eql_v2.ore_block_u64_8_256,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);



--! @brief >= operator for ORE block types
CREATE OPERATOR >= (
  FUNCTION=eql_v2.ore_block_u64_8_256_gte,
  LEFTARG=eql_v2.ore_block_u64_8_256,
  RIGHTARG=eql_v2.ore_block_u64_8_256,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalargesel,
  JOIN = scalargejoinsel
);
