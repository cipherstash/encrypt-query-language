-- REFERENCE: hand-maintained parity baseline for crates/eql-codegen - see ../README.md
-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/int4/int4_types.sql
-- REQUIRE: src/v3/scalars/functions.sql
-- REQUIRE: src/v3/sem/ore_block_256/functions.sql
-- REQUIRE: src/v3/sem/ore_block_256/operators.sql

--! @file encrypted_domain/int4/int4_ord_functions.sql
--! @brief Functions for eql_v3.int4_ord.

--! @brief Index extractor for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @return eql_v3.ore_block_256
CREATE FUNCTION eql_v3.ord_term(a eql_v3.int4_ord)
RETURNS eql_v3.ore_block_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ore_block_256(a::jsonb) $$;

--! @brief Operator wrapper for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b eql_v3.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.int4_ord, b eql_v3.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b::eql_v3.int4_ord) $$;

--! @brief Operator wrapper for eql_v3.int4_ord.
--! @param a jsonb
--! @param b eql_v3.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a jsonb, b eql_v3.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::eql_v3.int4_ord) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b eql_v3.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.int4_ord, b eql_v3.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b::eql_v3.int4_ord) $$;

--! @brief Operator wrapper for eql_v3.int4_ord.
--! @param a jsonb
--! @param b eql_v3.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a jsonb, b eql_v3.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::eql_v3.int4_ord) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b eql_v3.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a eql_v3.int4_ord, b eql_v3.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lt(a eql_v3.int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b::eql_v3.int4_ord) $$;

--! @brief Operator wrapper for eql_v3.int4_ord.
--! @param a jsonb
--! @param b eql_v3.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a jsonb, b eql_v3.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::eql_v3.int4_ord) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b eql_v3.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a eql_v3.int4_ord, b eql_v3.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lte(a eql_v3.int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b::eql_v3.int4_ord) $$;

--! @brief Operator wrapper for eql_v3.int4_ord.
--! @param a jsonb
--! @param b eql_v3.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a jsonb, b eql_v3.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::eql_v3.int4_ord) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b eql_v3.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a eql_v3.int4_ord, b eql_v3.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gt(a eql_v3.int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b::eql_v3.int4_ord) $$;

--! @brief Operator wrapper for eql_v3.int4_ord.
--! @param a jsonb
--! @param b eql_v3.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a jsonb, b eql_v3.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::eql_v3.int4_ord) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b eql_v3.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a eql_v3.int4_ord, b eql_v3.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gte(a eql_v3.int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b::eql_v3.int4_ord) $$;

--! @brief Operator wrapper for eql_v3.int4_ord.
--! @param a jsonb
--! @param b eql_v3.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a jsonb, b eql_v3.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::eql_v3.int4_ord) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b eql_v3.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.contains(a eql_v3.int4_ord, b eql_v3.int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contains(a eql_v3.int4_ord, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a jsonb
--! @param b eql_v3.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.contains(a jsonb, b eql_v3.int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b eql_v3.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a eql_v3.int4_ord, b eql_v3.int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a eql_v3.int4_ord, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a jsonb
--! @param b eql_v3.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a jsonb, b eql_v3.int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param selector text
--! @return eql_v3.int4_ord
CREATE FUNCTION eql_v3."->"(a eql_v3.int4_ord, selector text)
RETURNS eql_v3.int4_ord IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param selector integer
--! @return eql_v3.int4_ord
CREATE FUNCTION eql_v3."->"(a eql_v3.int4_ord, selector integer)
RETURNS eql_v3.int4_ord IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a jsonb
--! @param selector eql_v3.int4_ord
--! @return eql_v3.int4_ord
CREATE FUNCTION eql_v3."->"(a jsonb, selector eql_v3.int4_ord)
RETURNS eql_v3.int4_ord IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3."->>"(a eql_v3.int4_ord, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3."->>"(a eql_v3.int4_ord, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a jsonb
--! @param selector eql_v3.int4_ord
--! @return text
CREATE FUNCTION eql_v3."->>"(a jsonb, selector eql_v3.int4_ord)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3."?"(a eql_v3.int4_ord, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3."?|"(a eql_v3.int4_ord, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3."?&"(a eql_v3.int4_ord, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3."@?"(a eql_v3.int4_ord, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3."@@"(a eql_v3.int4_ord, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."#>"(a eql_v3.int4_ord, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3."#>>"(a eql_v3.int4_ord, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.int4_ord, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.int4_ord, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.int4_ord, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."#-"(a eql_v3.int4_ord, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b eql_v3.int4_ord
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a eql_v3.int4_ord, b eql_v3.int4_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a eql_v3.int4_ord
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a eql_v3.int4_ord, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.int4_ord.
--! @param a jsonb
--! @param b eql_v3.int4_ord
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a jsonb, b eql_v3.int4_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.int4_ord'; END; $$
LANGUAGE plpgsql;
