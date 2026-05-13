-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/operators/compare.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql
-- REQUIRE: src/ore_block_u64_8_256/operators.sql

--! @brief Greater-than-or-equal comparison helper for encrypted values
--! @internal
--!
--! Internal helper that delegates to eql_v2.compare for >= testing. Kept
--! for callers that invoke it directly. The `>=` operator wrappers no
--! longer go through this helper — see the inlinable bodies below.
--!
--! @param a eql_v2_encrypted First encrypted value
--! @param b eql_v2_encrypted Second encrypted value
--! @return Boolean True if a >= b (compare result >= 0)
--!
--! @see eql_v2.compare
--! @see eql_v2.">="
CREATE FUNCTION eql_v2.gte(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
  SET search_path = pg_catalog, extensions, public
AS $$
  BEGIN
    RETURN eql_v2.compare(a, b) >= 0;
  END;
$$ LANGUAGE plpgsql;

--! @brief Greater-than-or-equal operator for encrypted values
--!
--! Implements the >= operator for comparing two encrypted values via their
--! `ob` (ore_block_u64_8_256) ORE term. Requires the column to carry an
--! `ob` term.
--!
--! @param a eql_v2_encrypted Left operand
--! @param b eql_v2_encrypted Right operand
--! @return Boolean True if a >= b
--!
--! @example
--! SELECT * FROM users WHERE encrypted_age >= '18'::int::text::eql_v2_encrypted;
--!
--! @see eql_v2.ore_block_u64_8_256
--! @see eql_v2.add_search_config
-- Inlinable: see `src/operators/<.sql` for the rationale.
CREATE FUNCTION eql_v2.">="(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.ore_block_u64_8_256(a) >= eql_v2.ore_block_u64_8_256(b)
$$;


CREATE OPERATOR >=(
  FUNCTION = eql_v2.">=",
  LEFTARG = eql_v2_encrypted,
  RIGHTARG = eql_v2_encrypted,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);

--! @brief >= operator for encrypted value and JSONB
--! @param a eql_v2_encrypted Left operand (encrypted value)
--! @param b jsonb Right operand
--! @return Boolean True if a >= b
--! @see eql_v2.">="(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2.">="(a eql_v2_encrypted, b jsonb)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.ore_block_u64_8_256(a) >= eql_v2.ore_block_u64_8_256(b)
$$;

CREATE OPERATOR >=(
  FUNCTION = eql_v2.">=",
  LEFTARG = eql_v2_encrypted,
  RIGHTARG=jsonb,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);

--! @brief >= operator for JSONB and encrypted value
--! @param a jsonb Left operand
--! @param b eql_v2_encrypted Right operand (encrypted value)
--! @return Boolean True if a >= b
--! @see eql_v2.">="(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2.">="(a jsonb, b eql_v2_encrypted)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.ore_block_u64_8_256(a) >= eql_v2.ore_block_u64_8_256(b)
$$;


CREATE OPERATOR >=(
  FUNCTION = eql_v2.">=",
  LEFTARG = jsonb,
  RIGHTARG =eql_v2_encrypted,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);
