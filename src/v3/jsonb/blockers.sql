-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/jsonb/types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file v3/jsonb/blockers.sql
--! @brief Native-jsonb firewall for public.json.
--!
--! public.json SUPPORTS @> <@ -> ->> (see operators.sql). Comparisons
--! = <> < <= > >= are supported on public.jsonb_entry only, not on the root
--! document domain.
--! Every OTHER native jsonb operator reachable via domain fallback against the
--! base type jsonb is BLOCKED here so an encrypted column can never silently
--! route to plaintext-jsonb semantics. The blocked set is KNOWN_JSONB_OPERATORS
--! minus the supported ops: ? ?| ?& @? @@ #> #>> - #- ||.
--!
--! Each blocker is LANGUAGE plpgsql (NEVER STRICT — a STRICT blocker would let
--! PostgreSQL skip the body and return NULL on a NULL argument, bypassing the
--! exception) and delegates to the shared eql_v3.encrypted_domain_unsupported_*
--! helpers. Each blocker's RETURNS type matches the native operator it shadows
--! (#> -> jsonb, #>> -> text, - / #- / || -> jsonb; the rest are boolean) so a
--! composed expression resolves and the body raises 'operator not supported',
--! rather than failing earlier with a misleading 'operator does not exist' on a
--! boolean intermediate. The bound operator must resolve before native fallback,
--! so the firewall fires.

--! @brief Blocker: ? (key/element exists).
--! @param a public.json Left operand (encrypted payload).
--! @param b text Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_exists(a public.json, b text)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_bool('public.json', '?');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR ? (
  FUNCTION = eql_v3_internal.jsonb_blocked_exists,
  LEFTARG = public.json,
  RIGHTARG = text
);

--! @brief Blocker: ?| (any key exists).
--! @param a public.json Left operand (encrypted payload).
--! @param b text[] Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_exists_any(a public.json, b text[])
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_bool('public.json', '?|');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR ?| (
  FUNCTION = eql_v3_internal.jsonb_blocked_exists_any,
  LEFTARG = public.json,
  RIGHTARG = text[]
);

--! @brief Blocker: ?& (all keys exist).
--! @param a public.json Left operand (encrypted payload).
--! @param b text[] Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_exists_all(a public.json, b text[])
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_bool('public.json', '?&');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR ?& (
  FUNCTION = eql_v3_internal.jsonb_blocked_exists_all,
  LEFTARG = public.json,
  RIGHTARG = text[]
);

--! @brief Blocker: @? (jsonpath exists).
--! @param a public.json Left operand (encrypted payload).
--! @param b jsonpath Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_jsonpath_exists(a public.json, b jsonpath)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_bool('public.json', '@?');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR @? (
  FUNCTION = eql_v3_internal.jsonb_blocked_jsonpath_exists,
  LEFTARG = public.json,
  RIGHTARG = jsonpath
);

--! @brief Blocker: @@ (jsonpath predicate).
--! @param a public.json Left operand (encrypted payload).
--! @param b jsonpath Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_jsonpath_match(a public.json, b jsonpath)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_bool('public.json', '@@');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR @@ (
  FUNCTION = eql_v3_internal.jsonb_blocked_jsonpath_match,
  LEFTARG = public.json,
  RIGHTARG = jsonpath
);

--! @brief Blocker: #> (path extract, native returns jsonb).
--! @param a public.json Left operand (encrypted payload).
--! @param b text[] Native RHS operand.
--! @return jsonb Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_path_extract(a public.json, b text[])
RETURNS jsonb
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_jsonb('public.json', '#>');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR #> (
  FUNCTION = eql_v3_internal.jsonb_blocked_path_extract,
  LEFTARG = public.json,
  RIGHTARG = text[]
);

