-- REQUIRE: src/schema.sql

-- Represents a ciphertext encrypted with the CLLW ORE scheme for a fixed output size
-- Each output block is 8-bits
CREATE TYPE eql_v1.ore_cllw_u64_8 AS (
  bytes bytea
);
