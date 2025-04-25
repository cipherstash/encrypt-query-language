-- REQUIRE: src/schema.sql

DROP DOMAIN IF EXISTS eql_v1.blake3;
CREATE DOMAIN eql_v1.blake3 AS text;
