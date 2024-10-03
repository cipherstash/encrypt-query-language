--
-- PostgreSQL CipherStash Extension
--

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

-- CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: ore_64_8_v1_term; Type: TYPE; Schema: public;
--

CREATE TYPE public.ore_64_8_v1_term AS (
	bytes bytea
);

--
-- Name: ore_64_8_v1; Type: TYPE; Schema: public;
--

CREATE TYPE public.ore_64_8_v1 AS (
	terms public.ore_64_8_v1_term[]
);

--
-- Name: compare_ore_64_8_v1(public.ore_64_8_v1, public.ore_64_8_v1); Type: FUNCTION; Schema: public;
--

CREATE FUNCTION public.compare_ore_64_8_v1(a public.ore_64_8_v1, b public.ore_64_8_v1) RETURNS integer
    LANGUAGE plpgsql
    AS $$
  DECLARE
    cmp_result integer;
  BEGIN
    -- Recursively compare blocks bailing as soon as we can make a decision
    RETURN compare_ore_array(a.terms, b.terms);
  END
$$;

--
-- Name: compare_ore_64_8_v1_term(public.ore_64_8_v1_term, public.ore_64_8_v1_term); Type: FUNCTION; Schema: public;
--

CREATE FUNCTION public.compare_ore_64_8_v1_term(a public.ore_64_8_v1_term, b public.ore_64_8_v1_term) RETURNS integer
    LANGUAGE plpgsql
    AS $$
  DECLARE
    eq boolean := true;
    unequal_block smallint := 0;
    hash_key bytea;
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
      -- Compare each PRP (byte from the first 8 bytes) and PRF block (8 byte
      -- chunks of the rest of the value).
      -- NOTE:
      -- * Substr is ordinally indexed (hence 1 and not 0, and 9 and not 8).
      -- * We are not worrying about timing attacks here; don't fret about
      --   the OR or !=.
      IF
        substr(a.bytes, 1 + block, 1) != substr(b.bytes, 1 + block, 1)
        OR substr(a.bytes, 9 + left_block_size * block, left_block_size) != substr(b.bytes, 9 + left_block_size * BLOCK, left_block_size)
      THEN
        -- set the first unequal block we find
        IF eq THEN
          unequal_block := block;
        END IF;
        eq = false;
      END IF;
    END LOOP;

    IF eq THEN
      RETURN 0::integer;
    END IF;

    -- Hash key is the IV from the right CT of b
    hash_key := substr(b.bytes, right_offset + 1, 16);

    -- first right block is at right offset + nonce_size (ordinally indexed)
    target_block := substr(b.bytes, right_offset + 17 + (unequal_block * right_block_size), right_block_size);

    indicator := (
      get_bit(
        encrypt(
          substr(a.bytes, 9 + (left_block_size * unequal_block), left_block_size),
          hash_key,
          'aes-ecb'
        ),
        0
      ) + get_bit(target_block, get_byte(a.bytes, unequal_block))) % 2;

    IF indicator = 1 THEN
      RETURN 1::integer;
    ELSE
      RETURN -1::integer;
    END IF;
  END;
$$;


--
-- Name: compare_ore_array(public.ore_64_8_v1_term[], public.ore_64_8_v1_term[]); Type: FUNCTION; Schema: public;
--

