-- REQUIRE: src/schema.sql

-- Represents a ciphertext encrypted with the CLLW ORE scheme for a variable output size
-- Each output block is 8-bits
CREATE TYPE eql_v2.ore_cllw_var_8 AS (
  bytes bytea
);
