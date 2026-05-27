-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/int4/int4_types.sql
-- REQUIRE: src/encrypted_domain/functions.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql
-- REQUIRE: src/ore_block_u64_8_256/operators.sql

--! @file encrypted_domain/int4/int4_ord_functions.sql
--! @brief Ordered domain of the int4 encrypted-domain family — comparison/path functions.

--! @brief Index extractor for the eql_v2_int4_ord variant.
--! @param a eql_v2_int4_ord
--! @return eql_v2.ore_block_u64_8_256
CREATE FUNCTION eql_v2.ord_term(a eql_v2_int4_ord)
RETURNS eql_v2.ore_block_u64_8_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ore_block_u64_8_256(a::jsonb) $$;

--! @brief Equality wrapper for eql_v2_int4_ord.
--! @param a eql_v2_int4_ord
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.eq(a eql_v2_int4_ord, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) = eql_v2.ord_term(b) $$;

--! @brief Equality wrapper for eql_v2_int4_ord (domain, jsonb).
--! @param a eql_v2_int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eq(a eql_v2_int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) = eql_v2.ord_term(b::eql_v2_int4_ord) $$;

--! @brief Equality wrapper for eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.eq(a jsonb, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a::eql_v2_int4_ord) = eql_v2.ord_term(b) $$;

--! @brief Inequality wrapper for eql_v2_int4_ord.
--! @param a eql_v2_int4_ord
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.neq(a eql_v2_int4_ord, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) <> eql_v2.ord_term(b) $$;

--! @brief Inequality wrapper for eql_v2_int4_ord (domain, jsonb).
--! @param a eql_v2_int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.neq(a eql_v2_int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) <> eql_v2.ord_term(b::eql_v2_int4_ord) $$;

--! @brief Inequality wrapper for eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.neq(a jsonb, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a::eql_v2_int4_ord) <> eql_v2.ord_term(b) $$;

--! @brief Less-than wrapper for eql_v2_int4_ord.
--! @param a eql_v2_int4_ord
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.lt(a eql_v2_int4_ord, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) < eql_v2.ord_term(b) $$;

--! @brief Less-than wrapper for eql_v2_int4_ord (domain, jsonb).
--! @param a eql_v2_int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.lt(a eql_v2_int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) < eql_v2.ord_term(b::eql_v2_int4_ord) $$;

--! @brief Less-than wrapper for eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.lt(a jsonb, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a::eql_v2_int4_ord) < eql_v2.ord_term(b) $$;

--! @brief Less-than-or-equal wrapper for eql_v2_int4_ord.
--! @param a eql_v2_int4_ord
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.lte(a eql_v2_int4_ord, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) <= eql_v2.ord_term(b) $$;

--! @brief Less-than-or-equal wrapper for eql_v2_int4_ord (domain, jsonb).
--! @param a eql_v2_int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.lte(a eql_v2_int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) <= eql_v2.ord_term(b::eql_v2_int4_ord) $$;

--! @brief Less-than-or-equal wrapper for eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.lte(a jsonb, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a::eql_v2_int4_ord) <= eql_v2.ord_term(b) $$;

--! @brief Greater-than wrapper for eql_v2_int4_ord.
--! @param a eql_v2_int4_ord
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.gt(a eql_v2_int4_ord, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) > eql_v2.ord_term(b) $$;

--! @brief Greater-than wrapper for eql_v2_int4_ord (domain, jsonb).
--! @param a eql_v2_int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.gt(a eql_v2_int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) > eql_v2.ord_term(b::eql_v2_int4_ord) $$;

--! @brief Greater-than wrapper for eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.gt(a jsonb, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a::eql_v2_int4_ord) > eql_v2.ord_term(b) $$;

--! @brief Greater-than-or-equal wrapper for eql_v2_int4_ord.
--! @param a eql_v2_int4_ord
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.gte(a eql_v2_int4_ord, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) >= eql_v2.ord_term(b) $$;

--! @brief Greater-than-or-equal wrapper for eql_v2_int4_ord (domain, jsonb).
--! @param a eql_v2_int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.gte(a eql_v2_int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) >= eql_v2.ord_term(b::eql_v2_int4_ord) $$;

--! @brief Greater-than-or-equal wrapper for eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.gte(a jsonb, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a::eql_v2_int4_ord) >= eql_v2.ord_term(b) $$;