CREATE FUNCTION public.compare_ore_array(a public.ore_64_8_v1_term[], b public.ore_64_8_v1_term[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
  DECLARE
    cmp_result integer;
  BEGIN
    IF (array_length(a, 1) = 0 OR a IS NULL) AND (array_length(b, 1) = 0 OR b IS NULL) THEN
      RETURN 0;
    END IF;
    IF array_length(a, 1) = 0 OR a IS NULL THEN
      RETURN -1;
    END IF;
    IF array_length(b, 1) = 0 OR a IS NULL THEN
      RETURN 1;
    END IF;

    cmp_result := compare_ore_64_8_v1_term(a[1], b[1]);
    IF cmp_result = 0 THEN
    -- Removes the first element in the array, and calls this fn again to compare the next element/s in the array.
      RETURN compare_ore_array(a[2:array_length(a,1)], b[2:array_length(b,1)]);
    END IF;

    RETURN cmp_result;
  END
$$;


--
-- Name: ore_64_8_v1_eq(public.ore_64_8_v1, public.ore_64_8_v1); Type: FUNCTION; Schema: public;
--

CREATE FUNCTION public.ore_64_8_v1_eq(a public.ore_64_8_v1, b public.ore_64_8_v1) RETURNS boolean
    LANGUAGE sql
    AS $$
  SELECT compare_ore_64_8_v1(a, b) = 0
$$;


--
-- Name: ore_64_8_v1_gt(public.ore_64_8_v1, public.ore_64_8_v1); Type: FUNCTION; Schema: public;
--

CREATE FUNCTION public.ore_64_8_v1_gt(a public.ore_64_8_v1, b public.ore_64_8_v1) RETURNS boolean
    LANGUAGE sql
    AS $$
  SELECT compare_ore_64_8_v1(a, b) = 1
$$;


--
-- Name: ore_64_8_v1_gte(public.ore_64_8_v1, public.ore_64_8_v1); Type: FUNCTION; Schema: public;
--

CREATE FUNCTION public.ore_64_8_v1_gte(a public.ore_64_8_v1, b public.ore_64_8_v1) RETURNS boolean
    LANGUAGE sql
    AS $$
  SELECT compare_ore_64_8_v1(a, b) != -1
$$;


--
-- Name: ore_64_8_v1_lt(public.ore_64_8_v1, public.ore_64_8_v1); Type: FUNCTION; Schema: public;
--

CREATE FUNCTION public.ore_64_8_v1_lt(a public.ore_64_8_v1, b public.ore_64_8_v1) RETURNS boolean
    LANGUAGE sql
    AS $$
  SELECT compare_ore_64_8_v1(a, b) = -1
$$;


--
-- Name: ore_64_8_v1_lte(public.ore_64_8_v1, public.ore_64_8_v1); Type: FUNCTION; Schema: public;
--

CREATE FUNCTION public.ore_64_8_v1_lte(a public.ore_64_8_v1, b public.ore_64_8_v1) RETURNS boolean
    LANGUAGE sql
    AS $$
  SELECT compare_ore_64_8_v1(a, b) != 1
$$;


--
-- Name: ore_64_8_v1_neq(public.ore_64_8_v1, public.ore_64_8_v1); Type: FUNCTION; Schema: public;
--

CREATE FUNCTION public.ore_64_8_v1_neq(a public.ore_64_8_v1, b public.ore_64_8_v1) RETURNS boolean
    LANGUAGE sql
    AS $$
  SELECT compare_ore_64_8_v1(a, b) <> 0
$$;


--
-- Name: ore_64_8_v1_term_eq(public.ore_64_8_v1_term, public.ore_64_8_v1_term); Type: FUNCTION; Schema: public;
--

CREATE FUNCTION public.ore_64_8_v1_term_eq(a public.ore_64_8_v1_term, b public.ore_64_8_v1_term) RETURNS boolean
    LANGUAGE sql
    AS $$
  SELECT compare_ore_64_8_v1_term(a, b) = 0
$$;


--
-- Name: ore_64_8_v1_term_gt(public.ore_64_8_v1_term, public.ore_64_8_v1_term); Type: FUNCTION; Schema: public;
--

CREATE FUNCTION public.ore_64_8_v1_term_gt(a public.ore_64_8_v1_term, b public.ore_64_8_v1_term) RETURNS boolean
    LANGUAGE sql
    AS $$
  SELECT compare_ore_64_8_v1_term(a, b) = 1
$$;


--
-- Name: ore_64_8_v1_term_gte(public.ore_64_8_v1_term, public.ore_64_8_v1_term); Type: FUNCTION; Schema: public;
--

CREATE FUNCTION public.ore_64_8_v1_term_gte(a public.ore_64_8_v1_term, b public.ore_64_8_v1_term) RETURNS boolean
    LANGUAGE sql
    AS $$
  SELECT compare_ore_64_8_v1_term(a, b) != -1
$$;


--
-- Name: ore_64_8_v1_term_lt(public.ore_64_8_v1_term, public.ore_64_8_v1_term); Type: FUNCTION; Schema: public;
--

CREATE FUNCTION public.ore_64_8_v1_term_lt(a public.ore_64_8_v1_term, b public.ore_64_8_v1_term) RETURNS boolean
    LANGUAGE sql
    AS $$
  SELECT compare_ore_64_8_v1_term(a, b) = -1
$$;


--
-- Name: ore_64_8_v1_term_lte(public.ore_64_8_v1_term, public.ore_64_8_v1_term); Type: FUNCTION; Schema: public;
--

CREATE FUNCTION public.ore_64_8_v1_term_lte(a public.ore_64_8_v1_term, b public.ore_64_8_v1_term) RETURNS boolean
    LANGUAGE sql
    AS $$
  SELECT compare_ore_64_8_v1_term(a, b) != 1
$$;


--
-- Name: ore_64_8_v1_term_neq(public.ore_64_8_v1_term, public.ore_64_8_v1_term); Type: FUNCTION; Schema: public;
--

CREATE FUNCTION public.ore_64_8_v1_term_neq(a public.ore_64_8_v1_term, b public.ore_64_8_v1_term) RETURNS boolean
    LANGUAGE sql
    AS $$
  SELECT compare_ore_64_8_v1_term(a, b) <> 0
$$;


--
-- Name: <; Type: OPERATOR; Schema: public;
--

CREATE OPERATOR public.< (
    FUNCTION = public.ore_64_8_v1_term_lt,
    LEFTARG = public.ore_64_8_v1_term,
    RIGHTARG = public.ore_64_8_v1_term,
    COMMUTATOR = OPERATOR(public.>),
    NEGATOR = OPERATOR(public.>=),
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);


--
-- Name: <; Type: OPERATOR; Schema: public;
--

CREATE OPERATOR public.< (
    FUNCTION = public.ore_64_8_v1_lt,
    LEFTARG = public.ore_64_8_v1,
    RIGHTARG = public.ore_64_8_v1,
    COMMUTATOR = OPERATOR(public.>),
    NEGATOR = OPERATOR(public.>=),
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);


--
-- Name: <=; Type: OPERATOR; Schema: public;
--

CREATE OPERATOR public.<= (
    FUNCTION = public.ore_64_8_v1_term_lte,
    LEFTARG = public.ore_64_8_v1_term,
    RIGHTARG = public.ore_64_8_v1_term,
    COMMUTATOR = OPERATOR(public.>=),
    NEGATOR = OPERATOR(public.>),
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);


--
-- Name: <=; Type: OPERATOR; Schema: public;
--

CREATE OPERATOR public.<= (
    FUNCTION = public.ore_64_8_v1_lte,
    LEFTARG = public.ore_64_8_v1,
    RIGHTARG = public.ore_64_8_v1,
    COMMUTATOR = OPERATOR(public.>=),
    NEGATOR = OPERATOR(public.>),
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);


--
-- Name: <>; Type: OPERATOR; Schema: public;
--

CREATE OPERATOR public.<> (
    FUNCTION = public.ore_64_8_v1_term_neq,
    LEFTARG = public.ore_64_8_v1_term,
    RIGHTARG = public.ore_64_8_v1_term,
    NEGATOR = OPERATOR(public.=),
    MERGES,
    HASHES,
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);


--
-- Name: <>; Type: OPERATOR; Schema: public;
--

CREATE OPERATOR public.<> (
    FUNCTION = public.ore_64_8_v1_neq,
    LEFTARG = public.ore_64_8_v1,
    RIGHTARG = public.ore_64_8_v1,
    NEGATOR = OPERATOR(public.=),
    MERGES,
    HASHES,
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);


--
-- Name: =; Type: OPERATOR; Schema: public;
--

CREATE OPERATOR public.= (
    FUNCTION = public.ore_64_8_v1_term_eq,
    LEFTARG = public.ore_64_8_v1_term,
    RIGHTARG = public.ore_64_8_v1_term,
    NEGATOR = OPERATOR(public.<>),
    MERGES,
    HASHES,
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);


--
-- Name: =; Type: OPERATOR; Schema: public;
--

CREATE OPERATOR public.= (
    FUNCTION = public.ore_64_8_v1_eq,
    LEFTARG = public.ore_64_8_v1,
    RIGHTARG = public.ore_64_8_v1,
    NEGATOR = OPERATOR(public.<>),
    MERGES,
    HASHES,
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);

--
-- Name: >; Type: OPERATOR; Schema: public;
--

CREATE OPERATOR public.> (
    FUNCTION = public.ore_64_8_v1_term_gt,
    LEFTARG = public.ore_64_8_v1_term,
    RIGHTARG = public.ore_64_8_v1_term,
    COMMUTATOR = OPERATOR(public.<),
    NEGATOR = OPERATOR(public.<=),
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);


--
-- Name: >; Type: OPERATOR; Schema: public;
--

CREATE OPERATOR public.> (
    FUNCTION = public.ore_64_8_v1_gt,
    LEFTARG = public.ore_64_8_v1,
    RIGHTARG = public.ore_64_8_v1,
    COMMUTATOR = OPERATOR(public.<),
    NEGATOR = OPERATOR(public.<=),
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);


--
-- Name: >=; Type: OPERATOR; Schema: public;
--

CREATE OPERATOR public.>= (
    FUNCTION = public.ore_64_8_v1_term_gte,
    LEFTARG = public.ore_64_8_v1_term,
    RIGHTARG = public.ore_64_8_v1_term,
    COMMUTATOR = OPERATOR(public.<=),
    NEGATOR = OPERATOR(public.<),
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);


--
-- Name: >=; Type: OPERATOR; Schema: public;
--

CREATE OPERATOR public.>= (
    FUNCTION = public.ore_64_8_v1_gte,
    LEFTARG = public.ore_64_8_v1,
    RIGHTARG = public.ore_64_8_v1,
    COMMUTATOR = OPERATOR(public.<=),
    NEGATOR = OPERATOR(public.<),
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);

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
    RETURN
    (val->>'k' = 'ct' AND val ? 'c' AND NOT val ? 'p');
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
--
-- Configuration Schema
--
--  Defines core config state and storage types
--  Creates the cs_configuration_v1 table with constraint and unique indexes
--
--


--
-- cs_configuration_data_v1 is a jsonb column that stores the actuak configuration
--
-- For some reason CREATE DFOMAIN and CREATE TYPE do not support IF NOT EXISTS
-- Types cannot be dropped if used by a table, and we never drop the configuration table
-- DOMAIN constraints are added separately and not tied to DOMAIN creation
--
DO $$
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'cs_configuration_data_v1') THEN
      CREATE DOMAIN cs_configuration_data_v1 AS JSONB;
    END IF;
  END
$$;

--
-- cs_configuration_state_v1 is an ENUM that defines the valid configuration states
--
DO $$
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'cs_configuration_state_v1') THEN
      CREATE TYPE cs_configuration_state_v1 AS ENUM ('active', 'inactive', 'encrypting', 'pending');
    END IF;
  END
