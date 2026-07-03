-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/integer/integer_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/integer/integer_functions.sql
--! @brief Functions for eql_v3.integer.

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b eql_v3.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.integer, b eql_v3.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.integer, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a jsonb
--! @param b eql_v3.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b eql_v3.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b eql_v3.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.integer, b eql_v3.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.integer, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a jsonb
--! @param b eql_v3.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b eql_v3.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b eql_v3.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.integer, b eql_v3.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.integer, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a jsonb
--! @param b eql_v3.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b eql_v3.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b eql_v3.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.integer, b eql_v3.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.integer, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a jsonb
--! @param b eql_v3.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b eql_v3.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b eql_v3.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.integer, b eql_v3.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.integer, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a jsonb
--! @param b eql_v3.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b eql_v3.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b eql_v3.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.integer, b eql_v3.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.integer, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a jsonb
--! @param b eql_v3.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b eql_v3.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b eql_v3.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a eql_v3.integer, b eql_v3.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a eql_v3.integer, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a jsonb
--! @param b eql_v3.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b eql_v3.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b eql_v3.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a eql_v3.integer, b eql_v3.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a eql_v3.integer, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a jsonb
--! @param b eql_v3.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b eql_v3.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param selector text
--! @return eql_v3.integer
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.integer, selector text)
RETURNS eql_v3.integer IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param selector integer
--! @return eql_v3.integer
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.integer, selector integer)
RETURNS eql_v3.integer IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a jsonb
--! @param selector eql_v3.integer
--! @return eql_v3.integer
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector eql_v3.integer)
RETURNS eql_v3.integer IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.integer, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.integer, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a jsonb
--! @param selector eql_v3.integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector eql_v3.integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a eql_v3.integer, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a eql_v3.integer, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a eql_v3.integer, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a eql_v3.integer, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a eql_v3.integer, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a eql_v3.integer, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a eql_v3.integer, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.integer, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.integer, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.integer, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a eql_v3.integer, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b eql_v3.integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.integer, b eql_v3.integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a eql_v3.integer
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.integer, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.integer.
--! @param a jsonb
--! @param b eql_v3.integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b eql_v3.integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.integer'; END; $$
LANGUAGE plpgsql;
