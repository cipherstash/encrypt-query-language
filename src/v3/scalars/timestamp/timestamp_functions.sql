-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/timestamp/timestamp_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/timestamp/timestamp_functions.sql
--! @brief Functions for eql_v3.timestamp.

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b eql_v3.timestamp
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.timestamp, b eql_v3.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.timestamp, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a jsonb
--! @param b eql_v3.timestamp
--! @return boolean
CREATE FUNCTION eql_v3.eq(a jsonb, b eql_v3.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b eql_v3.timestamp
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.timestamp, b eql_v3.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.timestamp, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a jsonb
--! @param b eql_v3.timestamp
--! @return boolean
CREATE FUNCTION eql_v3.neq(a jsonb, b eql_v3.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b eql_v3.timestamp
--! @return boolean
CREATE FUNCTION eql_v3.lt(a eql_v3.timestamp, b eql_v3.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lt(a eql_v3.timestamp, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a jsonb
--! @param b eql_v3.timestamp
--! @return boolean
CREATE FUNCTION eql_v3.lt(a jsonb, b eql_v3.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b eql_v3.timestamp
--! @return boolean
CREATE FUNCTION eql_v3.lte(a eql_v3.timestamp, b eql_v3.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lte(a eql_v3.timestamp, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a jsonb
--! @param b eql_v3.timestamp
--! @return boolean
CREATE FUNCTION eql_v3.lte(a jsonb, b eql_v3.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b eql_v3.timestamp
--! @return boolean
CREATE FUNCTION eql_v3.gt(a eql_v3.timestamp, b eql_v3.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gt(a eql_v3.timestamp, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a jsonb
--! @param b eql_v3.timestamp
--! @return boolean
CREATE FUNCTION eql_v3.gt(a jsonb, b eql_v3.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b eql_v3.timestamp
--! @return boolean
CREATE FUNCTION eql_v3.gte(a eql_v3.timestamp, b eql_v3.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gte(a eql_v3.timestamp, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a jsonb
--! @param b eql_v3.timestamp
--! @return boolean
CREATE FUNCTION eql_v3.gte(a jsonb, b eql_v3.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b eql_v3.timestamp
--! @return boolean
CREATE FUNCTION eql_v3.contains(a eql_v3.timestamp, b eql_v3.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contains(a eql_v3.timestamp, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a jsonb
--! @param b eql_v3.timestamp
--! @return boolean
CREATE FUNCTION eql_v3.contains(a jsonb, b eql_v3.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b eql_v3.timestamp
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a eql_v3.timestamp, b eql_v3.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a eql_v3.timestamp, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a jsonb
--! @param b eql_v3.timestamp
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a jsonb, b eql_v3.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param selector text
--! @return eql_v3.timestamp
CREATE FUNCTION eql_v3."->"(a eql_v3.timestamp, selector text)
RETURNS eql_v3.timestamp IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param selector integer
--! @return eql_v3.timestamp
CREATE FUNCTION eql_v3."->"(a eql_v3.timestamp, selector integer)
RETURNS eql_v3.timestamp IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a jsonb
--! @param selector eql_v3.timestamp
--! @return eql_v3.timestamp
CREATE FUNCTION eql_v3."->"(a jsonb, selector eql_v3.timestamp)
RETURNS eql_v3.timestamp IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3."->>"(a eql_v3.timestamp, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3."->>"(a eql_v3.timestamp, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a jsonb
--! @param selector eql_v3.timestamp
--! @return text
CREATE FUNCTION eql_v3."->>"(a jsonb, selector eql_v3.timestamp)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3."?"(a eql_v3.timestamp, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3."?|"(a eql_v3.timestamp, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3."?&"(a eql_v3.timestamp, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3."@?"(a eql_v3.timestamp, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3."@@"(a eql_v3.timestamp, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."#>"(a eql_v3.timestamp, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3."#>>"(a eql_v3.timestamp, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.timestamp, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.timestamp, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.timestamp, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."#-"(a eql_v3.timestamp, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b eql_v3.timestamp
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a eql_v3.timestamp, b eql_v3.timestamp)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a eql_v3.timestamp
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a eql_v3.timestamp, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamp.
--! @param a jsonb
--! @param b eql_v3.timestamp
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a jsonb, b eql_v3.timestamp)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.timestamp'; END; $$
LANGUAGE plpgsql;