$$;

--
-- _cs_check_config_indexes returns true if the table configuration only includes valid index types
--
-- Used by the cs_configuration_data_v1_check constraint
--
-- Function types cannot be changed after creation so we always DROP & CREATE for flexibility
--
DROP FUNCTION IF EXISTS _cs_config_check_indexes(text, text);

CREATE FUNCTION _cs_config_check_indexes(val jsonb)
  RETURNS BOOLEAN
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	SELECT jsonb_object_keys(jsonb_path_query(val, '$.tables.*.*.indexes')) = ANY('{match_1, ore_1, ore_1_term, unique_1}');
END;

CREATE FUNCTION _cs_config_check_cast(val jsonb)
  RETURNS BOOLEAN
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
  SELECT jsonb_array_elements_text(jsonb_path_query_array(val, '$.tables.*.*.cast_as')) = ANY('{text, int}');
END;


--
-- Drop and reset the check constraint
--
ALTER DOMAIN cs_configuration_data_v1 DROP CONSTRAINT IF EXISTS cs_configuration_data_v1_check;

ALTER DOMAIN cs_configuration_data_v1
  ADD CONSTRAINT cs_configuration_data_v1_check CHECK (
    VALUE ?& array['s', 'tables'] AND
    VALUE->'tables' <> '{}'::jsonb AND
    _cs_config_check_cast(VALUE) AND
    _cs_config_check_indexes(VALUE)
);


