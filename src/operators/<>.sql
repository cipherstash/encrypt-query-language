-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/operators/compare.sql

--! @brief Not-equal comparison helper for encrypted values
--! @internal
--!
--! Internal helper that delegates to eql_v2.compare for inequality testing.
--! Returns true if encrypted values are not equal via encrypted index comparison.
--!
--! @param a eql_v2_encrypted First encrypted value
--! @param b eql_v2_encrypted Second encrypted value
--! @return Boolean True if values are not equal (compare result <> 0)
--!
--! @see eql_v2.compare
--! @see eql_v2."<>"
CREATE FUNCTION eql_v2.neq(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN eql_v2.compare(a, b) <> 0;
  END;
$$ LANGUAGE plpgsql;

--! @brief Not-equal operator for encrypted values
--!
--! Implements the <> (not equal) operator for comparing encrypted values using their
--! encrypted index terms. Enables WHERE clause inequality comparisons without decryption.
--!
--! @param a eql_v2_encrypted Left operand
--! @param b eql_v2_encrypted Right operand
--! @return Boolean True if encrypted values are not equal
--!
--! @example
--! -- Find records with non-matching values
--! SELECT * FROM users
--! WHERE encrypted_email <> 'admin@example.com'::text::eql_v2_encrypted;
--!
--! @see eql_v2.compare
--! @see eql_v2."="
CREATE FUNCTION eql_v2."<>"(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN eql_v2.neq(a, b );
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR <> (
  FUNCTION=eql_v2."<>",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

--! @brief <> operator for encrypted value and JSONB
--! @see eql_v2."<>"(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2."<>"(a eql_v2_encrypted, b jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN eql_v2.neq(a, b::eql_v2_encrypted);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR <> (
  FUNCTION=eql_v2."<>",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=jsonb,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

--! @brief <> operator for JSONB and encrypted value
--! @see eql_v2."<>"(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2."<>"(a jsonb, b eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN eql_v2.neq(a::eql_v2_encrypted, b);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR <> (
  FUNCTION=eql_v2."<>",
  LEFTARG=jsonb,
  RIGHTARG=eql_v2_encrypted,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);




