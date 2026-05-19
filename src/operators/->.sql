-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql

--! @brief JSONB field accessor operator for encrypted values (->)
--!
--! Implements the -> operator to access fields/elements from encrypted JSONB data.
--! Returns encrypted value matching the provided selector without decryption.
--!
--! Encrypted JSON is represented as an array of eql_v2_encrypted values in the ste_vec format.
--! Each element has a selector, ciphertext, and index terms:
--!     {"sv": [{"c": "", "s": "", "hm": ""}]}
--!
--! Provides three overloads:
--! - (eql_v2_encrypted, text) - Field name selector
--! - (eql_v2_encrypted, eql_v2_encrypted) - Encrypted selector
--! - (eql_v2_encrypted, integer) - Array index selector (0-based)
--!
--! @note Operator resolution: Assignment casts are considered (PostgreSQL standard behavior).
--! To use text selector, parameter may need explicit cast to text.
--!
--! @see eql_v2.ste_vec
--! @see eql_v2.selector
--! @see eql_v2."->>"

--! @brief -> operator with text selector
--!
--! Walks the encrypted document's `sv` array, picks the entry whose
--! selector matches, and returns it merged with the source payload's
--! `i` / `v` metadata as a new `eql_v2_encrypted`. Selectors are
--! deterministic per (path, key), so at most one entry matches; the
--! loop exits early on the first hit.
--!
--! Caveat. The merged return — `meta || sv_entry` — is a synthetic
--! shape: it has root-level `i` / `v` plus sv-element-level `s` / `c`
--! / `hm`-or-`oc`. It's not a strictly-valid `EncryptedPayload`
--! (root has no `s`) and not a strictly-valid `SteVecElement` (entry
--! has no `i` / `v`). Callers chain off `.data` to feed typed
--! extractors like `eql_v2.ore_cllw(.data::eql_v2.ste_vec_entry)`. A
--! future refactor may flip this function's return type to
--! `eql_v2.ste_vec_entry` so the typed chain is direct; until then
--! the wrap-then-cast pattern is the canonical recipe.
--!
--! @param eql_v2_encrypted Encrypted JSONB data
--! @param text Field name to extract
--! @return eql_v2_encrypted Encrypted value at selector, NULL if no match
--! @example
--! SELECT encrypted_json -> 'field_name' FROM table;
CREATE FUNCTION eql_v2."->"(e eql_v2_encrypted, selector text)
  RETURNS eql_v2_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  DECLARE
    meta jsonb;
    sv eql_v2_encrypted[];
    found jsonb;
	BEGIN

    IF e IS NULL THEN
      RETURN NULL;
    END IF;

    -- Column identifier and version
    meta := eql_v2.meta_data(e);

    sv := eql_v2.ste_vec(e);

    -- Linear scan with early EXIT on first match. Selectors are
    -- unique per (path, key) within a document, so at most one entry
    -- matches and continuing past the first hit is wasted work.
    FOR idx IN 1..array_length(sv, 1) LOOP
      if eql_v2.selector(sv[idx]) = selector THEN
        found := sv[idx];
        EXIT;
      END IF;
    END LOOP;

    IF found IS NULL THEN
      RETURN NULL;
    END IF;

    RETURN (meta || found)::eql_v2_encrypted;
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR ->(
  FUNCTION=eql_v2."->",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=text
);

---------------------------------------------------

--! @brief -> operator with encrypted selector
--! @param e eql_v2_encrypted Encrypted JSONB data
--! @param selector eql_v2_encrypted Encrypted field selector
--! @return eql_v2_encrypted Encrypted value at selector
--! @see eql_v2."->"(eql_v2_encrypted, text)
CREATE FUNCTION eql_v2."->"(e eql_v2_encrypted, selector eql_v2_encrypted)
  RETURNS eql_v2_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
	BEGIN
    RETURN eql_v2."->"(e, eql_v2.selector(selector));
  END;
$$ LANGUAGE plpgsql;



CREATE OPERATOR ->(
  FUNCTION=eql_v2."->",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted
);


---------------------------------------------------

--! @brief -> operator with integer array index
--! @param eql_v2_encrypted Encrypted array data
--! @param integer Array index (0-based, JSONB convention)
--! @return eql_v2_encrypted Encrypted value at array index
--! @note Array index is 0-based (JSONB standard) despite PostgreSQL arrays being 1-based
--! @example
--! SELECT encrypted_array -> 0 FROM table;
--! @see eql_v2.is_ste_vec_array
CREATE FUNCTION eql_v2."->"(e eql_v2_encrypted, selector integer)
  RETURNS eql_v2_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  DECLARE
    sv eql_v2_encrypted[];
    found eql_v2_encrypted;
	BEGIN
    IF NOT eql_v2.is_ste_vec_array(e) THEN
      RETURN NULL;
    END IF;

    sv := eql_v2.ste_vec(e);

    -- PostgreSQL arrays are 1-based
    -- JSONB arrays are 0-based and so the selector is 0-based
    FOR idx IN 1..array_length(sv, 1) LOOP
      if (idx-1) = selector THEN
        found := sv[idx];
      END IF;
    END LOOP;

    RETURN found;
  END;
$$ LANGUAGE plpgsql;





CREATE OPERATOR ->(
  FUNCTION=eql_v2."->",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=integer
);