--
-- CREATE the cs_configuration_v1 TABLE
--
CREATE TABLE IF NOT EXISTS cs_configuration_v1
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    state cs_configuration_state_v1 NOT NULL DEFAULT 'pending',
    data cs_configuration_data_v1,
    created_at timestamptz not null default current_timestamp,
    PRIMARY KEY(id)
);

--
-- Define partial indexes to ensure that there is only one active, pending and encrypting config at a time
--
CREATE UNIQUE INDEX IF NOT EXISTS cs_configuration_v1_index_active ON cs_configuration_v1 (state) WHERE state = 'active';
CREATE UNIQUE INDEX IF NOT EXISTS cs_configuration_v1_index_pending ON cs_configuration_v1 (state) WHERE state = 'pending';
CREATE UNIQUE INDEX IF NOT EXISTS cs_configuration_v1_index_encrypting ON cs_configuration_v1 (state) WHERE state = 'encrypting';
--
-- Configuration functions
--
--


-- DROP and CREATE functions
-- Function types cannot be changed after creation so we DROP for flexibility

DROP FUNCTION IF EXISTS cs_add_column_v1(text, text);
DROP FUNCTION IF EXISTS cs_remove_column_v1(text, text);
DROP FUNCTION IF EXISTS cs_add_index_v1(text, text, text, jsonb);
DROP FUNCTION IF EXISTS cs_remove_index_v1(text, text, text);
DROP FUNCTION IF EXISTS cs_modify_index_v1(text, text, text, jsonb);

