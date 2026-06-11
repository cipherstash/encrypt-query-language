-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/jsonb/types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file v3/jsonb/blockers.sql
--! @brief Native-jsonb firewall for eql_v3.json.
--!
--! eql_v3.json SUPPORTS @> <@ -> ->> (see operators.sql). Comparisons
--! = <> < <= > >= are supported on eql_v3.ste_vec_entry only, not on the root
--! document domain.
--! Every OTHER native jsonb operator reachable via domain fallback against the
--! base type jsonb is BLOCKED here so an encrypted column can never silently
--! route to plaintext-jsonb semantics. The blocked set is KNOWN_JSONB_OPERATORS
--! minus the supported ops: ? ?| ?& @? @@ #> #>> - #- ||.
--!
--! Each blocker is LANGUAGE plpgsql (NEVER STRICT — a STRICT blocker would let
--! PostgreSQL skip the body and return NULL on a NULL argument, bypassing the
--! exception) and delegates to the shared eql_v3.encrypted_domain_unsupported_bool
--! helper. The bound operator must resolve before native fallback, so the
--! firewall fires.

--! @brief Blocker: ? (key/element exists).
--! @param a eql_v3.json Left operand (encrypted payload).
--! @param b text Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_exists(a eql_v3.json, b text)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', '?');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR ? (
  FUNCTION = eql_v3.jsonb_blocked_exists,
  LEFTARG = eql_v3.json,
  RIGHTARG = text
);

--! @brief Blocker: ?| (any key exists).
--! @param a eql_v3.json Left operand (encrypted payload).
--! @param b text[] Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_exists_any(a eql_v3.json, b text[])
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', '?|');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR ?| (
  FUNCTION = eql_v3.jsonb_blocked_exists_any,
  LEFTARG = eql_v3.json,
  RIGHTARG = text[]
);

--! @brief Blocker: ?& (all keys exist).
--! @param a eql_v3.json Left operand (encrypted payload).
--! @param b text[] Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_exists_all(a eql_v3.json, b text[])
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', '?&');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR ?& (
  FUNCTION = eql_v3.jsonb_blocked_exists_all,
  LEFTARG = eql_v3.json,
  RIGHTARG = text[]
);

--! @brief Blocker: @? (jsonpath exists).
--! @param a eql_v3.json Left operand (encrypted payload).
--! @param b jsonpath Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_jsonpath_exists(a eql_v3.json, b jsonpath)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', '@?');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR @? (
  FUNCTION = eql_v3.jsonb_blocked_jsonpath_exists,
  LEFTARG = eql_v3.json,
  RIGHTARG = jsonpath
);

--! @brief Blocker: @@ (jsonpath predicate).
--! @param a eql_v3.json Left operand (encrypted payload).
--! @param b jsonpath Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_jsonpath_match(a eql_v3.json, b jsonpath)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', '@@');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR @@ (
  FUNCTION = eql_v3.jsonb_blocked_jsonpath_match,
  LEFTARG = eql_v3.json,
  RIGHTARG = jsonpath
);

--! @brief Blocker: #> (path extract, native returns jsonb).
--! @param a eql_v3.json Left operand (encrypted payload).
--! @param b text[] Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_path_extract(a eql_v3.json, b text[])
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', '#>');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR #> (
  FUNCTION = eql_v3.jsonb_blocked_path_extract,
  LEFTARG = eql_v3.json,
  RIGHTARG = text[]
);

--! @brief Blocker: #>> (path extract as text).
--! @param a eql_v3.json Left operand (encrypted payload).
--! @param b text[] Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_path_extract_text(a eql_v3.json, b text[])
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', '#>>');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR #>> (
  FUNCTION = eql_v3.jsonb_blocked_path_extract_text,
  LEFTARG = eql_v3.json,
  RIGHTARG = text[]
);

--! @brief Blocker: - (delete key, text RHS; native returns jsonb).
--! @param a eql_v3.json Left operand (encrypted payload).
--! @param b text Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_delete_text(a eql_v3.json, b text)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', '-');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR - (
  FUNCTION = eql_v3.jsonb_blocked_delete_text,
  LEFTARG = eql_v3.json,
  RIGHTARG = text
);

--! @brief Blocker: - (delete index, integer RHS).
--! @param a eql_v3.json Left operand (encrypted payload).
--! @param b integer Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_delete_int(a eql_v3.json, b integer)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', '-');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR - (
  FUNCTION = eql_v3.jsonb_blocked_delete_int,
  LEFTARG = eql_v3.json,
  RIGHTARG = integer
);

--! @brief Blocker: - (delete keys, text[] RHS).
--! @param a eql_v3.json Left operand (encrypted payload).
--! @param b text[] Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_delete_array(a eql_v3.json, b text[])
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', '-');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR - (
  FUNCTION = eql_v3.jsonb_blocked_delete_array,
  LEFTARG = eql_v3.json,
  RIGHTARG = text[]
);

--! @brief Blocker: #- (delete at path).
--! @param a eql_v3.json Left operand (encrypted payload).
--! @param b text[] Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_delete_path(a eql_v3.json, b text[])
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', '#-');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR #- (
  FUNCTION = eql_v3.jsonb_blocked_delete_path,
  LEFTARG = eql_v3.json,
  RIGHTARG = text[]
);

--! @brief Blocker: || (concatenate, encrypted on the left).
--! @param a eql_v3.json Left operand (encrypted payload).
--! @param b jsonb Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_concat(a eql_v3.json, b jsonb)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', '||');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR || (
  FUNCTION = eql_v3.jsonb_blocked_concat,
  LEFTARG = eql_v3.json,
  RIGHTARG = jsonb
);

