-- REFERENCE: hand-written parity baseline for crates/eql-codegen — see ../README.md
-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/schema.sql
-- REQUIRE: src/schema-v3.sql
-- REQUIRE: src/encrypted_domain/int4/int4_types.sql
-- REQUIRE: src/encrypted_domain/functions.sql
-- REQUIRE: src/hmac_256/functions.sql

--! @file encrypted_domain/int4/int4_eq_functions.sql
--! @brief Functions for eql_v3.int4_eq.

--! @brief Index extractor for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @return eql_v2.hmac_256
CREATE FUNCTION eql_v3.eq_term(a eql_v3.int4_eq)
RETURNS eql_v2.hmac_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) $$;

--! @brief Operator wrapper for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b eql_v3.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.int4_eq, b eql_v3.int4_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.int4_eq, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b::eql_v3.int4_eq) $$;

--! @brief Operator wrapper for eql_v3.int4_eq.
--! @param a jsonb
--! @param b eql_v3.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a jsonb, b eql_v3.int4_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a::eql_v3.int4_eq) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b eql_v3.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.int4_eq, b eql_v3.int4_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.int4_eq, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b::eql_v3.int4_eq) $$;

--! @brief Operator wrapper for eql_v3.int4_eq.
--! @param a jsonb
--! @param b eql_v3.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a jsonb, b eql_v3.int4_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a::eql_v3.int4_eq) <> eql_v3.eq_term(b) $$;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b eql_v3.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3.lt(a eql_v3.int4_eq, b eql_v3.int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lt(a eql_v3.int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a jsonb
--! @param b eql_v3.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3.lt(a jsonb, b eql_v3.int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b eql_v3.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3.lte(a eql_v3.int4_eq, b eql_v3.int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lte(a eql_v3.int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a jsonb
--! @param b eql_v3.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3.lte(a jsonb, b eql_v3.int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b eql_v3.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3.gt(a eql_v3.int4_eq, b eql_v3.int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gt(a eql_v3.int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a jsonb
--! @param b eql_v3.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3.gt(a jsonb, b eql_v3.int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b eql_v3.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3.gte(a eql_v3.int4_eq, b eql_v3.int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gte(a eql_v3.int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a jsonb
--! @param b eql_v3.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3.gte(a jsonb, b eql_v3.int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b eql_v3.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3.contains(a eql_v3.int4_eq, b eql_v3.int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contains(a eql_v3.int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a jsonb
--! @param b eql_v3.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3.contains(a jsonb, b eql_v3.int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b eql_v3.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a eql_v3.int4_eq, b eql_v3.int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a eql_v3.int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a jsonb
--! @param b eql_v3.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a jsonb, b eql_v3.int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param selector text
--! @return eql_v3.int4_eq
CREATE FUNCTION eql_v3."->"(a eql_v3.int4_eq, selector text)
RETURNS eql_v3.int4_eq IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param selector integer
--! @return eql_v3.int4_eq
CREATE FUNCTION eql_v3."->"(a eql_v3.int4_eq, selector integer)
RETURNS eql_v3.int4_eq IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a jsonb
--! @param selector eql_v3.int4_eq
--! @return eql_v3.int4_eq
CREATE FUNCTION eql_v3."->"(a jsonb, selector eql_v3.int4_eq)
RETURNS eql_v3.int4_eq IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3."->>"(a eql_v3.int4_eq, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3."->>"(a eql_v3.int4_eq, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a jsonb
--! @param selector eql_v3.int4_eq
--! @return text
CREATE FUNCTION eql_v3."->>"(a jsonb, selector eql_v3.int4_eq)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3."?"(a eql_v3.int4_eq, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3."?|"(a eql_v3.int4_eq, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3."?&"(a eql_v3.int4_eq, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3."@?"(a eql_v3.int4_eq, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3."@@"(a eql_v3.int4_eq, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."#>"(a eql_v3.int4_eq, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3."#>>"(a eql_v3.int4_eq, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.int4_eq, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.int4_eq, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.int4_eq, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."#-"(a eql_v3.int4_eq, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b eql_v3.int4_eq
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a eql_v3.int4_eq, b eql_v3.int4_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a eql_v3.int4_eq
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a eql_v3.int4_eq, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_eq.
--! @param a jsonb
--! @param b eql_v3.int4_eq
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a jsonb, b eql_v3.int4_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.int4_eq'; END; $$
LANGUAGE plpgsql;
