-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/types.sql
-- REQUIRE: src/encrypted_domain/functions.sql
-- REQUIRE: src/hmac_256/functions.sql
-- REQUIRE: src/ope_cllw_u64_65/functions.sql

--! @file encrypted_domain/int4/int4_ord_ope.sql
--! @brief Equality + OPE-direct ordering int4 variant.
--!
--! eql_v2_int4_ord_ope carries `hm` and `opf`. Equality uses HMAC
--! (functional btree engages). Range operators reduce to bytea
--! lex-compare of eql_v2_int4_ord_ope_ope_key(...) — both wrappers
--! inline, so a functional btree on the extractor expression
--!   ((eql_v2.eql_v2_int4_ord_ope_ope_key(col::jsonb)))
--! engages for range queries. Payload-term assumption: `hm`, `opf`.

-- OPE-key extractor (two overloads, both used as functional-index expressions).

--! @brief OPE-key extractor for eql_v2_int4_ord_ope.
--! @param a eql_v2_int4_ord_ope
--! @return bytea (OPE ciphertext; lexicographic order matches plaintext order)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_ope_key(a eql_v2_int4_ord_ope)
RETURNS bytea LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT (eql_v2.ope_cllw_u64_65(a::jsonb)).bytes $$;

--! @brief OPE-key extractor for eql_v2_int4_ord_ope (jsonb input).
--! @param a jsonb
--! @return bytea (OPE ciphertext; lexicographic order matches plaintext order)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_ope_key(a jsonb)
RETURNS bytea LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT (eql_v2.ope_cllw_u64_65(a)).bytes $$;

-- = / <> (HMAC equality wrappers, 3 shapes each)

--! @brief Equality wrapper for eql_v2_int4_ord_ope. Inlines to hmac_256 comparison.
--! @param a eql_v2_int4_ord_ope
--! @param b eql_v2_int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_eq(a eql_v2_int4_ord_ope, b eql_v2_int4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) = eql_v2.hmac_256(b::jsonb) $$;

--! @brief Equality wrapper for eql_v2_int4_ord_ope (domain, jsonb).
--! @param a eql_v2_int4_ord_ope
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_eq(a eql_v2_int4_ord_ope, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) = eql_v2.hmac_256(b) $$;