DROP FUNCTION IF EXISTS cs_encrypt_v1();
DROP FUNCTION IF EXISTS cs_activate_v1();
DROP FUNCTION IF EXISTS cs_discard_v1();

DROP FUNCTION IF EXISTS _cs_config_default();
DROP FUNCTION IF EXISTS _cs_config_match_1_default();

DROP FUNCTION IF EXISTS _cs_config_add_table(text, json);
DROP FUNCTION IF EXISTS _cs_config_add_column(text, text, json);
DROP FUNCTION IF EXISTS _cs_config_add_cast(text, text, text, json);
DROP FUNCTION IF EXISTS _cs_config_add_index(text, text, text, json, json);


CREATE FUNCTION _cs_config_default(config jsonb)
  RETURNS jsonb
  IMMUTABLE PARALLEL SAFE
AS $$
  BEGIN
    IF config IS NULL THEN
      SELECT jsonb_build_object('s', 1, 'tables', '{}') INTO config;
    END IF;
    RETURN config;
  END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION _cs_config_add_table(table_name text, config jsonb)
  RETURNS jsonb
  -- IMMUTABLE PARALLEL SAFE
AS $$
  DECLARE
    tbl jsonb;
  BEGIN
    IF NOT config #> array['tables'] ? table_name THEN
      SELECT jsonb_build_object(table_name, '{}') into tbl;
      SELECT jsonb_set(config, array['tables'], tbl) INTO config;
    END IF;
    RETURN config;
  END;
$$ LANGUAGE plpgsql;


-- Add the column if it doesn't exist
CREATE FUNCTION _cs_config_add_column(table_name text, column_name text, config jsonb)
  RETURNS jsonb
  IMMUTABLE PARALLEL SAFE
AS $$
  DECLARE
    col jsonb;
  BEGIN
    IF NOT config #> array['tables', table_name] ? column_name THEN
      SELECT jsonb_build_object(column_name,
              jsonb_build_object('indexes', json_build_object())) into col;
      SELECT jsonb_set(config, array['tables', table_name], col) INTO config;
    END IF;
    RETURN config;
  END;
$$ LANGUAGE plpgsql;

-- Set the cast
CREATE FUNCTION _cs_config_add_cast(table_name text, column_name text, cast_as text, config jsonb)
  RETURNS jsonb
  IMMUTABLE PARALLEL SAFE
AS $$
  BEGIN
    SELECT jsonb_set(config, array['tables', table_name, column_name, 'cast_as'], to_jsonb(cast_as)) INTO config;
    RETURN config;
  END;
$$ LANGUAGE plpgsql;


-- Add the column if it doesn't exist
CREATE FUNCTION _cs_config_add_index(table_name text, column_name text, index_name text, opts jsonb, config jsonb)
  RETURNS jsonb
  IMMUTABLE PARALLEL SAFE
AS $$
  BEGIN
    SELECT jsonb_insert(config, array['tables', table_name, column_name, 'indexes', index_name], opts) INTO config;
    RETURN config;
  END;
$$ LANGUAGE plpgsql;


--
-- Default options for match_1 index
--
CREATE FUNCTION _cs_config_match_1_default()
  RETURNS jsonb
LANGUAGE sql STRICT PARALLEL SAFE
BEGIN ATOMIC
  SELECT jsonb_build_object(
            'k', 6,
            'm', 2048,
            'include_original', true,
            'tokenizer', json_build_object('kind', 'ngram', 'token_length', 3),
            'token_filters', json_build_object('kind', 'downcase'));
END;

--
--
--
CREATE FUNCTION cs_add_index_v1(table_name text, column_name text, index_name text, cast_as text DEFAULT 'text', opts jsonb DEFAULT '{}')
  RETURNS jsonb
AS $$
  DECLARE
    o jsonb;
    _config jsonb;
  BEGIN

    -- set the active config
    SELECT data INTO _config FROM cs_configuration_v1 WHERE state = 'active' OR state = 'pending' ORDER BY state DESC;

    -- if index exists
    IF _config #> array['tables', table_name, column_name, 'indexes'] ?  index_name THEN
      RAISE EXCEPTION '% index exists for column: % %', index_name, table_name, column_name;
    END IF;

    IF NOT cast_as = ANY('{text, int}') THEN
      RAISE EXCEPTION '% is not a valid cast type', cast_as;
    END IF;

    -- set default config
    SELECT _cs_config_default(_config) INTO _config;

    SELECT _cs_config_add_table(table_name, _config) INTO _config;

    SELECT _cs_config_add_column(table_name, column_name, _config) INTO _config;

    SELECT _cs_config_add_cast(table_name, column_name, cast_as, _config) INTO _config;

    -- set default options for index if opts empty
    IF index_name = 'match_1' AND opts = '{}' THEN
      SELECT _cs_config_match_1_default() INTO opts;
    END IF;

    SELECT _cs_config_add_index(table_name, column_name, index_name, opts, _config) INTO _config;

    --  create a new pending record if we don't have one
    INSERT INTO cs_configuration_v1 (state, data) VALUES ('pending', _config)
    ON CONFLICT (state)
      WHERE state = 'pending'
    DO UPDATE
      SET data = _config;

    -- exeunt
    RETURN _config;
  END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION cs_remove_index_v1(table_name text, column_name text, index_name text)
  RETURNS jsonb
