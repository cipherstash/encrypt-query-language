DROP DOMAIN IF EXISTS eql_v1.match_index;
CREATE DOMAIN eql_v1.match_index AS smallint[];

DROP DOMAIN IF EXISTS eql_v1.unique_index;
CREATE DOMAIN eql_v1.unique_index AS text;


-- cs_encrypted_v1 is a column type and cannot be dropped if in use
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'eql_v1_encrypted') THEN
      CREATE DOMAIN eql_v1_encrypted AS JSONB;
	  END IF;
END
$$;


-- Should include a kind field
DROP FUNCTION IF EXISTS eql_v1._encrypted_check_k(jsonb);
CREATE FUNCTION eql_v1._encrypted_check_k(val jsonb)
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
DROP FUNCTION IF EXISTS eql_v1._encrypted_check_k_ct(jsonb);
CREATE FUNCTION eql_v1._encrypted_check_k_ct(val jsonb)
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
DROP FUNCTION IF EXISTS eql_v1._encrypted_check_k_sv(jsonb);
CREATE FUNCTION eql_v1._encrypted_check_k_sv(val jsonb)
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
DROP FUNCTION IF EXISTS eql_v1._encrypted_check_p(jsonb);
CREATE FUNCTION eql_v1._encrypted_check_p(val jsonb)
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
DROP FUNCTION IF EXISTS eql_v1._encrypted_check_i(jsonb);
CREATE FUNCTION eql_v1._encrypted_check_i(val jsonb)
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
DROP FUNCTION IF EXISTS eql_v1._encrypted_check_q(jsonb);
CREATE FUNCTION eql_v1._encrypted_check_q(val jsonb)
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
DROP FUNCTION IF EXISTS eql_v1._encrypted_check_i_ct(jsonb);
CREATE FUNCTION eql_v1._encrypted_check_i_ct(val jsonb)
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
DROP FUNCTION IF EXISTS eql_v1._encrypted_check_v(jsonb);
CREATE FUNCTION eql_v1._encrypted_check_v(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF (val ? 'v') THEN
      RETURN true;
    END IF;
    RAISE 'Encrypted column missing version (v) field: %', val;
  END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS eql_v1.check_encrypted(val jsonb);

CREATE FUNCTION eql_v1.check_encrypted(val jsonb)
  RETURNS BOOLEAN
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
    RETURN (
      eql_v1._encrypted_check_v(val) AND
      eql_v1._encrypted_check_i(val) AND
      eql_v1._encrypted_check_k(val) AND
      eql_v1._encrypted_check_k_ct(val) AND
      eql_v1._encrypted_check_k_sv(val) AND
      eql_v1._encrypted_check_q(val) AND
      eql_v1._encrypted_check_p(val)
    );
END;

ALTER DOMAIN eql_v1_encrypted DROP CONSTRAINT IF EXISTS eql_v1_encrypted_check;

ALTER DOMAIN eql_v1_encrypted
  ADD CONSTRAINT eql_v1_encrypted_check CHECK (
   eql_v1.check_encrypted(VALUE)
);

