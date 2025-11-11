-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/operators/compare.sql

--! @brief Less-than comparison helper for encrypted values
--! @internal
--!
--! Internal helper that delegates to eql_v2.compare for less-than testing.
--! Returns true if first value is less than second using ORE comparison.
--!
--! @param a eql_v2_encrypted First encrypted value
--! @param b eql_v2_encrypted Second encrypted value
--! @return Boolean True if a < b (compare result = -1)
--!
--! @see eql_v2.compare
--! @see eql_v2."<"
CREATE FUNCTION eql_v2.lt(a eql_v2_encrypted, b eql_v2_encrypted)
RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.compare(a, b) = -1;
  END;
$$ LANGUAGE plpgsql;

--! @brief Less-than operator for encrypted values
--!
--! Implements the < operator for comparing two encrypted values using Order-Revealing
--! Encryption (ORE) index terms. Enables range queries and sorting without decryption.
--! Requires 'ore' index configuration on the column.
--!
--! @param a eql_v2_encrypted Left operand
--! @param b eql_v2_encrypted Right operand
--! @return Boolean True if a is less than b
--!
--! @example
--! -- Range query on encrypted timestamps
--! SELECT * FROM events
--! WHERE encrypted_timestamp < '2024-01-01'::timestamp::text::eql_v2_encrypted;
--!
--! -- Compare encrypted numeric columns
--! SELECT * FROM products WHERE encrypted_price < encrypted_discount_price;
--!
--! @see eql_v2.compare
--! @see eql_v2.add_search_config
CREATE FUNCTION eql_v2."<"(a eql_v2_encrypted, b eql_v2_encrypted)
RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.lt(a, b);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR <(
  FUNCTION=eql_v2."<",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);

--! @brief Less-than operator for encrypted value and JSONB
--!
--! Overload of < operator accepting JSONB on the right side. Automatically
--! casts JSONB to eql_v2_encrypted for ORE comparison.
--!
--! @param eql_v2_encrypted Left operand (encrypted value)
--! @param b JSONB Right operand (will be cast to eql_v2_encrypted)
--! @return Boolean True if a < b
--!
--! @example
--! SELECT * FROM events WHERE encrypted_age < '18'::int::text::jsonb;
--!
--! @see eql_v2."<"(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2."<"(a eql_v2_encrypted, b jsonb)
RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.lt(a, b::eql_v2_encrypted);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR <(
  FUNCTION=eql_v2."<",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=jsonb,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);

--! @brief Less-than operator for JSONB and encrypted value
--!
--! Overload of < operator accepting JSONB on the left side. Automatically
--! casts JSONB to eql_v2_encrypted for ORE comparison.
--!
--! @param a JSONB Left operand (will be cast to eql_v2_encrypted)
--! @param eql_v2_encrypted Right operand (encrypted value)
--! @return Boolean True if a < b
--!
--! @example
--! SELECT * FROM events WHERE '2023-01-01'::date::text::jsonb < encrypted_date;
--!
--! @see eql_v2."<"(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2."<"(a jsonb, b eql_v2_encrypted)
RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.lt(a::eql_v2_encrypted, b);
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR <(
  FUNCTION=eql_v2."<",
  LEFTARG=jsonb,
  RIGHTARG=eql_v2_encrypted,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);


