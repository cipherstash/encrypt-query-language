-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/sem/ope_cllw/types.sql

--! @file v3/sem/ope_cllw/functions.sql
--! @brief CLLW OPE index-term extraction and comparison (eql_v3 SEM).

--! @brief Extract CLLW OPE index term from raw jsonb
--!
--! Returns the CLLW OPE ciphertext from the `op` field of an encrypted scalar
--! payload supplied as raw jsonb, hex-decoded to bytea. Inlinable
--! single-statement SQL — the planner folds the body into the calling query.
--!
--! **Missing-`op` semantics**: returns SQL-level NULL (not a composite with
--! NULL bytes) when `op` is absent, so btree's NULL handling filters those
--! rows from range queries.
--!
--! @param val jsonb An object carrying an `op` field
--! @return eql_v3.ope_cllw Composite carrying the CLLW OPE ciphertext, or
--!         NULL when the `op` field is absent.
--! @see eql_v3.has_ope_cllw
--! @see eql_v3.compare_ope_cllw_term
CREATE FUNCTION eql_v3.ope_cllw(val jsonb)
  RETURNS eql_v3.ope_cllw
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT CASE WHEN val ->> 'op' IS NULL THEN NULL
              ELSE ROW(decode(val ->> 'op', 'hex'))::eql_v3.ope_cllw
         END
$$;

COMMENT ON FUNCTION eql_v3.ope_cllw(jsonb) IS
  'eql-inline-critical: raw-jsonb CLLW OPE extractor; must stay inlinable (unpinned search_path)';

--! @brief Check if a raw jsonb value contains a CLLW OPE index term
--! @param val jsonb An object that may carry an `op` field
--! @return boolean True if `op` field is present and non-null
CREATE FUNCTION eql_v3.has_ope_cllw(val jsonb)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT val ->> 'op' IS NOT NULL
$$;

COMMENT ON FUNCTION eql_v3.has_ope_cllw(jsonb) IS
  'eql-inline-critical: raw-jsonb CLLW OPE presence helper; must stay inlinable (unpinned search_path)';

--! @brief Three-way CLLW OPE term comparison
--! @internal
--!
--! Btree support-function comparator for eql_v3.ope_cllw. The OPE ciphertext
--! is order-preserving under plain byte comparison, so this reduces to native
--! bytea three-way comparison of the decoded terms — no custom protocol.
--! Variable-length inputs compare with native bytea semantics (shorter prefix
--! sorts first), matching the operators in operators.sql.
--!
--! btree filters SQL-NULL composites at the row level (and the function is
--! STRICT), so a NULL composite never reaches the body. A non-NULL composite
--! with NULL `bytes` is a contract violation — the extractor returns SQL NULL
--! (not ROW(NULL)) on missing `op` — and yields NULL here rather than a
--! silent misorder.
--!
--! Carries a pinned search_path by design (like the CLLW ORE FUNCTION 1
--! comparator): it is only ever called through the btree operator class,
--! never from an inlinable index expression.
--!
--! @param a eql_v3.ope_cllw First term
--! @param b eql_v3.ope_cllw Second term
--! @return integer -1, 0, or 1; NULL if either composite has NULL bytes
--! @see eql_v3.ope_cllw
CREATE FUNCTION eql_v3.compare_ope_cllw_term(a eql_v3.ope_cllw, b eql_v3.ope_cllw)
  RETURNS int
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  SELECT CASE
    WHEN a.bytes IS NULL OR b.bytes IS NULL THEN NULL
    WHEN a.bytes < b.bytes THEN -1
    WHEN a.bytes > b.bytes THEN 1
    ELSE 0
  END
$$;
