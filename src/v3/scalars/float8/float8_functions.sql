-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/float8/float8_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/float8/float8_functions.sql
--! @brief Functions for public.float8.

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.float8, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.float8, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a jsonb
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.float8, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.float8, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a jsonb
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.float8, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.float8, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a jsonb
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.float8, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.float8, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a jsonb
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.float8, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.float8, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a jsonb
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.float8, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.float8, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a jsonb
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.float8, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.float8, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a jsonb
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.float8, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.float8, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a jsonb
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param selector text
--! @return public.float8
CREATE FUNCTION eql_v3_internal."->"(a public.float8, selector text)
RETURNS public.float8 IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param selector integer
--! @return public.float8
CREATE FUNCTION eql_v3_internal."->"(a public.float8, selector integer)
RETURNS public.float8 IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a jsonb
--! @param selector public.float8
--! @return public.float8
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.float8)
RETURNS public.float8 IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.float8, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.float8, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a jsonb
--! @param selector public.float8
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.float8)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.float8, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.float8, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.float8, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.float8, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.float8, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.float8, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.float8, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.float8, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.float8, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.float8, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.float8, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b public.float8
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.float8, b public.float8)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.float8, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a jsonb
--! @param b public.float8
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.float8)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.float8'; END; $$
LANGUAGE plpgsql;
