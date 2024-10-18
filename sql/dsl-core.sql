DROP CAST IF EXISTS (text AS ore_64_8_v1_term);

DROP FUNCTION IF EXISTS cs_match_v1;
DROP FUNCTION IF EXISTS cs_match_v1_v0;
DROP FUNCTION IF EXISTS cs_match_v1_v0_0;

DROP FUNCTION IF EXISTS cs_unique_v1;
DROP FUNCTION IF EXISTS cs_unique_v1_v0;
DROP FUNCTION IF EXISTS cs_unique_v1_v0_0;

DROP FUNCTION IF EXISTS cs_ore_64_8_v1;
DROP FUNCTION IF EXISTS cs_ore_64_8_v1_v0;
DROP FUNCTION IF EXISTS cs_ore_64_8_v1_v0_0;

DROP FUNCTION IF EXISTS _cs_text_to_ore_64_8_v1_term_v1_0;

DROP DOMAIN IF EXISTS cs_match_index_v1;
DROP DOMAIN IF EXISTS cs_unique_index_v1;

CREATE DOMAIN cs_match_index_v1 AS smallint[];
CREATE DOMAIN cs_unique_index_v1 AS text;
CREATE DOMAIN cs_ste_vec_index_v1 AS text[];

-- cs_encrypted_v1 is a column type and cannot be dropped if in use
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'cs_encrypted_v1') THEN
      CREATE DOMAIN cs_encrypted_v1 AS JSONB;
	  END IF;
END
$$;

DROP FUNCTION IF EXISTS _cs_encrypted_check_kind(jsonb);
CREATE FUNCTION _cs_encrypted_check_kind(val jsonb)
  RETURNS BOOLEAN
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
  RETURN (val->>'k' = 'ct' AND val ? 'c') AND NOT val ? 'p';
END;


-- drop and reset the check constraint
ALTER DOMAIN cs_encrypted_v1 DROP CONSTRAINT IF EXISTS cs_encrypted_v1_check;

ALTER DOMAIN cs_encrypted_v1
  ADD CONSTRAINT cs_encrypted_v1_check CHECK (
    -- version and source are required
    VALUE ?& array['v'] AND

    -- table and column
    VALUE->'i' ?& array['t', 'c'] AND

    -- plaintext or ciphertext for kind
    _cs_encrypted_check_kind(VALUE)

);

CREATE OR REPLACE FUNCTION cs_ciphertext_v1_v0_0(col jsonb)
    RETURNS text
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	RETURN col->>'c';
END;

CREATE OR REPLACE FUNCTION cs_ciphertext_v1_v0(col jsonb)
    RETURNS text
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	RETURN cs_ciphertext_v1_v0_0(col);
END;

CREATE OR REPLACE FUNCTION cs_ciphertext_v1(col jsonb)
    RETURNS text
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	RETURN cs_ciphertext_v1_v0_0(col);
END;

-- extracts match index from an emcrypted column
CREATE OR REPLACE FUNCTION cs_match_v1_v0_0(col jsonb)
  RETURNS cs_match_index_v1
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	SELECT ARRAY(SELECT jsonb_array_elements(col->'m'))::cs_match_index_v1;
END;

CREATE OR REPLACE FUNCTION cs_match_v1_v0(col jsonb)
  RETURNS cs_match_index_v1
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	RETURN cs_match_v1_v0_0(col);
END;

CREATE OR REPLACE FUNCTION cs_match_v1(col jsonb)
  RETURNS cs_match_index_v1
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	RETURN cs_match_v1_v0_0(col);
END;

-- extracts unique index from an encrypted column
CREATE OR REPLACE FUNCTION cs_unique_v1_v0_0(col jsonb)
  RETURNS cs_unique_index_v1
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	RETURN col->>'u';
END;

CREATE OR REPLACE FUNCTION cs_unique_v1_v0(col jsonb)
  RETURNS cs_unique_index_v1
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	RETURN cs_unique_v1_v0_0(col);
END;

CREATE OR REPLACE FUNCTION cs_unique_v1(col jsonb)
  RETURNS cs_unique_index_v1
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	RETURN cs_unique_v1_v0_0(col);
END;

-- extracts json ste_vec index from an encrypted column
CREATE OR REPLACE FUNCTION cs_ste_vec_v1_v0_0(col jsonb)
  RETURNS cs_ste_vec_index_v1
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	SELECT ARRAY(SELECT jsonb_array_elements(col->'sv'))::cs_ste_vec_index_v1;
END;

CREATE OR REPLACE FUNCTION cs_ste_vec_v1_v0(col jsonb)
  RETURNS cs_ste_vec_index_v1
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	RETURN cs_ste_vec_v1_v0_0(col);
END;

CREATE OR REPLACE FUNCTION cs_ste_vec_v1(col jsonb)
  RETURNS cs_ste_vec_index_v1
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	RETURN cs_ste_vec_v1_v0_0(col);
END;

-- casts text to ore_64_8_v1_term (bytea)
CREATE FUNCTION _cs_text_to_ore_64_8_v1_term_v1_0(t text)
  RETURNS ore_64_8_v1_term
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	RETURN t::bytea;
END;

-- cast to cleanup ore_64_8_v1 extraction
CREATE CAST (text AS ore_64_8_v1_term)
	WITH FUNCTION _cs_text_to_ore_64_8_v1_term_v1_0(text) AS IMPLICIT;

-- extracts ore index from an encrypted column
CREATE FUNCTION cs_ore_64_8_v1_v0_0(val jsonb)
  RETURNS ore_64_8_v1
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
  SELECT (val->>'o')::ore_64_8_v1;
END;

CREATE FUNCTION cs_ore_64_8_v1_v0(col jsonb)
  RETURNS ore_64_8_v1
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	RETURN cs_ore_64_8_v1_v0_0(col);
END;

CREATE FUNCTION cs_ore_64_8_v1(col jsonb)
  RETURNS ore_64_8_v1
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	RETURN cs_ore_64_8_v1_v0_0(col);
END;
