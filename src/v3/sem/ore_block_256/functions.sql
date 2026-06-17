-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/crypto.sql
-- REQUIRE: src/v3/common.sql
-- REQUIRE: src/v3/sem/ore_block_256/types.sql

--! @file v3/sem/ore_block_256/functions.sql
--! @brief ORE block construction, extraction, and comparison (eql_v3 SEM).
--!
--! jsonb-only subset of src/ore_block_u64_8_256/functions.sql. The
--! encrypted-column overloads are omitted; the helper jsonb_array_to_bytea_array
--! and pgcrypto encrypt() are reached via the forked src/v3/common.sql and
--! src/v3/crypto.sql so the whole closure stays under src/v3. (Doc comments
--! deliberately avoid naming eql_v2 symbols so the self-containment grep stays
--! clean.)

--! @brief Convert JSONB array to ORE block composite type
--! @internal
--! @param val jsonb Array of hex-encoded ORE block terms
--! @return eql_v3.ore_block_256 ORE block composite, or NULL if input is null
--! @note Inlinable `LANGUAGE sql` IMMUTABLE form (no `SET search_path`) so the
--!   planner can fold this per-encrypted-value helper into the calling query.
--!   This deliberately diverges from the v2 plpgsql equivalent (intentionally
--!   left unchanged): the `CASE WHEN jsonb_typeof(val) = 'array'` guard only
--!   evaluates the array path for an array, so a non-array JSON scalar returns
--!   NULL here instead of raising. The sole caller passes `val->'ob'`, always an
--!   array or JSON null, so the divergence is unreachable in practice; JSON null
--!   and empty array still return NULL exactly as before.
CREATE FUNCTION eql_v3.jsonb_array_to_ore_block_256(val jsonb)
RETURNS eql_v3.ore_block_256
  IMMUTABLE
AS $$
  SELECT CASE WHEN jsonb_typeof(val) = 'array'
    THEN ROW((
      SELECT array_agg(ROW(b)::eql_v3.ore_block_256_term)
      FROM unnest(eql_v3.jsonb_array_to_bytea_array(val)) AS b
    ))::eql_v3.ore_block_256
    ELSE NULL
  END;
$$ LANGUAGE sql;

--! @internal Mark this hand-written helper inline-critical so the post-install
--! pin_search_path pass leaves it unpinned (no `SET search_path`), preserving
--! SQL-function inlining. It takes a bare `jsonb` arg (not a jsonb-backed
--! encrypted DOMAIN), so the structural skip in tasks/pin_search_path.sql does
--! not recognise it; this marker is the documented manual opt-in.
COMMENT ON FUNCTION eql_v3.jsonb_array_to_ore_block_256(jsonb) IS
  'eql-inline-critical: per-encrypted-value ORE helper; must stay inlinable (unpinned search_path)';


--! @brief Extract ORE block index term from JSONB payload
--! @param val jsonb containing encrypted EQL payload
--! @return eql_v3.ore_block_256 ORE block index term
--! @throws Exception if 'ob' field is missing
CREATE FUNCTION eql_v3.ore_block_256(val jsonb)
  RETURNS eql_v3.ore_block_256
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  BEGIN
    -- Declared STRICT: PostgreSQL returns NULL for a NULL argument without
    -- entering the body, so no explicit `val IS NULL` guard is needed.
    IF eql_v3.has_ore_block_256(val) THEN
      RETURN eql_v3.jsonb_array_to_ore_block_256(val->'ob');
    END IF;
    RAISE 'Expected an ore index (ob) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;


