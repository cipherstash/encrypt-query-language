-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/types.sql
-- REQUIRE: src/encrypted_domain/functions.sql

--! @file encrypted_domain/int4/int4_functions.sql
--! @brief Storage-only int4 variant — comparison/path functions. All bool operators raise.
--!
--! eql_v2_int4 accepts the storage of an encrypted int4 column with
--! ciphertext (`c`) only. Every comparison, containment, and path
--! operator is a blocker so callers cannot accidentally fall through to
--! native jsonb semantics. Payload-term assumption: `c` only.

-- =, <> (blockers, 3 shapes each)

--! @brief Blocker for = on eql_v2_int4.
--! @param a eql_v2_int4
--! @param b eql_v2_int4
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eq(a eql_v2_int4, b eql_v2_int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for = on eql_v2_int4 (domain, jsonb).
--! @param a eql_v2_int4
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eq(a eql_v2_int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for = on eql_v2_int4 (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eq(a jsonb, b eql_v2_int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <> on eql_v2_int4.
--! @param a eql_v2_int4
--! @param b eql_v2_int4
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.neq(a eql_v2_int4, b eql_v2_int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '<>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <> on eql_v2_int4 (domain, jsonb).
--! @param a eql_v2_int4
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.neq(a eql_v2_int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '<>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <> on eql_v2_int4 (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.neq(a jsonb, b eql_v2_int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '<>'); END; $$
LANGUAGE plpgsql;

-- <, <=, >, >= (blockers, 3 shapes each)

--! @brief Blocker for < on eql_v2_int4.
--! @param a eql_v2_int4
--! @param b eql_v2_int4
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.lt(a eql_v2_int4, b eql_v2_int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '<'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for < on eql_v2_int4 (domain, jsonb).
--! @param a eql_v2_int4
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.lt(a eql_v2_int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '<'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for < on eql_v2_int4 (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.lt(a jsonb, b eql_v2_int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '<'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <= on eql_v2_int4.
--! @param a eql_v2_int4
--! @param b eql_v2_int4
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.lte(a eql_v2_int4, b eql_v2_int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '<='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <= on eql_v2_int4 (domain, jsonb).
--! @param a eql_v2_int4
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.lte(a eql_v2_int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '<='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <= on eql_v2_int4 (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.lte(a jsonb, b eql_v2_int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '<='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for > on eql_v2_int4.
--! @param a eql_v2_int4
--! @param b eql_v2_int4
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.gt(a eql_v2_int4, b eql_v2_int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for > on eql_v2_int4 (domain, jsonb).
--! @param a eql_v2_int4
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.gt(a eql_v2_int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for > on eql_v2_int4 (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.gt(a jsonb, b eql_v2_int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for >= on eql_v2_int4.
--! @param a eql_v2_int4
--! @param b eql_v2_int4
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.gte(a eql_v2_int4, b eql_v2_int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '>='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for >= on eql_v2_int4 (domain, jsonb).
--! @param a eql_v2_int4
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.gte(a eql_v2_int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '>='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for >= on eql_v2_int4 (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.gte(a jsonb, b eql_v2_int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '>='); END; $$
LANGUAGE plpgsql;

-- @>, <@ (blockers, 3 shapes each)

--! @brief Blocker for @> on eql_v2_int4.
--! @param a eql_v2_int4
--! @param b eql_v2_int4
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contains(a eql_v2_int4, b eql_v2_int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4 (domain, jsonb).
--! @param a eql_v2_int4
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contains(a eql_v2_int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4 (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contains(a jsonb, b eql_v2_int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4.
--! @param a eql_v2_int4
--! @param b eql_v2_int4
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contained_by(a eql_v2_int4, b eql_v2_int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4 (domain, jsonb).
--! @param a eql_v2_int4
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contained_by(a eql_v2_int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4 (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contained_by(a jsonb, b eql_v2_int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '<@'); END; $$
LANGUAGE plpgsql;

-- -> and ->> (blockers, 3 asymmetric shapes each)

--! @brief Blocker for -> on eql_v2_int4 (domain, text).
--! @param a eql_v2_int4
--! @param selector text
--! @return eql_v2_int4 (never returns; always raises)
CREATE FUNCTION eql_v2."->"(a eql_v2_int4, selector text)
RETURNS eql_v2_int4 IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4 (domain, integer).
--! @param a eql_v2_int4
--! @param selector integer
--! @return eql_v2_int4 (never returns; always raises)
CREATE FUNCTION eql_v2."->"(a eql_v2_int4, selector integer)
RETURNS eql_v2_int4 IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4 (jsonb, domain).
--! @param a jsonb
--! @param selector eql_v2_int4
--! @return eql_v2_int4 (never returns; always raises)
CREATE FUNCTION eql_v2."->"(a jsonb, selector eql_v2_int4)
RETURNS eql_v2_int4 IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4 (domain, text).
--! @param a eql_v2_int4
--! @param selector text
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2."->>"(a eql_v2_int4, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4 (domain, integer).
--! @param a eql_v2_int4
--! @param selector integer
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2."->>"(a eql_v2_int4, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4 (jsonb, domain).
--! @param a jsonb
--! @param selector eql_v2_int4
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2."->>"(a jsonb, selector eql_v2_int4)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4'; END; $$
LANGUAGE plpgsql;
