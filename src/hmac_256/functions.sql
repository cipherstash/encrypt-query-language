-- REQUIRE: src/schema.sql
-- REQUIRE: src/hmac_256/types.sql
-- REQUIRE: src/ste_vec/types.sql

--! @brief Extract HMAC-SHA256 index term from JSONB payload
--!
--! Extracts the HMAC-SHA256 hash value from the 'hm' field of an encrypted
--! data payload. Inlinable single-statement SQL — the planner can fold this
--! into the calling query so functional hash indexes built on
--! `eql_v2.hmac_256(col)` engage structurally.
--!
--! @param jsonb containing encrypted EQL payload
--! @return eql_v2.hmac_256 HMAC-SHA256 hash value, or NULL when `hm` is absent
--!
--! @note Returns NULL when the payload lacks `hm`. Callers that need to
--!       surface misconfiguration loudly should use
--!       `eql_v2.hash_encrypted` (`GROUP BY` / `DISTINCT` / hash joins)
--!       which raises with a clear message when `hm` is missing.
--!
--! @see eql_v2.has_hmac_256
--! @see eql_v2.compare_hmac_256
--! @see eql_v2.hash_encrypted
CREATE FUNCTION eql_v2.hmac_256(val jsonb)
  RETURNS eql_v2.hmac_256
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT (val ->> 'hm')::eql_v2.hmac_256
$$;


--! @brief Check if JSONB payload contains HMAC-SHA256 index term
--!
--! Tests whether the encrypted data payload includes an 'hm' field,
--! indicating an HMAC-SHA256 hash is available for exact-match queries.
--!
--! @param jsonb containing encrypted EQL payload
--! @return Boolean True if 'hm' field is present and non-null
--!
--! @see eql_v2.hmac_256
CREATE FUNCTION eql_v2.has_hmac_256(val jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
	BEGIN
    RETURN val ->> 'hm' IS NOT NULL;
  END;
$$ LANGUAGE plpgsql;


--! @brief Check if encrypted column value contains HMAC-SHA256 index term
--!
--! Tests whether an encrypted column value includes an HMAC-SHA256 hash
--! by checking its underlying JSONB data field.
--!
--! @param eql_v2_encrypted Encrypted column value
--! @return Boolean True if HMAC-SHA256 hash is present
--!
--! @see eql_v2.has_hmac_256(jsonb)
CREATE FUNCTION eql_v2.has_hmac_256(val eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
	BEGIN
    RETURN eql_v2.has_hmac_256(val.data);
  END;
$$ LANGUAGE plpgsql;



--! @brief Extract HMAC-SHA256 index term from encrypted column value
--!
--! Extracts the HMAC-SHA256 hash from an encrypted column value. Inlinable
--! single-statement SQL — see the jsonb overload for the rationale.
--!
--! @param eql_v2_encrypted Encrypted column value
--! @return eql_v2.hmac_256 HMAC-SHA256 hash value, or NULL when `hm` is absent
--!
--! @see eql_v2.hmac_256(jsonb)
CREATE FUNCTION eql_v2.hmac_256(val eql_v2_encrypted)
  RETURNS eql_v2.hmac_256
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT ((val).data ->> 'hm')::eql_v2.hmac_256
$$;


--! @brief Extract HMAC-SHA256 index term from a ste_vec entry
--!
--! Extracts the HMAC from the `hm` field of an `sv` element extracted via
--! the `->` operator. Inlinable. The recipe for field-level equality on
--! encrypted JSON is:
--!
--! @example
--! -- Functional hash index
--! CREATE INDEX ON users USING hash (eql_v2.hmac_256(data -> '<selector>'));
--! -- Bare-form predicate matches via the inlined `=` on ste_vec_entry
--! SELECT * FROM users WHERE data -> '<selector>' = $1::eql_v2.ste_vec_entry;
--!
--! @param entry eql_v2.ste_vec_entry STE-vec entry (extracted via `->`)
--! @return eql_v2.hmac_256 HMAC value, or NULL when `hm` is absent
--!
--! @see eql_v2.has_hmac_256
--! @see src/operators/->.sql
CREATE FUNCTION eql_v2.hmac_256(entry eql_v2.ste_vec_entry)
  RETURNS eql_v2.hmac_256
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT (entry ->> 'hm')::eql_v2.hmac_256
$$;


--! @brief Check if a ste_vec entry contains an HMAC-SHA256 index term
--!
--! @param entry eql_v2.ste_vec_entry STE-vec entry
--! @return Boolean True if `hm` field is present and non-null
CREATE FUNCTION eql_v2.has_hmac_256(entry eql_v2.ste_vec_entry)
  RETURNS boolean
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT entry ->> 'hm' IS NOT NULL
$$;


