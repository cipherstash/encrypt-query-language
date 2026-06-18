-- REFERENCE: hand-maintained parity baseline for crates/eql-codegen - see ../README.md
-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/bool/bool_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/bool/bool_functions.sql
--! @brief Functions for eql_v3.bool.

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b eql_v3.bool
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.bool, b eql_v3.bool)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.bool, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a jsonb
--! @param b eql_v3.bool
--! @return boolean
CREATE FUNCTION eql_v3.eq(a jsonb, b eql_v3.bool)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b eql_v3.bool
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.bool, b eql_v3.bool)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.bool, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a jsonb
--! @param b eql_v3.bool
--! @return boolean
CREATE FUNCTION eql_v3.neq(a jsonb, b eql_v3.bool)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b eql_v3.bool
--! @return boolean
CREATE FUNCTION eql_v3.lt(a eql_v3.bool, b eql_v3.bool)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lt(a eql_v3.bool, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a jsonb
--! @param b eql_v3.bool
--! @return boolean
CREATE FUNCTION eql_v3.lt(a jsonb, b eql_v3.bool)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b eql_v3.bool
--! @return boolean
CREATE FUNCTION eql_v3.lte(a eql_v3.bool, b eql_v3.bool)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lte(a eql_v3.bool, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a jsonb
--! @param b eql_v3.bool
--! @return boolean
CREATE FUNCTION eql_v3.lte(a jsonb, b eql_v3.bool)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b eql_v3.bool
--! @return boolean
CREATE FUNCTION eql_v3.gt(a eql_v3.bool, b eql_v3.bool)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gt(a eql_v3.bool, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a jsonb
--! @param b eql_v3.bool
--! @return boolean
CREATE FUNCTION eql_v3.gt(a jsonb, b eql_v3.bool)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b eql_v3.bool
--! @return boolean
CREATE FUNCTION eql_v3.gte(a eql_v3.bool, b eql_v3.bool)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gte(a eql_v3.bool, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a jsonb
--! @param b eql_v3.bool
--! @return boolean
CREATE FUNCTION eql_v3.gte(a jsonb, b eql_v3.bool)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b eql_v3.bool
--! @return boolean
CREATE FUNCTION eql_v3.contains(a eql_v3.bool, b eql_v3.bool)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contains(a eql_v3.bool, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a jsonb
--! @param b eql_v3.bool
--! @return boolean
CREATE FUNCTION eql_v3.contains(a jsonb, b eql_v3.bool)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b eql_v3.bool
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a eql_v3.bool, b eql_v3.bool)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a eql_v3.bool, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a jsonb
--! @param b eql_v3.bool
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a jsonb, b eql_v3.bool)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param selector text
--! @return eql_v3.bool
CREATE FUNCTION eql_v3."->"(a eql_v3.bool, selector text)
RETURNS eql_v3.bool IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param selector integer
--! @return eql_v3.bool
CREATE FUNCTION eql_v3."->"(a eql_v3.bool, selector integer)
RETURNS eql_v3.bool IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a jsonb
--! @param selector eql_v3.bool
--! @return eql_v3.bool
CREATE FUNCTION eql_v3."->"(a jsonb, selector eql_v3.bool)
RETURNS eql_v3.bool IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3."->>"(a eql_v3.bool, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3."->>"(a eql_v3.bool, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a jsonb
--! @param selector eql_v3.bool
--! @return text
CREATE FUNCTION eql_v3."->>"(a jsonb, selector eql_v3.bool)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3."?"(a eql_v3.bool, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3."?|"(a eql_v3.bool, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3."?&"(a eql_v3.bool, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3."@?"(a eql_v3.bool, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3."@@"(a eql_v3.bool, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."#>"(a eql_v3.bool, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3."#>>"(a eql_v3.bool, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.bool, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.bool, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.bool, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."#-"(a eql_v3.bool, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b eql_v3.bool
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a eql_v3.bool, b eql_v3.bool)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a eql_v3.bool
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a eql_v3.bool, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bool.
--! @param a jsonb
--! @param b eql_v3.bool
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a jsonb, b eql_v3.bool)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.bool'; END; $$
LANGUAGE plpgsql;
