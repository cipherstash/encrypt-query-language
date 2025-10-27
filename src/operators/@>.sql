-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/ste_vec/functions.sql

--! @brief Contains operator for encrypted values (@>)
--!
--! Implements the @> (contains) operator for testing if left encrypted value
--! contains the right encrypted value. Uses ste_vec (secure tree encoding vector)
--! index terms for containment testing without decryption.
--!
--! Primarily used for encrypted array or set containment queries.
--!
--! @param a eql_v2_encrypted Left operand (container)
--! @param b eql_v2_encrypted Right operand (contained value)
--! @return Boolean True if a contains b
--!
--! @example
--! -- Check if encrypted array contains value
--! SELECT * FROM documents
--! WHERE encrypted_tags @> '["security"]'::jsonb::eql_v2_encrypted;
--!
--! @note Requires ste_vec index configuration
--! @see eql_v2.ste_vec_contains
--! @see eql_v2.add_search_config
CREATE FUNCTION eql_v2."@>"(a eql_v2_encrypted, b eql_v2_encrypted)
RETURNS boolean AS $$
  SELECT eql_v2.ste_vec_contains(a, b)
$$ LANGUAGE SQL;

CREATE OPERATOR @>(
  FUNCTION=eql_v2."@>",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted
);