--! @brief Blocker: #>> (path extract as text).
--! @param a public.json Left operand (encrypted payload).
--! @param b text[] Native RHS operand.
--! @return text Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_path_extract_text(a public.json, b text[])
RETURNS text
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_text('public.json', '#>>');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR #>> (
  FUNCTION = eql_v3_internal.jsonb_blocked_path_extract_text,
  LEFTARG = public.json,
  RIGHTARG = text[]
);

--! @brief Blocker: - (delete key, text RHS; native returns jsonb).
--! @param a public.json Left operand (encrypted payload).
--! @param b text Native RHS operand.
--! @return jsonb Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_delete_text(a public.json, b text)
RETURNS jsonb
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_jsonb('public.json', '-');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal.jsonb_blocked_delete_text,
  LEFTARG = public.json,
  RIGHTARG = text
);

--! @brief Blocker: - (delete index, integer RHS).
--! @param a public.json Left operand (encrypted payload).
--! @param b integer Native RHS operand.
--! @return jsonb Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_delete_int(a public.json, b integer)
RETURNS jsonb
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_jsonb('public.json', '-');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal.jsonb_blocked_delete_int,
  LEFTARG = public.json,
  RIGHTARG = integer
);

--! @brief Blocker: - (delete keys, text[] RHS).
--! @param a public.json Left operand (encrypted payload).
--! @param b text[] Native RHS operand.
--! @return jsonb Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_delete_array(a public.json, b text[])
RETURNS jsonb
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_jsonb('public.json', '-');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal.jsonb_blocked_delete_array,
  LEFTARG = public.json,
  RIGHTARG = text[]
);

--! @brief Blocker: #- (delete at path).
--! @param a public.json Left operand (encrypted payload).
--! @param b text[] Native RHS operand.
--! @return jsonb Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_delete_path(a public.json, b text[])
RETURNS jsonb
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_jsonb('public.json', '#-');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR #- (
  FUNCTION = eql_v3_internal.jsonb_blocked_delete_path,
  LEFTARG = public.json,
  RIGHTARG = text[]
);

--! @brief Blocker: || (concatenate, encrypted on the left).
--! @param a public.json Left operand (encrypted payload).
--! @param b jsonb Native RHS operand.
--! @return jsonb Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_concat(a public.json, b jsonb)
RETURNS jsonb
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_jsonb('public.json', '||');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal.jsonb_blocked_concat,
  LEFTARG = public.json,
  RIGHTARG = jsonb
);

--! @brief Blocker: || (concatenate, encrypted on the right).
--! @param a jsonb Native LHS operand.
--! @param b public.json Right operand (encrypted payload).
--! @return jsonb Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_concat_rhs(a jsonb, b public.json)
RETURNS jsonb
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_jsonb('public.json', '||');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal.jsonb_blocked_concat_rhs,
  LEFTARG = jsonb,
  RIGHTARG = public.json
);

------------------------------------------------------------------------------
-- Root-document comparison blockers.
------------------------------------------------------------------------------

--! @brief Blocker: root public.json document comparisons.
--! @param a public.json Left operand (encrypted payload).
--! @param b public.json Right operand (encrypted payload).
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_compare_json_json(a public.json, b public.json)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_bool('public.json', 'comparison');
END;
$$ LANGUAGE plpgsql;

--! @brief Blocker: root public.json-to-jsonb comparisons.
--! @param a public.json Left operand (encrypted payload).
--! @param b jsonb Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_compare_json_jsonb(a public.json, b jsonb)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_bool('public.json', 'comparison');
END;
$$ LANGUAGE plpgsql;

