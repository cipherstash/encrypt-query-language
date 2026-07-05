-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/real/real_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/real/real_functions.sql
--! @brief Functions for public.real.

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.real, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.real, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a jsonb
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.real, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.real, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a jsonb
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.real, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.real, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a jsonb
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.real, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.real, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a jsonb
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.real, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.real, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a jsonb
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.real, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.real, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a jsonb
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.real, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.real, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a jsonb
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.real, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.real, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a jsonb
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param selector text
--! @return public.real
CREATE FUNCTION eql_v3_internal."->"(a public.real, selector text)
RETURNS public.real IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param selector integer
--! @return public.real
CREATE FUNCTION eql_v3_internal."->"(a public.real, selector integer)
RETURNS public.real IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a jsonb
--! @param selector public.real
--! @return public.real
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.real)
RETURNS public.real IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.real, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.real, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a jsonb
--! @param selector public.real
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.real)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.real, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.real, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.real, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.real, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.real, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.real, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.real, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.real, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.real, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.real, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.real, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b public.real
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.real, b public.real)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.real, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a jsonb
--! @param b public.real
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.real)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.real'; END; $$
LANGUAGE plpgsql;