--! @brief Check if JSONB payload contains ORE block index term
--! @param val jsonb containing encrypted EQL payload
--! @return boolean True if 'ob' field is present and non-null
CREATE FUNCTION eql_v3.has_ore_block_256(val jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  BEGIN
    RETURN val ->> 'ob' IS NOT NULL;
  END;
$$ LANGUAGE plpgsql;


--! @brief Compare two ORE block terms using cryptographic comparison
--! @internal
--! @param a eql_v3.ore_block_256_term First ORE term
--! @param b eql_v3.ore_block_256_term Second ORE term
--! @return integer -1 if a < b, 0 if a = b, 1 if a > b
--! @throws Exception if ciphertexts are different lengths
--! @note Marked `IMMUTABLE` (the three `compare_ore_block_256_term(s)`
--!   overloads all are). This deliberately diverges from the v2 originals,
--!   which carry no volatility marker and so default to `VOLATILE`. The
--!   comparison is deterministic — its only crypto call, pgcrypto `encrypt()`,
--!   is itself `IMMUTABLE STRICT PARALLEL SAFE` — so `IMMUTABLE` lets the
--!   planner fold/cache these in ordering and index contexts. NOT `STRICT`:
--!   the NULL-handling branches below are load-bearing for the array overload.
CREATE FUNCTION eql_v3.compare_ore_block_256_term(a eql_v3.ore_block_256_term, b eql_v3.ore_block_256_term)
  RETURNS integer
  IMMUTABLE
  SET search_path = pg_catalog, extensions, public
AS $$
  DECLARE
    eq boolean := true;
    unequal_block smallint := 0;
    hash_key bytea;
    data_block bytea;
    encrypt_block bytea;
    target_block bytea;

    left_block_size CONSTANT smallint := 16;
    right_block_size CONSTANT smallint := 32;
    right_offset CONSTANT smallint := 136; -- 8 * 17

    indicator smallint := 0;
  BEGIN
    IF a IS NULL AND b IS NULL THEN
      RETURN 0;
    END IF;

    IF a IS NULL THEN
      RETURN -1;
    END IF;

    IF b IS NULL THEN
      RETURN 1;
    END IF;

    IF bit_length(a.bytes) != bit_length(b.bytes) THEN
      RAISE EXCEPTION 'Ciphertexts are different lengths';
    END IF;

    FOR block IN 0..7 LOOP
      IF
        substr(a.bytes, 1 + block, 1) != substr(b.bytes, 1 + block, 1)
        OR substr(a.bytes, 9 + left_block_size * block, left_block_size) != substr(b.bytes, 9 + left_block_size * block, left_block_size)
      THEN
        IF eq THEN
          unequal_block := block;
        END IF;
        eq = false;
      END IF;
    END LOOP;

    IF eq THEN
      RETURN 0::integer;
    END IF;

    hash_key := substr(b.bytes, right_offset + 1, 16);

    target_block := substr(b.bytes, right_offset + 17 + (unequal_block * right_block_size), right_block_size);

    data_block := substr(a.bytes, 9 + (left_block_size * unequal_block), left_block_size);

    encrypt_block := encrypt(data_block::bytea, hash_key::bytea, 'aes-ecb');

    indicator := (
      get_bit(
        encrypt_block,
        0
      ) + get_bit(target_block, get_byte(a.bytes, unequal_block))) % 2;

    IF indicator = 1 THEN
      RETURN 1::integer;
    ELSE
      RETURN -1::integer;
    END IF;
  END;
$$ LANGUAGE plpgsql;


--! @brief Compare arrays of ORE block terms recursively
--! @internal
--! @param a eql_v3.ore_block_256_term[] First array
--! @param b eql_v3.ore_block_256_term[] Second array
--! @return integer -1/0/1, or NULL if either array is NULL
CREATE FUNCTION eql_v3.compare_ore_block_256_terms(a eql_v3.ore_block_256_term[], b eql_v3.ore_block_256_term[])
RETURNS integer
  IMMUTABLE
  SET search_path = pg_catalog, extensions, public
AS $$
  DECLARE
    cmp_result integer;
  BEGIN
    IF a IS NULL OR b IS NULL THEN
      RETURN NULL;
    END IF;

    IF cardinality(a) = 0 AND cardinality(b) = 0 THEN
      RETURN 0;
    END IF;

    IF (cardinality(a) = 0) AND cardinality(b) > 0 THEN
      RETURN -1;
    END IF;

    IF cardinality(a) > 0 AND (cardinality(b) = 0) THEN
      RETURN 1;
    END IF;

    cmp_result := eql_v3.compare_ore_block_256_term(a[1], b[1]);

    IF cmp_result = 0 THEN
      RETURN eql_v3.compare_ore_block_256_terms(a[2:array_length(a,1)], b[2:array_length(b,1)]);
    END IF;

    RETURN cmp_result;
  END
$$ LANGUAGE plpgsql;


--! @brief Compare ORE block composite types
--! @internal
--! @param a eql_v3.ore_block_256 First ORE block
--! @param b eql_v3.ore_block_256 Second ORE block
--! @return integer -1/0/1
CREATE FUNCTION eql_v3.compare_ore_block_256_terms(a eql_v3.ore_block_256, b eql_v3.ore_block_256)
RETURNS integer
  IMMUTABLE
  SET search_path = pg_catalog, extensions, public
AS $$
  BEGIN
    RETURN eql_v3.compare_ore_block_256_terms(a.terms, b.terms);
  END
$$ LANGUAGE plpgsql;