--! @brief Blocker: root jsonb-to-public.json comparisons.
--! @param a jsonb Native LHS operand.
--! @param b public.json Right operand (encrypted payload).
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_compare_jsonb_json(a jsonb, b public.json)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_bool('public.json', 'comparison');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.jsonb_blocked_compare_json_json,
  LEFTARG = public.json,
  RIGHTARG = public.json
);

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.jsonb_blocked_compare_json_jsonb,
  LEFTARG = public.json,
  RIGHTARG = jsonb
);

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.jsonb_blocked_compare_jsonb_json,
  LEFTARG = jsonb,
  RIGHTARG = public.json
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.jsonb_blocked_compare_json_json,
  LEFTARG = public.json,
  RIGHTARG = public.json
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.jsonb_blocked_compare_json_jsonb,
  LEFTARG = public.json,
  RIGHTARG = jsonb
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.jsonb_blocked_compare_jsonb_json,
  LEFTARG = jsonb,
  RIGHTARG = public.json
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.jsonb_blocked_compare_json_json,
  LEFTARG = public.json,
  RIGHTARG = public.json
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.jsonb_blocked_compare_json_jsonb,
  LEFTARG = public.json,
  RIGHTARG = jsonb
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.jsonb_blocked_compare_jsonb_json,
  LEFTARG = jsonb,
  RIGHTARG = public.json
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.jsonb_blocked_compare_json_json,
  LEFTARG = public.json,
  RIGHTARG = public.json
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.jsonb_blocked_compare_json_jsonb,
  LEFTARG = public.json,
  RIGHTARG = jsonb
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.jsonb_blocked_compare_jsonb_json,
  LEFTARG = jsonb,
  RIGHTARG = public.json
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.jsonb_blocked_compare_json_json,
  LEFTARG = public.json,
  RIGHTARG = public.json
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.jsonb_blocked_compare_json_jsonb,
  LEFTARG = public.json,
  RIGHTARG = jsonb
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.jsonb_blocked_compare_jsonb_json,
  LEFTARG = jsonb,
  RIGHTARG = public.json
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.jsonb_blocked_compare_json_json,
  LEFTARG = public.json,
  RIGHTARG = public.json
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.jsonb_blocked_compare_json_jsonb,
  LEFTARG = public.json,
  RIGHTARG = jsonb
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.jsonb_blocked_compare_jsonb_json,
  LEFTARG = jsonb,
  RIGHTARG = public.json
);

------------------------------------------------------------------------------
-- Mixed jsonb containment blockers.
------------------------------------------------------------------------------

--! @brief Blocker: @> with encrypted root document and native jsonb.
--! @param a public.json Left operand (encrypted payload).
--! @param b jsonb Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_contains_json_jsonb(a public.json, b jsonb)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_bool('public.json', '@>');
END;
$$ LANGUAGE plpgsql;

--! @brief Blocker: @> with native jsonb and encrypted root document.
--! @param a jsonb Native LHS operand.
--! @param b public.json Right operand (encrypted payload).
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_contains_jsonb_json(a jsonb, b public.json)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_bool('public.json', '@>');
END;
$$ LANGUAGE plpgsql;

--! @brief Blocker: <@ with encrypted root document and native jsonb.
--! @param a public.json Left operand (encrypted payload).
--! @param b jsonb Native RHS operand.
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_contained_json_jsonb(a public.json, b jsonb)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_bool('public.json', '<@');
END;
$$ LANGUAGE plpgsql;

--! @brief Blocker: <@ with native jsonb and encrypted root document.
--! @param a jsonb Native LHS operand.
--! @param b public.json Right operand (encrypted payload).
--! @return boolean Never returns; always raises 'operator not supported'.
CREATE FUNCTION eql_v3_internal.jsonb_blocked_contained_jsonb_json(a jsonb, b public.json)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN eql_v3_internal.encrypted_domain_unsupported_bool('public.json', '<@');
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.jsonb_blocked_contains_json_jsonb,
  LEFTARG = public.json,
  RIGHTARG = jsonb
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.jsonb_blocked_contains_jsonb_json,
  LEFTARG = jsonb,
  RIGHTARG = public.json
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.jsonb_blocked_contained_json_jsonb,
  LEFTARG = public.json,
  RIGHTARG = jsonb
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.jsonb_blocked_contained_jsonb_json,
  LEFTARG = jsonb,
  RIGHTARG = public.json
);
