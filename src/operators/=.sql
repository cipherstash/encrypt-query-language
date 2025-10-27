-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/operators/compare.sql

--! @brief Equality comparison helper for encrypted values
--! @internal
--!
--! Internal helper that delegates to eql_v2.compare for equality testing.
--! Returns true if encrypted values are equal via encrypted index comparison.
--!
--! @param a eql_v2_encrypted First encrypted value
--! @param b eql_v2_encrypted Second encrypted value
--! @return Boolean True if values are equal (compare result = 0)
--!
--! @see eql_v2.compare
--! @see eql_v2."="
CREATE FUNCTION eql_v2.eq(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN eql_v2.compare(a, b) = 0;
  END;
$$ LANGUAGE plpgsql;

--! @brief Equality operator for encrypted values
--!
--! Implements the = operator for comparing two encrypted values using their
--! encrypted index terms (unique/blake3). Enables WHERE clause comparisons
--! without decryption.
--!
--! @param a eql_v2_encrypted Left operand
--! @param b eql_v2_encrypted Right operand
--! @return Boolean True if encrypted values are equal
--!
--! @example
--! -- Compare encrypted columns
--! SELECT * FROM users WHERE encrypted_email = other_encrypted_email;
--!
--! -- Search using encrypted literal
--! SELECT * FROM users
--! WHERE encrypted_email = '{"c":"...","i":{"unique":"..."}}'::eql_v2_encrypted;
--!
--! @see eql_v2.compare
--! @see eql_v2.add_search_config
CREATE FUNCTION eql_v2."="(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN eql_v2.eq(a, b);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR = (
  FUNCTION=eql_v2."=",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

--! @brief Equality operator for encrypted value and JSONB
--!
--! Overload of = operator accepting JSONB on the right side. Automatically
--! casts JSONB to eql_v2_encrypted for comparison. Useful for comparing
--! against JSONB literals or columns.
--!
--! @param a eql_v2_encrypted Left operand (encrypted value)
--! @param b JSONB Right operand (will be cast to eql_v2_encrypted)
--! @return Boolean True if values are equal
--!
--! @example
--! -- Compare encrypted column to JSONB literal
--! SELECT * FROM users
--! WHERE encrypted_email = '{"c":"...","i":{"unique":"..."}}'::jsonb;
--!
--! @see eql_v2."="(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2."="(a eql_v2_encrypted, b jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN eql_v2.eq(a, b::eql_v2_encrypted);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR = (
  FUNCTION=eql_v2."=",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=jsonb,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

--! @brief Equality operator for JSONB and encrypted value
--!
--! Overload of = operator accepting JSONB on the left side. Automatically
--! casts JSONB to eql_v2_encrypted for comparison. Enables commutative
--! equality comparisons.
--!
--! @param a JSONB Left operand (will be cast to eql_v2_encrypted)
--! @param b eql_v2_encrypted Right operand (encrypted value)
--! @return Boolean True if values are equal
--!
--! @example
--! -- Compare JSONB literal to encrypted column
--! SELECT * FROM users
--! WHERE '{"c":"...","i":{"unique":"..."}}'::jsonb = encrypted_email;
--!
--! @see eql_v2."="(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2."="(a jsonb, b eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN eql_v2.eq(a::eql_v2_encrypted, b);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR = (
  FUNCTION=eql_v2."=",
  LEFTARG=jsonb,
  RIGHTARG=eql_v2_encrypted,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

