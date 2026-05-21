-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/types.sql
-- REQUIRE: src/encrypted_domain/functions.sql
-- REQUIRE: src/hmac_256/functions.sql

--! @file encrypted_domain/int4/int4_eq_functions.sql
--! @brief Equality-only int4 variant — comparison/path functions. Supports = and <> via HMAC-256.
--!
--! eql_v2_int4_eq carries `c`, `hm` and supports HMAC equality. A
--! functional index on eql_v2.eq_term(col) — USING hash or USING btree —
--! engages for `=`. `<>` is supported but is a seq-scan (no index serves
--! inequality). All other operators raise. Payload-term assumption:
--! `c`, `hm`.

-- index extractor

--! @brief Index extractor for the eql_v2_int4_eq variant.
--!
--! Returns the HMAC-256 equality term carried in the `hm` field of the
--! jsonb payload. The returned eql_v2.hmac_256 is a domain over text, so
--! a functional index — USING hash (eql_v2.eq_term(col)) or
--! USING btree (eql_v2.eq_term(col)) — engages `=`. Inlinable
--! single-statement SQL: `col = $1` folds to
--! `eql_v2.eq_term(col) = eql_v2.eq_term($1)` and matches that index.
--!
--! @param a eql_v2_int4_eq Equality-variant encrypted int4 value
--! @return eql_v2.hmac_256 HMAC-256 equality index term
--! @see eql_v2.hmac_256
--! @example
--! -- functional index for equality
--! CREATE INDEX t_col_idx ON t USING hash (eql_v2.eq_term(col));
CREATE FUNCTION eql_v2.eq_term(a eql_v2_int4_eq)
RETURNS eql_v2.hmac_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) $$;

-- = / <> (HMAC equality wrappers, 3 shapes each)

--! @brief Equality wrapper for eql_v2_int4_eq. Inlines to eq_term comparison.
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

--! @brief Inequality wrapper for eql_v2_int4_eq. Inlines to eq_term comparison.
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

-- <, <=, >, >=, ~~, ~~*, @>, <@ (blockers, 3 shapes each — 8 ops × 3 = 24 functions)

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

--! @brief Blocker for ~~ on eql_v2_int4_eq.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_like(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~ on eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_like(a eql_v2_int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~ on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_like(a jsonb, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_eq.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_ilike(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_ilike(a eql_v2_int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_ilike(a jsonb, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '~~*'); END; $$
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

-- -> and ->> (blockers, 3 asymmetric shapes each)

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
