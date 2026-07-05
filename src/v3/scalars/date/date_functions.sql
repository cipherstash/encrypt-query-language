-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/date/date_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/date/date_functions.sql
--! @brief Functions for public.date.

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b public.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.date, b public.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.date, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a jsonb
--! @param b public.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b public.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b public.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.date, b public.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.date, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a jsonb
--! @param b public.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b public.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b public.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.date, b public.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.date, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a jsonb
--! @param b public.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b public.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.date, b public.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.date, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a jsonb
--! @param b public.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b public.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.date, b public.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.date, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a jsonb
--! @param b public.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b public.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.date, b public.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.date, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a jsonb
--! @param b public.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b public.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.date, b public.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.date, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a jsonb
--! @param b public.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b public.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.date, b public.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.date, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a jsonb
--! @param b public.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param selector text
--! @return public.date
CREATE FUNCTION eql_v3_internal."->"(a public.date, selector text)
RETURNS public.date IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param selector integer
--! @return public.date
CREATE FUNCTION eql_v3_internal."->"(a public.date, selector integer)
RETURNS public.date IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a jsonb
--! @param selector public.date
--! @return public.date
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.date)
RETURNS public.date IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.date, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.date, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a jsonb
--! @param selector public.date
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.date)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.date, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.date, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.date, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.date, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.date, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.date, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.date, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.date, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.date, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.date, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.date, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b public.date
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.date, b public.date)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a public.date
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.date, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.date.
--! @param a jsonb
--! @param b public.date
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.date)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.date'; END; $$
LANGUAGE plpgsql;
