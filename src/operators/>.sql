-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/operators/compare.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql
-- REQUIRE: src/ore_block_u64_8_256/operators.sql

--! @brief Greater-than comparison helper for encrypted values
--! @internal
--! @deprecated Slated for removal in EQL 3.0. Use the `>` operator instead.
--!
--! Internal helper that delegates to `eql_v2.compare` for greater-than
--! testing. The `>` operator wrappers no longer go through this helper —
--! see the inlinable bodies below.
--!
--! @warning Behaviour now diverges from the `>` operator: this helper
--!   still walks `eql_v2.compare`'s priority list, whereas `>` goes
--!   straight to `ore_block_u64_8_256` and raises on missing `ob`. See
--!   the matching note on `eql_v2.lt` and U-005 for migration guidance.
--!
--! @param a eql_v2_encrypted First encrypted value
--! @param b eql_v2_encrypted Second encrypted value
--! @return Boolean True if a > b (compare result = 1)
--!
--! @see eql_v2.compare
--! @see eql_v2.">"
CREATE FUNCTION eql_v2.gt(a eql_v2_encrypted, b eql_v2_encrypted)
RETURNS boolean
  SET search_path = pg_catalog, extensions, public
AS $$
  BEGIN
    RETURN eql_v2.compare(a, b) = 1;
  END;
$$ LANGUAGE plpgsql;

--! @brief Greater-than operator for encrypted values
--!
--! Implements the > operator for comparing two encrypted values via their
--! `ob` (ore_block_u64_8_256) ORE term. Enables range queries and sorting
--! without decryption. Requires the column to carry an `ob` term.
--!
--! @param a eql_v2_encrypted Left operand
--! @param b eql_v2_encrypted Right operand
--! @return Boolean True if a is greater than b
--!
--! @example
--! SELECT * FROM events
--! WHERE encrypted_value > '100'::int::text::eql_v2_encrypted;
--!
--! @see eql_v2.ore_block_u64_8_256
--! @see eql_v2.add_search_config
-- Inlinable: see `src/operators/<.sql` for the rationale. Predicate
-- `WHERE col > val` reduces to
-- `WHERE eql_v2.ore_block_u64_8_256(col) > eql_v2.ore_block_u64_8_256(val)`
-- and matches a functional ORE index built on the same expression.
-- Breaking impact: columns with only `ore_cllw_*` or OPE terms now
-- raise from the `ore_block_u64_8_256(jsonb)` extractor
-- (`Expected an ore index (ob) value in json: ...`) where they
-- previously fell through `eql_v2.compare`. See U-005.
CREATE FUNCTION eql_v2.">"(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.ore_block_u64_8_256(a) > eql_v2.ore_block_u64_8_256(b)
$$;

CREATE OPERATOR >(
  FUNCTION=eql_v2.">",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);

--! @brief > operator for encrypted value and JSONB
--! @param a eql_v2_encrypted Left operand (encrypted value)
--! @param b jsonb Right operand
--! @return Boolean True if a > b
--! @see eql_v2.">"(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2.">"(a eql_v2_encrypted, b jsonb)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.ore_block_u64_8_256(a) > eql_v2.ore_block_u64_8_256(b)
$$;

CREATE OPERATOR >(
  FUNCTION = eql_v2.">",
  LEFTARG = eql_v2_encrypted,
  RIGHTARG = jsonb,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);

--! @brief > operator for JSONB and encrypted value
--! @param a jsonb Left operand
--! @param b eql_v2_encrypted Right operand (encrypted value)
--! @return Boolean True if a > b
--! @see eql_v2.">"(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2.">"(a jsonb, b eql_v2_encrypted)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.ore_block_u64_8_256(a) > eql_v2.ore_block_u64_8_256(b)
$$;


CREATE OPERATOR >(
  FUNCTION = eql_v2.">",
  LEFTARG = jsonb,
  RIGHTARG = eql_v2_encrypted,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);
