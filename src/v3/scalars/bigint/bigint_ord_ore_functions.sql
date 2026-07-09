-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_types.sql
-- REQUIRE: src/v3/scalars/functions.sql
-- REQUIRE: src/v3/sem/ore_block_256/functions.sql
-- REQUIRE: src/v3/sem/ore_block_256/operators.sql

--! @file encrypted_domain/bigint/bigint_ord_ore_functions.sql
--! @brief Functions for public.eql_v3_bigint_ord_ore.

--! @brief Index extractor for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @return eql_v3_internal.ore_block_256
CREATE FUNCTION eql_v3.ord_term(a public.eql_v3_bigint_ord_ore)
RETURNS eql_v3_internal.ore_block_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.ore_block_256(a::jsonb) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b public.eql_v3_bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.eql_v3_bigint_ord_ore, b public.eql_v3_bigint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.eql_v3_bigint_ord_ore, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b::public.eql_v3_bigint_ord_ore) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord_ore.
--! @param a jsonb
--! @param b public.eql_v3_bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.eq(a jsonb, b public.eql_v3_bigint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.eql_v3_bigint_ord_ore) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b public.eql_v3_bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.eql_v3_bigint_ord_ore, b public.eql_v3_bigint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.eql_v3_bigint_ord_ore, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b::public.eql_v3_bigint_ord_ore) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord_ore.
--! @param a jsonb
--! @param b public.eql_v3_bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.neq(a jsonb, b public.eql_v3_bigint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.eql_v3_bigint_ord_ore) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b public.eql_v3_bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.eql_v3_bigint_ord_ore, b public.eql_v3_bigint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.eql_v3_bigint_ord_ore, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b::public.eql_v3_bigint_ord_ore) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord_ore.
--! @param a jsonb
--! @param b public.eql_v3_bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lt(a jsonb, b public.eql_v3_bigint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.eql_v3_bigint_ord_ore) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b public.eql_v3_bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.eql_v3_bigint_ord_ore, b public.eql_v3_bigint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.eql_v3_bigint_ord_ore, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b::public.eql_v3_bigint_ord_ore) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord_ore.
--! @param a jsonb
--! @param b public.eql_v3_bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lte(a jsonb, b public.eql_v3_bigint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.eql_v3_bigint_ord_ore) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b public.eql_v3_bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.eql_v3_bigint_ord_ore, b public.eql_v3_bigint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.eql_v3_bigint_ord_ore, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b::public.eql_v3_bigint_ord_ore) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord_ore.
--! @param a jsonb
--! @param b public.eql_v3_bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gt(a jsonb, b public.eql_v3_bigint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.eql_v3_bigint_ord_ore) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b public.eql_v3_bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.eql_v3_bigint_ord_ore, b public.eql_v3_bigint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.eql_v3_bigint_ord_ore, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b::public.eql_v3_bigint_ord_ore) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord_ore.
--! @param a jsonb
--! @param b public.eql_v3_bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gte(a jsonb, b public.eql_v3_bigint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.eql_v3_bigint_ord_ore) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b public.eql_v3_bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.eql_v3_bigint_ord_ore, b public.eql_v3_bigint_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.eql_v3_bigint_ord_ore, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a jsonb
--! @param b public.eql_v3_bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.eql_v3_bigint_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b public.eql_v3_bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.eql_v3_bigint_ord_ore, b public.eql_v3_bigint_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.eql_v3_bigint_ord_ore, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a jsonb
--! @param b public.eql_v3_bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.eql_v3_bigint_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param selector text
--! @return public.eql_v3_bigint_ord_ore
CREATE FUNCTION eql_v3_internal."->"(a public.eql_v3_bigint_ord_ore, selector text)
RETURNS public.eql_v3_bigint_ord_ore IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param selector integer
--! @return public.eql_v3_bigint_ord_ore
CREATE FUNCTION eql_v3_internal."->"(a public.eql_v3_bigint_ord_ore, selector integer)
RETURNS public.eql_v3_bigint_ord_ore IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a jsonb
--! @param selector public.eql_v3_bigint_ord_ore
--! @return public.eql_v3_bigint_ord_ore
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.eql_v3_bigint_ord_ore)
RETURNS public.eql_v3_bigint_ord_ore IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.eql_v3_bigint_ord_ore, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.eql_v3_bigint_ord_ore, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a jsonb
--! @param selector public.eql_v3_bigint_ord_ore
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.eql_v3_bigint_ord_ore)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.eql_v3_bigint_ord_ore, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.eql_v3_bigint_ord_ore, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.eql_v3_bigint_ord_ore, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.eql_v3_bigint_ord_ore, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.eql_v3_bigint_ord_ore, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.eql_v3_bigint_ord_ore, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.eql_v3_bigint_ord_ore, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_bigint_ord_ore, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_bigint_ord_ore, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_bigint_ord_ore, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.eql_v3_bigint_ord_ore, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b public.eql_v3_bigint_ord_ore
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.eql_v3_bigint_ord_ore, b public.eql_v3_bigint_ord_ore)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a public.eql_v3_bigint_ord_ore
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.eql_v3_bigint_ord_ore, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord_ore.
--! @param a jsonb
--! @param b public.eql_v3_bigint_ord_ore
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.eql_v3_bigint_ord_ore)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_bigint_ord_ore'; END; $$
LANGUAGE plpgsql;