--! @brief Equality wrapper for eql_v2_int4_ord_ope (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_eq(a jsonb, b eql_v2_int4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a) = eql_v2.hmac_256(b::jsonb) $$;

--! @brief Inequality wrapper for eql_v2_int4_ord_ope. Inlines to hmac_256 comparison.
--! @param a eql_v2_int4_ord_ope
--! @param b eql_v2_int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_neq(a eql_v2_int4_ord_ope, b eql_v2_int4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) <> eql_v2.hmac_256(b::jsonb) $$;

--! @brief Inequality wrapper for eql_v2_int4_ord_ope (domain, jsonb).
--! @param a eql_v2_int4_ord_ope
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_neq(a eql_v2_int4_ord_ope, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) <> eql_v2.hmac_256(b) $$;

--! @brief Inequality wrapper for eql_v2_int4_ord_ope (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_neq(a jsonb, b eql_v2_int4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a) <> eql_v2.hmac_256(b::jsonb) $$;

-- <, <=, >, >= (OPE-direct range wrappers, 3 shapes each)
-- These inline to bytea lex-compare of eql_v2_int4_ord_ope_ope_key(...);
-- both the wrapper and the extractor inline, so a functional btree on
-- ((eql_v2.eql_v2_int4_ord_ope_ope_key(col::jsonb))) engages for range
-- queries. The (domain, jsonb) and (jsonb, domain) overloads dispatch
-- to the appropriate ope_key overload for each argument.

--! @brief Less-than wrapper for eql_v2_int4_ord_ope. Inlines to bytea lex-compare of the OPE-key extractor.
--! @param a eql_v2_int4_ord_ope
--! @param b eql_v2_int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_lt(a eql_v2_int4_ord_ope, b eql_v2_int4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.eql_v2_int4_ord_ope_ope_key(a) < eql_v2.eql_v2_int4_ord_ope_ope_key(b) $$;

--! @brief Less-than wrapper for eql_v2_int4_ord_ope (domain, jsonb).
--! @param a eql_v2_int4_ord_ope
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_lt(a eql_v2_int4_ord_ope, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.eql_v2_int4_ord_ope_ope_key(a) < eql_v2.eql_v2_int4_ord_ope_ope_key(b) $$;

--! @brief Less-than wrapper for eql_v2_int4_ord_ope (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_lt(a jsonb, b eql_v2_int4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.eql_v2_int4_ord_ope_ope_key(a) < eql_v2.eql_v2_int4_ord_ope_ope_key(b) $$;

--! @brief Less-than-or-equal wrapper for eql_v2_int4_ord_ope.
--! @param a eql_v2_int4_ord_ope
--! @param b eql_v2_int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_lte(a eql_v2_int4_ord_ope, b eql_v2_int4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.eql_v2_int4_ord_ope_ope_key(a) <= eql_v2.eql_v2_int4_ord_ope_ope_key(b) $$;

--! @brief Less-than-or-equal wrapper for eql_v2_int4_ord_ope (domain, jsonb).
--! @param a eql_v2_int4_ord_ope
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_lte(a eql_v2_int4_ord_ope, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.eql_v2_int4_ord_ope_ope_key(a) <= eql_v2.eql_v2_int4_ord_ope_ope_key(b) $$;

--! @brief Less-than-or-equal wrapper for eql_v2_int4_ord_ope (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_lte(a jsonb, b eql_v2_int4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.eql_v2_int4_ord_ope_ope_key(a) <= eql_v2.eql_v2_int4_ord_ope_ope_key(b) $$;

--! @brief Greater-than wrapper for eql_v2_int4_ord_ope.
--! @param a eql_v2_int4_ord_ope
--! @param b eql_v2_int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_gt(a eql_v2_int4_ord_ope, b eql_v2_int4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.eql_v2_int4_ord_ope_ope_key(a) > eql_v2.eql_v2_int4_ord_ope_ope_key(b) $$;

--! @brief Greater-than wrapper for eql_v2_int4_ord_ope (domain, jsonb).
--! @param a eql_v2_int4_ord_ope
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_gt(a eql_v2_int4_ord_ope, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.eql_v2_int4_ord_ope_ope_key(a) > eql_v2.eql_v2_int4_ord_ope_ope_key(b) $$;

--! @brief Greater-than wrapper for eql_v2_int4_ord_ope (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_gt(a jsonb, b eql_v2_int4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.eql_v2_int4_ord_ope_ope_key(a) > eql_v2.eql_v2_int4_ord_ope_ope_key(b) $$;

--! @brief Greater-than-or-equal wrapper for eql_v2_int4_ord_ope.
--! @param a eql_v2_int4_ord_ope
--! @param b eql_v2_int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_gte(a eql_v2_int4_ord_ope, b eql_v2_int4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.eql_v2_int4_ord_ope_ope_key(a) >= eql_v2.eql_v2_int4_ord_ope_ope_key(b) $$;

--! @brief Greater-than-or-equal wrapper for eql_v2_int4_ord_ope (domain, jsonb).
--! @param a eql_v2_int4_ord_ope
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_gte(a eql_v2_int4_ord_ope, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.eql_v2_int4_ord_ope_ope_key(a) >= eql_v2.eql_v2_int4_ord_ope_ope_key(b) $$;

--! @brief Greater-than-or-equal wrapper for eql_v2_int4_ord_ope (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_gte(a jsonb, b eql_v2_int4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.eql_v2_int4_ord_ope_ope_key(a) >= eql_v2.eql_v2_int4_ord_ope_ope_key(b) $$;

-- ~~, ~~*, @>, <@ (blockers, 3 shapes each)

--! @brief Blocker for ~~ on eql_v2_int4_ord_ope.
--! @param a eql_v2_int4_ord_ope
--! @param b eql_v2_int4_ord_ope
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_like(a eql_v2_int4_ord_ope, b eql_v2_int4_ord_ope)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ope', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~ on eql_v2_int4_ord_ope (domain, jsonb).
--! @param a eql_v2_int4_ord_ope
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_like(a eql_v2_int4_ord_ope, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ope', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~ on eql_v2_int4_ord_ope (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ope
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_like(a jsonb, b eql_v2_int4_ord_ope)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ope', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_ord_ope.
--! @param a eql_v2_int4_ord_ope
--! @param b eql_v2_int4_ord_ope
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_ilike(a eql_v2_int4_ord_ope, b eql_v2_int4_ord_ope)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ope', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_ord_ope (domain, jsonb).
--! @param a eql_v2_int4_ord_ope
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_ilike(a eql_v2_int4_ord_ope, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ope', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_ord_ope (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ope
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_ilike(a jsonb, b eql_v2_int4_ord_ope)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ope', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_ord_ope.
--! @param a eql_v2_int4_ord_ope
--! @param b eql_v2_int4_ord_ope
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_contains(a eql_v2_int4_ord_ope, b eql_v2_int4_ord_ope)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ope', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_ord_ope (domain, jsonb).
--! @param a eql_v2_int4_ord_ope
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_contains(a eql_v2_int4_ord_ope, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ope', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_ord_ope (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ope
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_contains(a jsonb, b eql_v2_int4_ord_ope)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ope', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_ord_ope.
--! @param a eql_v2_int4_ord_ope
--! @param b eql_v2_int4_ord_ope
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_contained_by(a eql_v2_int4_ord_ope, b eql_v2_int4_ord_ope)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ope', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_ord_ope (domain, jsonb).
--! @param a eql_v2_int4_ord_ope
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_contained_by(a eql_v2_int4_ord_ope, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ope', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_ord_ope (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ope
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_contained_by(a jsonb, b eql_v2_int4_ord_ope)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ope', '<@'); END; $$
LANGUAGE plpgsql;

-- -> and ->> (blockers, 3 asymmetric shapes each)

--! @brief Blocker for -> on eql_v2_int4_ord_ope (domain, text).
--! @param a eql_v2_int4_ord_ope
--! @param selector text
--! @return eql_v2_int4_ord_ope (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_arrow(a eql_v2_int4_ord_ope, selector text)
RETURNS eql_v2_int4_ord_ope IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4_ord_ope (domain, integer).
--! @param a eql_v2_int4_ord_ope
--! @param selector integer
--! @return eql_v2_int4_ord_ope (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_arrow(a eql_v2_int4_ord_ope, selector integer)
RETURNS eql_v2_int4_ord_ope IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4_ord_ope (jsonb, domain).
--! @param a jsonb
--! @param selector eql_v2_int4_ord_ope
--! @return eql_v2_int4_ord_ope (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_arrow(a jsonb, selector eql_v2_int4_ord_ope)
RETURNS eql_v2_int4_ord_ope IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_ord_ope (domain, text).
--! @param a eql_v2_int4_ord_ope
--! @param selector text
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_arrow_text(a eql_v2_int4_ord_ope, selector text)
RETURNS text IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_ord_ope (domain, integer).
--! @param a eql_v2_int4_ord_ope
--! @param selector integer
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_arrow_text(a eql_v2_int4_ord_ope, selector integer)
RETURNS text IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_ord_ope (jsonb, domain).
--! @param a jsonb
--! @param selector eql_v2_int4_ord_ope
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ope_arrow_text(a jsonb, selector eql_v2_int4_ord_ope)
RETURNS text IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_ord_ope'; END; $$
LANGUAGE plpgsql;

-- Operator declarations

CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_ord_ope_eq,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = eql_v2_int4_ord_ope,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_ord_ope_eq,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = jsonb,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_ord_ope_eq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ope,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_ord_ope_neq,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = eql_v2_int4_ord_ope,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_ord_ope_neq,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = jsonb,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_ord_ope_neq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ope,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v2.eql_v2_int4_ord_ope_lt,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = eql_v2_int4_ord_ope,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR < (FUNCTION = eql_v2.eql_v2_int4_ord_ope_lt,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = jsonb);
CREATE OPERATOR < (FUNCTION = eql_v2.eql_v2_int4_ord_ope_lt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ope);

CREATE OPERATOR <= (
  FUNCTION = eql_v2.eql_v2_int4_ord_ope_lte,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = eql_v2_int4_ord_ope,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR <= (FUNCTION = eql_v2.eql_v2_int4_ord_ope_lte,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = jsonb);
CREATE OPERATOR <= (FUNCTION = eql_v2.eql_v2_int4_ord_ope_lte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ope);

CREATE OPERATOR > (
  FUNCTION = eql_v2.eql_v2_int4_ord_ope_gt,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = eql_v2_int4_ord_ope,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR > (FUNCTION = eql_v2.eql_v2_int4_ord_ope_gt,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = jsonb);
CREATE OPERATOR > (FUNCTION = eql_v2.eql_v2_int4_ord_ope_gt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ope);

CREATE OPERATOR >= (
  FUNCTION = eql_v2.eql_v2_int4_ord_ope_gte,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = eql_v2_int4_ord_ope,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR >= (FUNCTION = eql_v2.eql_v2_int4_ord_ope_gte,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = jsonb);
CREATE OPERATOR >= (FUNCTION = eql_v2.eql_v2_int4_ord_ope_gte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ope);

CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_ord_ope_like,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = eql_v2_int4_ord_ope);
CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_ord_ope_like,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = jsonb);
CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_ord_ope_like,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ope);

CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_ord_ope_ilike,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = eql_v2_int4_ord_ope);
CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_ord_ope_ilike,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = jsonb);
CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_ord_ope_ilike,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ope);

CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_ord_ope_contains,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = eql_v2_int4_ord_ope);
CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_ord_ope_contains,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = jsonb);
CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_ord_ope_contains,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ope);

CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_ord_ope_contained_by,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = eql_v2_int4_ord_ope);
CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_ord_ope_contained_by,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = jsonb);
CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_ord_ope_contained_by,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ope);

CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_ord_ope_arrow,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = text);
CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_ord_ope_arrow,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = integer);
CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_ord_ope_arrow,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ope);

CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_ord_ope_arrow_text,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = text);
CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_ord_ope_arrow_text,
  LEFTARG = eql_v2_int4_ord_ope, RIGHTARG = integer);
CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_ord_ope_arrow_text,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ope);
