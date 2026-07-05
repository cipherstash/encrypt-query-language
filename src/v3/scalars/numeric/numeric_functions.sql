-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/numeric/numeric_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/numeric/numeric_functions.sql
--! @brief Functions for public.numeric.

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.numeric, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.numeric, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a jsonb
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.numeric, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.numeric, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a jsonb
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.numeric, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.numeric, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a jsonb
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.numeric, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.numeric, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a jsonb
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.numeric, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.numeric, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a jsonb
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.numeric, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.numeric, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a jsonb
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.numeric, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.numeric, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a jsonb
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.numeric, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.numeric, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a jsonb
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param selector text
--! @return public.numeric
CREATE FUNCTION eql_v3_internal."->"(a public.numeric, selector text)
RETURNS public.numeric IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param selector integer
--! @return public.numeric
CREATE FUNCTION eql_v3_internal."->"(a public.numeric, selector integer)
RETURNS public.numeric IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a jsonb
--! @param selector public.numeric
--! @return public.numeric
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.numeric)
RETURNS public.numeric IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.numeric, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.numeric, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a jsonb
--! @param selector public.numeric
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.numeric)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.numeric, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.numeric, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.numeric, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.numeric, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.numeric, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.numeric, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.numeric, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.numeric, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.numeric, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.numeric, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.numeric, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b public.numeric
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.numeric, b public.numeric)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.numeric, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a jsonb
--! @param b public.numeric
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.numeric)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.numeric'; END; $$
LANGUAGE plpgsql;