--! @brief Blocker: || (concatenate, encrypted on the right).
--! @param a jsonb Native LHS operand.
--! @param b eql_v3.json Right operand (encrypted payload).
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_concat_rhs(a jsonb, b eql_v3.json)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', '||');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR || (
  FUNCTION = eql_v3.jsonb_blocked_concat_rhs,
  LEFTARG = jsonb,
  RIGHTARG = eql_v3.json
);

------------------------------------------------------------------------------
-- Root-document comparison blockers.
------------------------------------------------------------------------------

--! @brief Blocker: root eql_v3.json document comparisons.
--! @param a eql_v3.json Left operand (encrypted payload).
--! @param b eql_v3.json Right operand (encrypted payload).
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_compare_json_json(a eql_v3.json, b eql_v3.json)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', 'comparison');
END;
$$ LANGUAGE plpgsql;

--! @brief Blocker: root eql_v3.json-to-jsonb comparisons.
--! @param a eql_v3.json Left operand (encrypted payload).
--! @param b jsonb Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_compare_json_jsonb(a eql_v3.json, b jsonb)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', 'comparison');
END;
$$ LANGUAGE plpgsql;

--! @brief Blocker: root jsonb-to-eql_v3.json comparisons.
--! @param a jsonb Native LHS operand.
--! @param b eql_v3.json Right operand (encrypted payload).
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_compare_jsonb_json(a jsonb, b eql_v3.json)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', 'comparison');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR = (
  FUNCTION = eql_v3.jsonb_blocked_compare_json_json,
  LEFTARG = eql_v3.json,
  RIGHTARG = eql_v3.json
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.jsonb_blocked_compare_json_jsonb,
  LEFTARG = eql_v3.json,
  RIGHTARG = jsonb
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.jsonb_blocked_compare_jsonb_json,
  LEFTARG = jsonb,
  RIGHTARG = eql_v3.json
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.jsonb_blocked_compare_json_json,
  LEFTARG = eql_v3.json,
  RIGHTARG = eql_v3.json
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.jsonb_blocked_compare_json_jsonb,
  LEFTARG = eql_v3.json,
  RIGHTARG = jsonb
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.jsonb_blocked_compare_jsonb_json,
  LEFTARG = jsonb,
  RIGHTARG = eql_v3.json
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.jsonb_blocked_compare_json_json,
  LEFTARG = eql_v3.json,
  RIGHTARG = eql_v3.json
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.jsonb_blocked_compare_json_jsonb,
  LEFTARG = eql_v3.json,
  RIGHTARG = jsonb
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.jsonb_blocked_compare_jsonb_json,
  LEFTARG = jsonb,
  RIGHTARG = eql_v3.json
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.jsonb_blocked_compare_json_json,
  LEFTARG = eql_v3.json,
  RIGHTARG = eql_v3.json
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.jsonb_blocked_compare_json_jsonb,
  LEFTARG = eql_v3.json,
  RIGHTARG = jsonb
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.jsonb_blocked_compare_jsonb_json,
  LEFTARG = jsonb,
  RIGHTARG = eql_v3.json
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.jsonb_blocked_compare_json_json,
  LEFTARG = eql_v3.json,
  RIGHTARG = eql_v3.json
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.jsonb_blocked_compare_json_jsonb,
  LEFTARG = eql_v3.json,
  RIGHTARG = jsonb
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.jsonb_blocked_compare_jsonb_json,
  LEFTARG = jsonb,
  RIGHTARG = eql_v3.json
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.jsonb_blocked_compare_json_json,
  LEFTARG = eql_v3.json,
  RIGHTARG = eql_v3.json
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.jsonb_blocked_compare_json_jsonb,
  LEFTARG = eql_v3.json,
  RIGHTARG = jsonb
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.jsonb_blocked_compare_jsonb_json,
  LEFTARG = jsonb,
  RIGHTARG = eql_v3.json
);

------------------------------------------------------------------------------
-- Mixed jsonb containment blockers.
------------------------------------------------------------------------------

--! @brief Blocker: @> with encrypted root document and native jsonb.
--! @param a eql_v3.json Left operand (encrypted payload).
--! @param b jsonb Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_contains_json_jsonb(a eql_v3.json, b jsonb)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', '@>');
END;
$$ LANGUAGE plpgsql;

--! @brief Blocker: @> with native jsonb and encrypted root document.
--! @param a jsonb Native LHS operand.
--! @param b eql_v3.json Right operand (encrypted payload).
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_contains_jsonb_json(a jsonb, b eql_v3.json)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', '@>');
END;
$$ LANGUAGE plpgsql;

--! @brief Blocker: <@ with encrypted root document and native jsonb.
--! @param a eql_v3.json Left operand (encrypted payload).
--! @param b jsonb Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_contained_json_jsonb(a eql_v3.json, b jsonb)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', '<@');
END;
$$ LANGUAGE plpgsql;

--! @brief Blocker: <@ with native jsonb and encrypted root document.
--! @param a jsonb Native LHS operand.
--! @param b eql_v3.json Right operand (encrypted payload).
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3.jsonb_blocked_contained_jsonb_json(a jsonb, b eql_v3.json)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3.encrypted_domain_unsupported_bool('eql_v3.json', '<@');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR @> (
  FUNCTION = eql_v3.jsonb_blocked_contains_json_jsonb,
  LEFTARG = eql_v3.json,
  RIGHTARG = jsonb
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3.jsonb_blocked_contains_jsonb_json,
  LEFTARG = jsonb,
  RIGHTARG = eql_v3.json
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3.jsonb_blocked_contained_json_jsonb,
  LEFTARG = eql_v3.json,
  RIGHTARG = jsonb
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3.jsonb_blocked_contained_jsonb_json,
  LEFTARG = jsonb,
  RIGHTARG = eql_v3.json
);
