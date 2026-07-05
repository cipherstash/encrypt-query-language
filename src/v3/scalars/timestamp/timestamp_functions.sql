-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/timestamp/timestamp_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/timestamp/timestamp_functions.sql
--! @brief Functions for public.timestamp.

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b public.timestamp
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.timestamp, b public.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.timestamp, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a jsonb
--! @param b public.timestamp
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b public.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b public.timestamp
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.timestamp, b public.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.timestamp, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a jsonb
--! @param b public.timestamp
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b public.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b public.timestamp
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.timestamp, b public.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.timestamp, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a jsonb
--! @param b public.timestamp
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b public.timestamp
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.timestamp, b public.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.timestamp, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a jsonb
--! @param b public.timestamp
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b public.timestamp
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.timestamp, b public.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.timestamp, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a jsonb
--! @param b public.timestamp
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b public.timestamp
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.timestamp, b public.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.timestamp, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a jsonb
--! @param b public.timestamp
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b public.timestamp
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.timestamp, b public.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.timestamp, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a jsonb
--! @param b public.timestamp
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b public.timestamp
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.timestamp, b public.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.timestamp, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a jsonb
--! @param b public.timestamp
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.timestamp)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param selector text
--! @return public.timestamp
CREATE FUNCTION eql_v3_internal."->"(a public.timestamp, selector text)
RETURNS public.timestamp IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param selector integer
--! @return public.timestamp
CREATE FUNCTION eql_v3_internal."->"(a public.timestamp, selector integer)
RETURNS public.timestamp IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a jsonb
--! @param selector public.timestamp
--! @return public.timestamp
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.timestamp)
RETURNS public.timestamp IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.timestamp, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.timestamp, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a jsonb
--! @param selector public.timestamp
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.timestamp)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.timestamp, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.timestamp, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.timestamp, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.timestamp, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.timestamp, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.timestamp, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.timestamp, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.timestamp, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.timestamp, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.timestamp, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.timestamp, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b public.timestamp
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.timestamp, b public.timestamp)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a public.timestamp
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.timestamp, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.timestamp'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.timestamp.
--! @param a jsonb
--! @param b public.timestamp
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.timestamp)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.timestamp'; END; $$
LANGUAGE plpgsql;
