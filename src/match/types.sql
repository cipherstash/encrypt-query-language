-- REQUIRE: src/schema.sql

DROP DOMAIN IF EXISTS eql_v1.match_index;
CREATE DOMAIN eql_v1.match_index AS smallint[];

