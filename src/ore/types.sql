-- REQUIRE: src/schema.sql

DROP TYPE IF EXISTS eql_v1.ore_64_8_v1_term;

CREATE TYPE eql_v1.ore_64_8_v1_term AS (
  bytes bytea
);

DROP TYPE IF EXISTS eql_v1.ore_64_8_v1;

CREATE TYPE eql_v1.ore_64_8_v1 AS (
  terms eql_v1.ore_64_8_v1_term[]
);
