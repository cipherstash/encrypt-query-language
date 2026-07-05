-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/boolean/boolean_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/boolean/boolean_functions.sql
--! @brief Functions for public.boolean.

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b public.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.boolean, b public.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a jsonb
--! @param b public.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b public.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b public.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.boolean, b public.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a jsonb
--! @param b public.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b public.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b public.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.boolean, b public.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a jsonb
--! @param b public.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b public.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.boolean, b public.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a jsonb
--! @param b public.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b public.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.boolean, b public.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a jsonb
--! @param b public.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b public.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.boolean, b public.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a jsonb
--! @param b public.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b public.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.boolean, b public.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a jsonb
--! @param b public.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b public.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.boolean, b public.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a jsonb
--! @param b public.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param selector text
--! @return public.boolean
CREATE FUNCTION eql_v3_internal."->"(a public.boolean, selector text)
RETURNS public.boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param selector integer
--! @return public.boolean
CREATE FUNCTION eql_v3_internal."->"(a public.boolean, selector integer)
RETURNS public.boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a jsonb
--! @param selector public.boolean
--! @return public.boolean
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.boolean)
RETURNS public.boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.boolean, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.boolean, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a jsonb
--! @param selector public.boolean
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.boolean)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.boolean, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.boolean, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.boolean, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.boolean, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.boolean, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.boolean, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.boolean, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.boolean, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.boolean, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.boolean, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.boolean, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b public.boolean
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.boolean, b public.boolean)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a public.boolean
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.boolean, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.boolean.
--! @param a jsonb
--! @param b public.boolean
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.boolean)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.boolean'; END; $$
LANGUAGE plpgsql;
