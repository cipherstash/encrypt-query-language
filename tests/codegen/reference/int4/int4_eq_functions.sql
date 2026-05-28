-- REFERENCE: hand-written parity baseline for tasks/codegen/ — see ../README.md
-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/int4/int4_types.sql
-- REQUIRE: src/encrypted_domain/functions.sql
-- REQUIRE: src/hmac_256/functions.sql

--! @file encrypted_domain/int4/int4_eq_functions.sql
--! @brief Equality-only domain of the int4 encrypted-domain family — comparison/path functions.

--! @brief Index extractor for the eql_v2_int4_eq variant.
--! @param a eql_v2_int4_eq
--! @return eql_v2.hmac_256
CREATE FUNCTION eql_v2.eq_term(a eql_v2_int4_eq)
RETURNS eql_v2.hmac_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) $$;

--! @brief Equality wrapper for eql_v2_int4_eq.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean
CREATE FUNCTION eql_v2.eq(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.eq_term(a) = eql_v2.eq_term(b) $$;

--! @brief Equality wrapper for eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eq(a eql_v2_int4_eq, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.eq_term(a) = eql_v2.eq_term(b::eql_v2_int4_eq) $$;

--! @brief Equality wrapper for eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean
CREATE FUNCTION eql_v2.eq(a jsonb, b eql_v2_int4_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.eq_term(a::eql_v2_int4_eq) = eql_v2.eq_term(b) $$;

--! @brief Inequality wrapper for eql_v2_int4_eq.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean
CREATE FUNCTION eql_v2.neq(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.eq_term(a) <> eql_v2.eq_term(b) $$;

--! @brief Inequality wrapper for eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.neq(a eql_v2_int4_eq, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.eq_term(a) <> eql_v2.eq_term(b::eql_v2_int4_eq) $$;

--! @brief Inequality wrapper for eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean
CREATE FUNCTION eql_v2.neq(a jsonb, b eql_v2_int4_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.eq_term(a::eql_v2_int4_eq) <> eql_v2.eq_term(b) $$;

--! @brief Blocker for < on eql_v2_int4_eq.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.lt(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '<'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for < on eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.lt(a eql_v2_int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '<'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for < on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.lt(a jsonb, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '<'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <= on eql_v2_int4_eq.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.lte(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '<='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <= on eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.lte(a eql_v2_int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '<='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <= on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.lte(a jsonb, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '<='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for > on eql_v2_int4_eq.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.gt(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for > on eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.gt(a eql_v2_int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for > on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.gt(a jsonb, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for >= on eql_v2_int4_eq.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.gte(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '>='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for >= on eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.gte(a eql_v2_int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '>='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for >= on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.gte(a jsonb, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '>='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_eq.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contains(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contains(a eql_v2_int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contains(a jsonb, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_eq.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contained_by(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contained_by(a eql_v2_int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contained_by(a jsonb, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4_eq (domain, text).
--! @param a eql_v2_int4_eq
--! @param selector text
--! @return eql_v2_int4_eq (never returns; always raises)
CREATE FUNCTION eql_v2."->"(a eql_v2_int4_eq, selector text)
RETURNS eql_v2_int4_eq IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4_eq (domain, integer).
--! @param a eql_v2_int4_eq
--! @param selector integer
--! @return eql_v2_int4_eq (never returns; always raises)
CREATE FUNCTION eql_v2."->"(a eql_v2_int4_eq, selector integer)
RETURNS eql_v2_int4_eq IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param selector eql_v2_int4_eq
--! @return eql_v2_int4_eq (never returns; always raises)
CREATE FUNCTION eql_v2."->"(a jsonb, selector eql_v2_int4_eq)
RETURNS eql_v2_int4_eq IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_eq (domain, text).
--! @param a eql_v2_int4_eq
--! @param selector text
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2."->>"(a eql_v2_int4_eq, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_eq (domain, integer).
--! @param a eql_v2_int4_eq
--! @param selector integer
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2."->>"(a eql_v2_int4_eq, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param selector eql_v2_int4_eq
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2."->>"(a jsonb, selector eql_v2_int4_eq)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ? on eql_v2_int4_eq (domain, text).
--! @param a eql_v2_int4_eq
--! @param b text
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2."?"(a eql_v2_int4_eq, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '?'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ?| on eql_v2_int4_eq (domain, text[]).
--! @param a eql_v2_int4_eq
--! @param b text[]
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2."?|"(a eql_v2_int4_eq, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '?|'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ?& on eql_v2_int4_eq (domain, text[]).
--! @param a eql_v2_int4_eq
--! @param b text[]
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2."?&"(a eql_v2_int4_eq, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '?&'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @? on eql_v2_int4_eq (domain, jsonpath).
--! @param a eql_v2_int4_eq
--! @param b jsonpath
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2."@?"(a eql_v2_int4_eq, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '@?'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @@ on eql_v2_int4_eq (domain, jsonpath).
--! @param a eql_v2_int4_eq
--! @param b jsonpath
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2."@@"(a eql_v2_int4_eq, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '@@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for #> on eql_v2_int4_eq (domain, text[]).
--! @param a eql_v2_int4_eq
--! @param b text[]
--! @return jsonb (never returns; always raises)
CREATE FUNCTION eql_v2."#>"(a eql_v2_int4_eq, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for #>> on eql_v2_int4_eq (domain, text[]).
--! @param a eql_v2_int4_eq
--! @param b text[]
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2."#>>"(a eql_v2_int4_eq, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for - on eql_v2_int4_eq (domain, text).
--! @param a eql_v2_int4_eq
--! @param b text
--! @return jsonb (never returns; always raises)
CREATE FUNCTION eql_v2."-"(a eql_v2_int4_eq, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for - on eql_v2_int4_eq (domain, integer).
--! @param a eql_v2_int4_eq
--! @param b integer
--! @return jsonb (never returns; always raises)
CREATE FUNCTION eql_v2."-"(a eql_v2_int4_eq, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for - on eql_v2_int4_eq (domain, text[]).
--! @param a eql_v2_int4_eq
--! @param b text[]
--! @return jsonb (never returns; always raises)
CREATE FUNCTION eql_v2."-"(a eql_v2_int4_eq, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for #- on eql_v2_int4_eq (domain, text[]).
--! @param a eql_v2_int4_eq
--! @param b text[]
--! @return jsonb (never returns; always raises)
CREATE FUNCTION eql_v2."#-"(a eql_v2_int4_eq, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for || on eql_v2_int4_eq.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return jsonb (never returns; always raises)
CREATE FUNCTION eql_v2."||"(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for || on eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return jsonb (never returns; always raises)
CREATE FUNCTION eql_v2."||"(a eql_v2_int4_eq, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for || on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return jsonb (never returns; always raises)
CREATE FUNCTION eql_v2."||"(a jsonb, b eql_v2_int4_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;
