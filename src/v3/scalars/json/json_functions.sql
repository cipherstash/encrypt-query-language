-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/json/json_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/json/json_functions.sql
--! @brief Functions for public.eql_v3_json.

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.eql_v3_json, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.eql_v3_json, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.eql_v3_json, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.eql_v3_json, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.eql_v3_json, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.eql_v3_json, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.eql_v3_json, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.eql_v3_json, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.eql_v3_json, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.eql_v3_json, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.eql_v3_json, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.eql_v3_json, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.eql_v3_json, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.eql_v3_json, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.eql_v3_json, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.eql_v3_json, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param selector text
--! @return public.eql_v3_json
CREATE FUNCTION eql_v3_internal."->"(a public.eql_v3_json, selector text)
RETURNS public.eql_v3_json IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param selector integer
--! @return public.eql_v3_json
CREATE FUNCTION eql_v3_internal."->"(a public.eql_v3_json, selector integer)
RETURNS public.eql_v3_json IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param selector public.eql_v3_json
--! @return public.eql_v3_json
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.eql_v3_json)
RETURNS public.eql_v3_json IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.eql_v3_json, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.eql_v3_json, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param selector public.eql_v3_json
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.eql_v3_json)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.eql_v3_json, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.eql_v3_json, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.eql_v3_json, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.eql_v3_json, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.eql_v3_json, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.eql_v3_json, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.eql_v3_json, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_json, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_json, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_json, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.eql_v3_json, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b public.eql_v3_json
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.eql_v3_json, b public.eql_v3_json)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.eql_v3_json, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param b public.eql_v3_json
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.eql_v3_json)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;