AS $$
  DECLARE
    _config jsonb;
  BEGIN

    -- set the active config
    SELECT data INTO _config FROM cs_configuration_v1 WHERE state = 'active' OR state = 'pending' ORDER BY state DESC;

    -- if no config
    IF _config IS NULL THEN
      RAISE EXCEPTION 'No active or pending configuration exists';
    END IF;

    -- if the table doesn't exist
    IF NOT _config #> array['tables'] ? table_name THEN
      RAISE EXCEPTION 'No configuration exists for table: %', table_name;
    END IF;

    -- if the index does not exist
    -- IF NOT _config->key ? index_name THEN
    IF NOT _config #> array['tables', table_name] ?  column_name THEN
      RAISE EXCEPTION 'No % index exists for column: % %', index_name, table_name, column_name;
    END IF;

    --  create a new pending record if we don't have one
    INSERT INTO cs_configuration_v1 (state, data) VALUES ('pending', _config)
    ON CONFLICT (state)
      WHERE state = 'pending'
    DO NOTHING;

    -- remove the index
    SELECT _config #- array['tables', table_name, column_name, 'indexes', index_name] INTO _config;

    -- if column is now empty, remove the column
    IF _config #> array['tables', table_name, column_name, 'indexes'] = '{}' THEN
      SELECT _config #- array['tables', table_name, column_name] INTO _config;
    END IF;

    -- if table  is now empty, remove the table
    IF _config #> array['tables', table_name] = '{}' THEN
      SELECT _config #- array['tables', table_name] INTO _config;
    END IF;

    -- if config empty delete
    -- or update the config
    IF _config #> array['tables'] = '{}' THEN
      DELETE FROM cs_configuration_v1 WHERE state = 'pending';
    ELSE
      UPDATE cs_configuration_v1 SET data = _config WHERE state = 'pending';
    END IF;

    -- exeunt
    RETURN _config;
  END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION cs_modify_index_v1(table_name text, column_name text, index_name text, cast_as text DEFAULT 'text', opts jsonb DEFAULT '{}')
  RETURNS jsonb
AS $$
  BEGIN
    PERFORM cs_remove_index_v1(table_name, column_name, index_name);
    RETURN cs_add_index_v1(table_name, column_name, index_name, cast_as, opts);
  END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION cs_encrypt_v1()
  RETURNS boolean
AS $$
	BEGIN
    IF NOT cs_ready_for_encryption_v1() THEN
      RAISE EXCEPTION 'Some pending columns do not have an encrypted target';
    END IF;

		IF NOT EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'pending') THEN
			RAISE EXCEPTION 'No pending configuration exists to encrypt';
		END IF;

    UPDATE cs_configuration_v1 SET state = 'encrypting' WHERE state = 'pending';
		RETURN true;
  END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION cs_activate_v1()
  RETURNS boolean
AS $$
	BEGIN

	  IF EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'encrypting') THEN
	  	UPDATE cs_configuration_v1 SET state = 'inactive' WHERE state = 'active';
			UPDATE cs_configuration_v1 SET state = 'active' WHERE state = 'encrypting';
			RETURN true;
		ELSE
			RAISE EXCEPTION 'No encrypting configuration exists to activate';
		END IF;
  END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION cs_discard_v1()
  RETURNS boolean
AS $$
  BEGIN
    IF EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'pending') THEN
        DELETE FROM cs_configuration_v1 WHERE state = 'pending';
      RETURN true;
    ELSE
      RAISE EXCEPTION 'No pending configuration exists to discard';
    END IF;
  END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION cs_add_column_v1(table_name text, column_name text)
  RETURNS jsonb
