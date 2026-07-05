-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/double/double_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/double/double_functions.sql
--! @brief Functions for public.double.

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.double, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.double, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a jsonb
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.double, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.double, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a jsonb
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.double, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.double, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a jsonb
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.double, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.double, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a jsonb
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.double, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.double, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a jsonb
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.double, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.double, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a jsonb
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.double, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.double, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a jsonb
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.double, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.double, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a jsonb
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param selector text
--! @return public.double
CREATE FUNCTION eql_v3_internal."->"(a public.double, selector text)
RETURNS public.double IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param selector integer
--! @return public.double
CREATE FUNCTION eql_v3_internal."->"(a public.double, selector integer)
RETURNS public.double IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a jsonb
--! @param selector public.double
--! @return public.double
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.double)
RETURNS public.double IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.double, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.double, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a jsonb
--! @param selector public.double
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.double)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.double, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.double, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.double, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.double, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.double, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.double, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.double, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.double, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.double, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.double, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.double, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b public.double
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.double, b public.double)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.double, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a jsonb
--! @param b public.double
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.double)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.double'; END; $$
LANGUAGE plpgsql;
