DROP DOMAIN IF EXISTS cs_match_index_v1;
CREATE DOMAIN cs_match_index_v1 AS smallint[];

DROP DOMAIN IF EXISTS cs_unique_index_v1;
CREATE DOMAIN cs_unique_index_v1 AS text;


-- cs_encrypted_v1 is a column type and cannot be dropped if in use
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'cs_encrypted_v1') THEN
      CREATE DOMAIN cs_encrypted_v1 AS JSONB;
	  END IF;
END
$$;


-- Should include a kind field
DROP FUNCTION IF EXISTS _cs_encrypted_check_k(jsonb);
CREATE FUNCTION _cs_encrypted_check_k(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF (val->>'k' = ANY('{ct, sv}')) THEN
      RETURN true;
    END IF;
    RAISE 'Invalid kind (%) in Encrypted column. Kind should be one of {ct, sv}', val;
  END;
$$ LANGUAGE plpgsql;


--
-- CT payload should include a c field
--
DROP FUNCTION IF EXISTS _cs_encrypted_check_k_ct(jsonb);
CREATE FUNCTION _cs_encrypted_check_k_ct(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF (val->>'k' = 'ct') THEN
      IF (val ? 'c') THEN
        RETURN true;
      END IF;
      RAISE 'Encrypted column kind (k) of "ct" missing data field (c):  %', val;
    END IF;
    RETURN true;
  END;
$$ LANGUAGE plpgsql;


--
-- SV payload should include an sv field
--
DROP FUNCTION IF EXISTS _cs_encrypted_check_k_sv(jsonb);
CREATE FUNCTION _cs_encrypted_check_k_sv(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF (val->>'k' = 'sv') THEN
      IF (val ? 'sv') THEN
        RETURN true;
      END IF;
      RAISE 'Encrypted column kind (k) of "sv" missing data field (sv):  %', val;
    END IF;
    RETURN true;
  END;
$$ LANGUAGE plpgsql;


-- Plaintext field should never be present in an encrypted column
DROP FUNCTION IF EXISTS _cs_encrypted_check_p(jsonb);
CREATE FUNCTION _cs_encrypted_check_p(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF NOT val ? 'p' THEN
      RETURN true;
    END IF;
    RAISE 'Encrypted column includes plaintext (p) field: %', val;
  END;
$$ LANGUAGE plpgsql;

-- Should include an ident field
DROP FUNCTION IF EXISTS _cs_encrypted_check_i(jsonb);
CREATE FUNCTION _cs_encrypted_check_i(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF val ? 'i' THEN
      RETURN true;
    END IF;
    RAISE 'Encrypted column missing ident (i) field: %', val;
  END;
$$ LANGUAGE plpgsql;

-- Query field should never be present in an encrypted column
DROP FUNCTION IF EXISTS _cs_encrypted_check_q(jsonb);
CREATE FUNCTION _cs_encrypted_check_q(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF val ? 'q' THEN
      RAISE 'Encrypted column includes query (q) field: %', val;
    END IF;
    RETURN true;
  END;
$$ LANGUAGE plpgsql;

-- Ident field should include table and column
DROP FUNCTION IF EXISTS _cs_encrypted_check_i_ct(jsonb);
CREATE FUNCTION _cs_encrypted_check_i_ct(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF (val->'i' ?& array['t', 'c']) THEN
      RETURN true;
    END IF;
    RAISE 'Encrypted column ident (i) missing table (t) or column (c) fields: %', val;
  END;
$$ LANGUAGE plpgsql;

-- Should include a version field
DROP FUNCTION IF EXISTS _cs_encrypted_check_v(jsonb);
CREATE FUNCTION _cs_encrypted_check_v(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF (val ? 'v') THEN
      RETURN true;
    END IF;
    RAISE 'Encrypted column missing version (v) field: %', val;
  END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS cs_check_encrypted_v1(val jsonb);

CREATE FUNCTION cs_check_encrypted_v1(val jsonb)
  RETURNS BOOLEAN
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
    RETURN (
      _cs_encrypted_check_v(val) AND
      _cs_encrypted_check_i(val) AND
      _cs_encrypted_check_k(val) AND
      _cs_encrypted_check_k_ct(val) AND
      _cs_encrypted_check_k_sv(val) AND
      _cs_encrypted_check_q(val) AND
      _cs_encrypted_check_p(val)
    );
END;

ALTER DOMAIN cs_encrypted_v1 DROP CONSTRAINT IF EXISTS cs_encrypted_v1_check;

ALTER DOMAIN cs_encrypted_v1
  ADD CONSTRAINT cs_encrypted_v1_check CHECK (
   cs_check_encrypted_v1(VALUE)
);

