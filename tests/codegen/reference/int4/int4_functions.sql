-- REFERENCE: hand-maintained parity baseline for crates/eql-codegen - see ../README.md
-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/schema.sql
-- REQUIRE: src/schema-v3.sql
-- REQUIRE: src/encrypted_domain/int4/int4_types.sql
-- REQUIRE: src/encrypted_domain/functions.sql

--! @file encrypted_domain/int4/int4_functions.sql
--! @brief Functions for eql_v3.int4.

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.int4, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3.eq(a jsonb, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.int4, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3.neq(a jsonb, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3.lt(a eql_v3.int4, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lt(a eql_v3.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3.lt(a jsonb, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3.lte(a eql_v3.int4, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lte(a eql_v3.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3.lte(a jsonb, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3.gt(a eql_v3.int4, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gt(a eql_v3.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3.gt(a jsonb, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3.gte(a eql_v3.int4, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gte(a eql_v3.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3.gte(a jsonb, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3.contains(a eql_v3.int4, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contains(a eql_v3.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3.contains(a jsonb, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a eql_v3.int4, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a eql_v3.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a jsonb, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param selector text
--! @return eql_v3.int4
CREATE FUNCTION eql_v3."->"(a eql_v3.int4, selector text)
RETURNS eql_v3.int4 IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param selector integer
--! @return eql_v3.int4
CREATE FUNCTION eql_v3."->"(a eql_v3.int4, selector integer)
RETURNS eql_v3.int4 IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param selector eql_v3.int4
--! @return eql_v3.int4
CREATE FUNCTION eql_v3."->"(a jsonb, selector eql_v3.int4)
RETURNS eql_v3.int4 IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3."->>"(a eql_v3.int4, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3."->>"(a eql_v3.int4, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param selector eql_v3.int4
--! @return text
CREATE FUNCTION eql_v3."->>"(a jsonb, selector eql_v3.int4)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3."?"(a eql_v3.int4, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3."?|"(a eql_v3.int4, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3."?&"(a eql_v3.int4, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3."@?"(a eql_v3.int4, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3."@@"(a eql_v3.int4, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."#>"(a eql_v3.int4, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3."#>>"(a eql_v3.int4, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.int4, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.int4, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.int4, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."#-"(a eql_v3.int4, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b eql_v3.int4
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a eql_v3.int4, b eql_v3.int4)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a eql_v3.int4, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param b eql_v3.int4
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a jsonb, b eql_v3.int4)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;
