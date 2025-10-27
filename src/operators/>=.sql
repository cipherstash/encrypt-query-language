-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/operators/compare.sql

--! @brief Greater-than-or-equal comparison helper for encrypted values
--! @internal
--!
--! Internal helper that delegates to eql_v2.compare for >= testing.
--! Returns true if first value is greater than or equal to second using ORE comparison.
--!
--! @param a eql_v2_encrypted First encrypted value
--! @param b eql_v2_encrypted Second encrypted value
--! @return Boolean True if a >= b (compare result >= 0)
--!
--! @see eql_v2.compare
--! @see eql_v2.">="
CREATE FUNCTION eql_v2.gte(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.compare(a, b) >= 0;
  END;
$$ LANGUAGE plpgsql;

--! @brief Greater-than-or-equal operator for encrypted values
--!
--! Implements the >= operator for comparing encrypted values using ORE index terms.
--! Enables range queries with inclusive upper bounds without decryption.
--!
--! @param a eql_v2_encrypted Left operand
--! @param b eql_v2_encrypted Right operand
--! @return Boolean True if a >= b
--!
--! @example
--! -- Find records with age 18 or over
--! SELECT * FROM users WHERE encrypted_age >= '18'::int::text::eql_v2_encrypted;
--!
--! @see eql_v2.compare
--! @see eql_v2.add_search_config
CREATE FUNCTION eql_v2.">="(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.gte(a, b);
  END;
$$ LANGUAGE plpgsql;


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
--! @see eql_v2.">="(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2.">="(a eql_v2_encrypted, b jsonb)
RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.gte(a, b::eql_v2_encrypted);
  END;
$$ LANGUAGE plpgsql;

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
--! @see eql_v2.">="(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2.">="(a jsonb, b eql_v2_encrypted)
RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.gte(a::eql_v2_encrypted, b);
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR >=(
  FUNCTION = eql_v2.">=",
  LEFTARG = jsonb,
  RIGHTARG =eql_v2_encrypted,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);