AS $$
  DECLARE
    key text;
    _config jsonb;
  BEGIN
    -- set the active config
    SELECT data INTO _config FROM cs_configuration_v1 WHERE state = 'active' OR state = 'pending' ORDER BY state DESC;

    -- set default config
    SELECT _cs_config_default(_config) INTO _config;

    -- if index exists
    IF _config #> array['tables', table_name] ?  column_name THEN
      RAISE EXCEPTION 'Config exists for column: % %', table_name, column_name;
    END IF;

    SELECT _cs_config_add_table(table_name, _config) INTO _config;

    SELECT _cs_config_add_column(table_name, column_name, _config) INTO _config;

    --  create a new pending record if we don't have one
    INSERT INTO cs_configuration_v1 (state, data) VALUES ('pending', _config)
    ON CONFLICT (state)
      WHERE state = 'pending'
    DO UPDATE
      SET data = _config;

    -- exeunt
    RETURN _config;
  END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION cs_remove_column_v1(table_name text, column_name text)
  RETURNS jsonb
AS $$
  DECLARE
    key text;
    _config jsonb;
  BEGIN
     -- set the active config
    SELECT data INTO _config FROM cs_configuration_v1 WHERE state = 'active' OR state = 'pending' ORDER BY state DESC;

    -- if no config
    IF _config IS NULL THEN
      RAISE EXCEPTION 'No active or pending configuration exists';
    END IF;

    -- if the table doesn't exist
    IF NOT _config #> array['tables'] ? table_name THEN
      RAISE EXCEPTION 'No configuration exists for table: %', table_name;
    END IF;

    -- if the column does not exist
    IF NOT _config #> array['tables', table_name] ?  column_name THEN
      RAISE EXCEPTION 'No configuration exists for column: % %', table_name, column_name;
    END IF;

    --  create a new pending record if we don't have one
    INSERT INTO cs_configuration_v1 (state, data) VALUES ('pending', _config)
    ON CONFLICT (state)
      WHERE state = 'pending'
    DO NOTHING;

    -- remove the column
    SELECT _config #- array['tables', table_name, column_name] INTO _config;

    -- if table  is now empty, remove the table
    IF _config #> array['tables', table_name] = '{}' THEN
      SELECT _config #- array['tables', table_name] INTO _config;
    END IF;

    -- if config empty delete
    -- or update the config
    IF _config #> array['tables'] = '{}' THEN
      DELETE FROM cs_configuration_v1 WHERE state = 'pending';
    ELSE
      UPDATE cs_configuration_v1 SET data = _config WHERE state = 'pending';
    END IF;

    -- exeunt
    RETURN _config;

  END;
$$ LANGUAGE plpgsql;

-- DROP and CREATE functions
-- Function types cannot be changed after creation so we DROP for flexibility
DROP FUNCTION IF EXISTS cs_select_pending_columns_v1;
DROP FUNCTION IF EXISTS cs_select_target_columns_v1;
DROP FUNCTION IF EXISTS cs_count_encrypted_with_active_config_v1;
DROP FUNCTION IF EXISTS cs_create_encrypted_columns_v1();
DROP FUNCTION IF EXISTS cs_rename_encrypted_columns_v1();

DROP FUNCTION IF EXISTS _cs_diff_config_v1;
DROP FUNCTION IF EXISTS _cs_table_from_config_key;
DROP FUNCTION IF EXISTS _cs_column_from_config_key;


-- Return the diff of two configurations
-- Returns the set of keys in a that have different values to b
-- The json comparison is on object values held by the key
CREATE OR REPLACE FUNCTION _cs_diff_config_v1(a JSONB, b JSONB)
	RETURNS TABLE(table_name TEXT, column_name TEXT)
IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN QUERY
    WITH table_keys AS (
      SELECT jsonb_object_keys(a->'tables') AS key
      UNION
      SELECT jsonb_object_keys(b->'tables') AS key
    ),
    column_keys AS (
      SELECT tk.key AS table_key, jsonb_object_keys(a->'tables'->tk.key) AS column_key
      FROM table_keys tk
      UNION
      SELECT tk.key AS table_key, jsonb_object_keys(b->'tables'->tk.key) AS column_key
      FROM table_keys tk
    )
    SELECT
      ck.table_key AS table_name,
      ck.column_key AS column_name
    FROM
      column_keys ck
    WHERE
      (a->'tables'->ck.table_key->ck.column_key IS DISTINCT FROM b->'tables'->ck.table_key->ck.column_key);
  END;
$$ LANGUAGE plpgsql;


-- Returns the set of columns with pending configuration changes
-- Compares the columns in pending configuration that do not match the active config
CREATE FUNCTION cs_select_pending_columns_v1()
	RETURNS TABLE(table_name TEXT, column_name TEXT)
