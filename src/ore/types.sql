-- REQUIRE: src/schema.sql


CREATE TYPE eql_v1.ore_64_8_v1_term AS (
  bytes bytea
);


CREATE TYPE eql_v1.ore_64_8_v1 AS (
  terms eql_v1.ore_64_8_v1_term[]
);
