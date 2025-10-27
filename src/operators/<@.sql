-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/ste_vec/functions.sql

--! @brief Contained-by operator for encrypted values (<@)
--!
--! Implements the <@ (contained-by) operator for testing if left encrypted value
--! is contained by the right encrypted value. Uses ste_vec (secure tree encoding vector)
--! index terms for containment testing without decryption. Reverse of @> operator.
--!
--! Primarily used for encrypted array or set containment queries.
--!
--! @param a eql_v2_encrypted Left operand (contained value)
--! @param b eql_v2_encrypted Right operand (container)
--! @return Boolean True if a is contained by b
--!
--! @example
--! -- Check if value is contained in encrypted array
--! SELECT * FROM documents
--! WHERE '["security"]'::jsonb::eql_v2_encrypted <@ encrypted_tags;
--!
--! @note Requires ste_vec index configuration
--! @see eql_v2.ste_vec_contains
--! @see eql_v2.\"@>\"
--! @see eql_v2.add_search_config

CREATE FUNCTION eql_v2."<@"(a eql_v2_encrypted, b eql_v2_encrypted)
RETURNS boolean AS $$
  -- Contains with reversed arguments
  SELECT eql_v2.ste_vec_contains(b, a)
$$ LANGUAGE SQL;

CREATE OPERATOR <@(
  FUNCTION=eql_v2."<@",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted
);