AS $$
	DECLARE
		active JSONB;
		pending JSONB;
		config_id BIGINT;
	BEGIN
		SELECT data INTO active FROM cs_configuration_v1 WHERE state = 'active';

		-- set default config
    IF active IS NULL THEN
      active := '{}';
    END IF;

		SELECT id, data INTO config_id, pending FROM cs_configuration_v1 WHERE state = 'pending';

		-- set default config
		IF config_id IS NULL THEN
			RAISE EXCEPTION 'No pending configuration exists to encrypt';
		END IF;

		RETURN QUERY
		SELECT d.table_name, d.column_name FROM _cs_diff_config_v1(active, pending) as d;
	END;
$$ LANGUAGE plpgsql;

--
-- Returns the target columns with pending configuration
--
-- A `pending` column may be either a plaintext variant or cs_encrypted_v1.
-- A `target` column is always of type cs_encrypted_v1
--
-- On initial encryption from plaintext the target column will be `{column_name}_encrypted `
-- OR NULL if the column does not exist
--
CREATE FUNCTION cs_select_target_columns_v1()
	RETURNS TABLE(table_name TEXT, column_name TEXT, target_column TEXT)
	STABLE STRICT PARALLEL SAFE
AS $$
  SELECT
    c.table_name,
    c.column_name,
    s.column_name as target_column
  FROM
    cs_select_pending_columns_v1() c
  LEFT JOIN information_schema.columns s ON
    s.table_name = c.table_name AND
    (s.column_name = c.table_name OR s.column_name = c.column_name || '_encrypted') AND
    s.domain_name = 'cs_encrypted_v1';
$$ LANGUAGE sql;


--
-- Returns true if all pending columns have a target (encrypted) column
CREATE FUNCTION cs_ready_for_encryption_v1()
	RETURNS BOOLEAN
	STABLE STRICT PARALLEL SAFE
AS $$
	SELECT EXISTS (
	  SELECT *
	  FROM cs_select_target_columns_v1() AS c
	  WHERE c.target_column IS NOT NULL);
$$ LANGUAGE sql;


--
-- Creates cs_encrypted_v1 columns for any plaintext columns with pending configuration
-- The new column name is `{column_name}_encrypted`
--
-- Executes the ALTER TABLE statement
--   `ALTER TABLE {target_table} ADD COLUMN {column_name}_encrypted cs_encrypted_v1;`
--
CREATE FUNCTION cs_create_encrypted_columns_v1()
	RETURNS TABLE(table_name TEXT, column_name TEXT)
AS $$
	BEGIN
    FOR table_name, column_name IN
      SELECT c.table_name, (c.column_name || '_encrypted') FROM cs_select_target_columns_v1() AS c WHERE c.target_column IS NULL
    LOOP
		  EXECUTE format('ALTER TABLE %I ADD column %I cs_encrypted_v1', table_name, column_name);
      RETURN NEXT;
    END LOOP;
	END;
$$ LANGUAGE plpgsql;


--
-- Renames plaintext and cs_encrypted_v1 columns created for the initial encryption.
-- The source plaintext column is renamed to `{column_name}_plaintext`
-- The target encrypted column is renamed from `{column_name}_encrypted` to `{column_name}`
--
-- Executes the ALTER TABLE statements
--   `ALTER TABLE {target_table} RENAME COLUMN {column_name} TO {column_name}_plaintext;
--   `ALTER TABLE {target_table} RENAME COLUMN {column_name}_encrypted TO {column_name};`
--
CREATE FUNCTION cs_rename_encrypted_columns_v1()
	RETURNS TABLE(table_name TEXT, column_name TEXT, target_column TEXT)
AS $$
	BEGIN
    FOR table_name, column_name, target_column IN
      SELECT * FROM cs_select_target_columns_v1() as c WHERE c.target_column = c.column_name || '_encrypted'
    LOOP
		  EXECUTE format('ALTER TABLE %I RENAME %I TO %I;', table_name, column_name, column_name || '_plaintext');
		  EXECUTE format('ALTER TABLE %I RENAME %I TO %I;', table_name, target_column, column_name);
      RETURN NEXT;
    END LOOP;
	END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION cs_count_encrypted_with_active_config_v1(table_name TEXT, column_name TEXT)
  RETURNS BIGINT
AS $$
DECLARE
  result BIGINT;
BEGIN
	EXECUTE format(
        'SELECT COUNT(%I) FROM %s t WHERE %I->>%L = (SELECT id::TEXT FROM cs_configuration_v1 WHERE state = %L)',
        column_name, table_name, column_name, 'v', 'active'
    )
	INTO result;
  	RETURN result;
END;
$$ LANGUAGE plpgsql;
