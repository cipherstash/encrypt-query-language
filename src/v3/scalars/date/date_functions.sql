-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/date/date_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/date/date_functions.sql
--! @brief Functions for eql_v3.date.

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b eql_v3.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.date, b eql_v3.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.date, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a jsonb
--! @param b eql_v3.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b eql_v3.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b eql_v3.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.date, b eql_v3.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.date, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a jsonb
--! @param b eql_v3.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b eql_v3.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b eql_v3.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.date, b eql_v3.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.date, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a jsonb
--! @param b eql_v3.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b eql_v3.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b eql_v3.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.date, b eql_v3.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.date, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a jsonb
--! @param b eql_v3.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b eql_v3.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b eql_v3.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.date, b eql_v3.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.date, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a jsonb
--! @param b eql_v3.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b eql_v3.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b eql_v3.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.date, b eql_v3.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.date, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a jsonb
--! @param b eql_v3.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b eql_v3.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b eql_v3.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a eql_v3.date, b eql_v3.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a eql_v3.date, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a jsonb
--! @param b eql_v3.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b eql_v3.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b eql_v3.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a eql_v3.date, b eql_v3.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a eql_v3.date, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a jsonb
--! @param b eql_v3.date
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b eql_v3.date)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param selector text
--! @return eql_v3.date
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.date, selector text)
RETURNS eql_v3.date IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param selector integer
--! @return eql_v3.date
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.date, selector integer)
RETURNS eql_v3.date IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a jsonb
--! @param selector eql_v3.date
--! @return eql_v3.date
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector eql_v3.date)
RETURNS eql_v3.date IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.date, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.date, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a jsonb
--! @param selector eql_v3.date
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector eql_v3.date)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a eql_v3.date, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a eql_v3.date, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a eql_v3.date, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a eql_v3.date, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a eql_v3.date, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a eql_v3.date, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a eql_v3.date, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.date, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.date, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.date, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a eql_v3.date, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b eql_v3.date
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.date, b eql_v3.date)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a eql_v3.date
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.date, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.date.
--! @param a jsonb
--! @param b eql_v3.date
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b eql_v3.date)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.date'; END; $$
LANGUAGE plpgsql;
