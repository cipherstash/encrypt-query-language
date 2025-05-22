-- REQUIRE: src/schema.sql


CREATE TYPE eql_v2.ore_block_u64_8_256_term AS (
  bytes bytea
);


CREATE TYPE eql_v2.ore_block_u64_8_256 AS (
  terms eql_v2.ore_block_u64_8_256_term[]
);