--! @brief Blocker for @> on eql_v2_int4_ord.
--! @param a eql_v2_int4_ord
--! @param b eql_v2_int4_ord
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contains(a eql_v2_int4_ord, b eql_v2_int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_ord (domain, jsonb).
--! @param a eql_v2_int4_ord
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contains(a eql_v2_int4_ord, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contains(a jsonb, b eql_v2_int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_ord.
--! @param a eql_v2_int4_ord
--! @param b eql_v2_int4_ord
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contained_by(a eql_v2_int4_ord, b eql_v2_int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_ord (domain, jsonb).
--! @param a eql_v2_int4_ord
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contained_by(a eql_v2_int4_ord, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contained_by(a jsonb, b eql_v2_int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4_ord (domain, text).
--! @param a eql_v2_int4_ord
--! @param selector text
--! @return eql_v2_int4_ord (never returns; always raises)
CREATE FUNCTION eql_v2."->"(a eql_v2_int4_ord, selector text)
RETURNS eql_v2_int4_ord IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4_ord (domain, integer).
--! @param a eql_v2_int4_ord
--! @param selector integer
--! @return eql_v2_int4_ord (never returns; always raises)
CREATE FUNCTION eql_v2."->"(a eql_v2_int4_ord, selector integer)
RETURNS eql_v2_int4_ord IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param selector eql_v2_int4_ord
--! @return eql_v2_int4_ord (never returns; always raises)
CREATE FUNCTION eql_v2."->"(a jsonb, selector eql_v2_int4_ord)
RETURNS eql_v2_int4_ord IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_ord (domain, text).
--! @param a eql_v2_int4_ord
--! @param selector text
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2."->>"(a eql_v2_int4_ord, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_ord (domain, integer).
--! @param a eql_v2_int4_ord
--! @param selector integer
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2."->>"(a eql_v2_int4_ord, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param selector eql_v2_int4_ord
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2."->>"(a jsonb, selector eql_v2_int4_ord)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ? on eql_v2_int4_ord (domain, text).
--! @param a eql_v2_int4_ord
--! @param b text
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2."?"(a eql_v2_int4_ord, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '?'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ?| on eql_v2_int4_ord (domain, text[]).
--! @param a eql_v2_int4_ord
--! @param b text[]
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2."?|"(a eql_v2_int4_ord, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '?|'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ?& on eql_v2_int4_ord (domain, text[]).
--! @param a eql_v2_int4_ord
--! @param b text[]
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2."?&"(a eql_v2_int4_ord, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '?&'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @? on eql_v2_int4_ord (domain, jsonpath).
--! @param a eql_v2_int4_ord
--! @param b jsonpath
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2."@?"(a eql_v2_int4_ord, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '@?'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @@ on eql_v2_int4_ord (domain, jsonpath).
--! @param a eql_v2_int4_ord
--! @param b jsonpath
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2."@@"(a eql_v2_int4_ord, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '@@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for #> on eql_v2_int4_ord (domain, text[]).
--! @param a eql_v2_int4_ord
--! @param b text[]
--! @return jsonb (never returns; always raises)
CREATE FUNCTION eql_v2."#>"(a eql_v2_int4_ord, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for #>> on eql_v2_int4_ord (domain, text[]).
--! @param a eql_v2_int4_ord
--! @param b text[]
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2."#>>"(a eql_v2_int4_ord, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for - on eql_v2_int4_ord (domain, text).
--! @param a eql_v2_int4_ord
--! @param b text
--! @return jsonb (never returns; always raises)
CREATE FUNCTION eql_v2."-"(a eql_v2_int4_ord, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for - on eql_v2_int4_ord (domain, integer).
--! @param a eql_v2_int4_ord
--! @param b integer
--! @return jsonb (never returns; always raises)
CREATE FUNCTION eql_v2."-"(a eql_v2_int4_ord, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for - on eql_v2_int4_ord (domain, text[]).
--! @param a eql_v2_int4_ord
--! @param b text[]
--! @return jsonb (never returns; always raises)
CREATE FUNCTION eql_v2."-"(a eql_v2_int4_ord, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for #- on eql_v2_int4_ord (domain, text[]).
--! @param a eql_v2_int4_ord
--! @param b text[]
--! @return jsonb (never returns; always raises)
CREATE FUNCTION eql_v2."#-"(a eql_v2_int4_ord, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for || on eql_v2_int4_ord.
--! @param a eql_v2_int4_ord
--! @param b eql_v2_int4_ord
--! @return jsonb (never returns; always raises)
CREATE FUNCTION eql_v2."||"(a eql_v2_int4_ord, b eql_v2_int4_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for || on eql_v2_int4_ord (domain, jsonb).
--! @param a eql_v2_int4_ord
--! @param b jsonb
--! @return jsonb (never returns; always raises)
CREATE FUNCTION eql_v2."||"(a eql_v2_int4_ord, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for || on eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord
--! @return jsonb (never returns; always raises)
CREATE FUNCTION eql_v2."||"(a jsonb, b eql_v2_int4_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;
