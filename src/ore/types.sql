-- REQUIRE: src/schema.sql


CREATE TYPE eql_v2.ore_64_8_v2_term AS (
  bytes bytea
);


CREATE TYPE eql_v2.ore_64_8_v2 AS (
  terms eql_v2.ore_64_8_v2_term[]
);
