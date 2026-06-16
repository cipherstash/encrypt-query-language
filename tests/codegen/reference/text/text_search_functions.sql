-- REFERENCE: hand-maintained parity baseline for crates/eql-codegen - see ../README.md
-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/text/text_types.sql
-- REQUIRE: src/v3/scalars/functions.sql
-- REQUIRE: src/v3/sem/hmac_256/functions.sql
-- REQUIRE: src/v3/sem/ore_block_256/functions.sql
-- REQUIRE: src/v3/sem/ore_block_256/operators.sql
-- REQUIRE: src/v3/sem/bloom_filter/functions.sql

--! @file encrypted_domain/text/text_search_functions.sql
--! @brief Functions for eql_v3.text_search.

--! @brief Index extractor for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @return eql_v3.hmac_256
CREATE FUNCTION eql_v3.eq_term(a eql_v3.text_search)
RETURNS eql_v3.hmac_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.hmac_256(a::jsonb) $$;

--! @brief Index extractor for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @return eql_v3.ore_block_256
CREATE FUNCTION eql_v3.ord_term(a eql_v3.text_search)
RETURNS eql_v3.ore_block_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ore_block_256(a::jsonb) $$;

--! @brief Index extractor for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @return eql_v3.bloom_filter
CREATE FUNCTION eql_v3.match_term(a eql_v3.text_search)
RETURNS eql_v3.bloom_filter
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.bloom_filter(a::jsonb) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b eql_v3.text_search
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.text_search, b eql_v3.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.text_search, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b::eql_v3.text_search) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a jsonb
--! @param b eql_v3.text_search
--! @return boolean
CREATE FUNCTION eql_v3.eq(a jsonb, b eql_v3.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a::eql_v3.text_search) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b eql_v3.text_search
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.text_search, b eql_v3.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.text_search, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b::eql_v3.text_search) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a jsonb
--! @param b eql_v3.text_search
--! @return boolean
CREATE FUNCTION eql_v3.neq(a jsonb, b eql_v3.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a::eql_v3.text_search) <> eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b eql_v3.text_search
--! @return boolean
CREATE FUNCTION eql_v3.lt(a eql_v3.text_search, b eql_v3.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lt(a eql_v3.text_search, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b::eql_v3.text_search) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a jsonb
--! @param b eql_v3.text_search
--! @return boolean
CREATE FUNCTION eql_v3.lt(a jsonb, b eql_v3.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::eql_v3.text_search) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b eql_v3.text_search
--! @return boolean
CREATE FUNCTION eql_v3.lte(a eql_v3.text_search, b eql_v3.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lte(a eql_v3.text_search, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b::eql_v3.text_search) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a jsonb
--! @param b eql_v3.text_search
--! @return boolean
CREATE FUNCTION eql_v3.lte(a jsonb, b eql_v3.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::eql_v3.text_search) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b eql_v3.text_search
--! @return boolean
CREATE FUNCTION eql_v3.gt(a eql_v3.text_search, b eql_v3.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gt(a eql_v3.text_search, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b::eql_v3.text_search) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a jsonb
--! @param b eql_v3.text_search
--! @return boolean
CREATE FUNCTION eql_v3.gt(a jsonb, b eql_v3.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::eql_v3.text_search) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b eql_v3.text_search
--! @return boolean
CREATE FUNCTION eql_v3.gte(a eql_v3.text_search, b eql_v3.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gte(a eql_v3.text_search, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b::eql_v3.text_search) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a jsonb
--! @param b eql_v3.text_search
--! @return boolean
CREATE FUNCTION eql_v3.gte(a jsonb, b eql_v3.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::eql_v3.text_search) >= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b eql_v3.text_search
--! @return boolean
CREATE FUNCTION eql_v3.contains(a eql_v3.text_search, b eql_v3.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) @> eql_v3.match_term(b) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contains(a eql_v3.text_search, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) @> eql_v3.match_term(b::eql_v3.text_search) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a jsonb
--! @param b eql_v3.text_search
--! @return boolean
CREATE FUNCTION eql_v3.contains(a jsonb, b eql_v3.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a::eql_v3.text_search) @> eql_v3.match_term(b) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b eql_v3.text_search
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a eql_v3.text_search, b eql_v3.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) <@ eql_v3.match_term(b) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a eql_v3.text_search, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) <@ eql_v3.match_term(b::eql_v3.text_search) $$;

--! @brief Operator wrapper for eql_v3.text_search.
--! @param a jsonb
--! @param b eql_v3.text_search
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a jsonb, b eql_v3.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a::eql_v3.text_search) <@ eql_v3.match_term(b) $$;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param selector text
--! @return eql_v3.text_search
CREATE FUNCTION eql_v3."->"(a eql_v3.text_search, selector text)
RETURNS eql_v3.text_search IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param selector integer
--! @return eql_v3.text_search
CREATE FUNCTION eql_v3."->"(a eql_v3.text_search, selector integer)
RETURNS eql_v3.text_search IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a jsonb
--! @param selector eql_v3.text_search
--! @return eql_v3.text_search
CREATE FUNCTION eql_v3."->"(a jsonb, selector eql_v3.text_search)
RETURNS eql_v3.text_search IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3."->>"(a eql_v3.text_search, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3."->>"(a eql_v3.text_search, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a jsonb
--! @param selector eql_v3.text_search
--! @return text
CREATE FUNCTION eql_v3."->>"(a jsonb, selector eql_v3.text_search)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3."?"(a eql_v3.text_search, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3."?|"(a eql_v3.text_search, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3."?&"(a eql_v3.text_search, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3."@?"(a eql_v3.text_search, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3."@@"(a eql_v3.text_search, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."#>"(a eql_v3.text_search, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3."#>>"(a eql_v3.text_search, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.text_search, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.text_search, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.text_search, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."#-"(a eql_v3.text_search, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b eql_v3.text_search
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a eql_v3.text_search, b eql_v3.text_search)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a eql_v3.text_search
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a eql_v3.text_search, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_search.
--! @param a jsonb
--! @param b eql_v3.text_search
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a jsonb, b eql_v3.text_search)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.text_search'; END; $$
LANGUAGE plpgsql;
