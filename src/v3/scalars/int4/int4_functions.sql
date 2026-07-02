-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/int4/int4_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/int4/int4_functions.sql
--! @brief Functions for eql_v3.int4.

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.int4, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.int4, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.int4, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.int4, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.int4, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.int4, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a eql_v3.int4, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a eql_v3.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a eql_v3.int4, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a eql_v3.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param b eql_v3.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b eql_v3.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param selector text
--! @return eql_v3.int4
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.int4, selector text)
RETURNS eql_v3.int4 IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param selector integer
--! @return eql_v3.int4
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.int4, selector integer)
RETURNS eql_v3.int4 IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param selector eql_v3.int4
--! @return eql_v3.int4
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector eql_v3.int4)
RETURNS eql_v3.int4 IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.int4, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.int4, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param selector eql_v3.int4
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector eql_v3.int4)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a eql_v3.int4, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a eql_v3.int4, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a eql_v3.int4, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a eql_v3.int4, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a eql_v3.int4, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a eql_v3.int4, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a eql_v3.int4, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.int4, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.int4, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.int4, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a eql_v3.int4, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b eql_v3.int4
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.int4, b eql_v3.int4)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a eql_v3.int4
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.int4, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4.
--! @param a jsonb
--! @param b eql_v3.int4
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b eql_v3.int4)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.int4'; END; $$
LANGUAGE plpgsql;
