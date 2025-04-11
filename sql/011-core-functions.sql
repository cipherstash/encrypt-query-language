DROP FUNCTION IF EXISTS eql_v1.ciphertext(val jsonb);

CREATE FUNCTION eql_v1.ciphertext(val jsonb)
  RETURNS text
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val ? 'c' THEN
      RETURN val->>'c';
    END IF;
    RAISE 'Expected a ciphertext (c) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;


-- extracts match index from an emcrypted column
DROP FUNCTION IF EXISTS eql_v1.match(val jsonb);

CREATE FUNCTION eql_v1.match(val jsonb)
  RETURNS eql_v1.match_index
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val ? 'm' THEN
      RETURN ARRAY(SELECT jsonb_array_elements(val->'m'))::eql_v1.match_index;
    END IF;
    RAISE 'Expected a match index (m) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;



-- extracts unique index from an encrypted column
DROP FUNCTION IF EXISTS  eql_v1.unique(val jsonb);

CREATE FUNCTION eql_v1.unique(val jsonb)
  RETURNS eql_v1.unique_index
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val ? 'u' THEN
      RETURN val->>'u';
    END IF;
    RAISE 'Expected a unique index (u) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;


-- extracts json ste_vec index from an encrypted column
DROP FUNCTION IF EXISTS eql_v1.ste_vec(val jsonb);

CREATE FUNCTION eql_v1.ste_vec(val jsonb)
  RETURNS eql_v1.ste_vec_index
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val ? 'sv' THEN
      RETURN (val->'sv')::eql_v1.ste_vec_index;
    END IF;
    RAISE 'Expected a structured vector index (sv) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;


-- casts text to ore_64_8_v1_term (bytea)
DROP FUNCTION IF EXISTS eql_v1.text_to_ore_64_8_v1_term(t text);

CREATE FUNCTION eql_v1.text_to_ore_64_8_v1_term(t text)
  RETURNS eql_v1.ore_64_8_v1_term
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	RETURN t::bytea;
END;

-- cast to cleanup ore_64_8_v1 extraction
DROP CAST IF EXISTS (text AS eql_v1.ore_64_8_v1_term);

CREATE CAST (text AS eql_v1.ore_64_8_v1_term)
	WITH FUNCTION eql_v1.text_to_ore_64_8_v1_term(text) AS IMPLICIT;

DROP FUNCTION IF EXISTS eql_v1.jsonb_array_to_ore_64_8_v1(val jsonb);

-- Casts a jsonb array of hex-encoded strings to the `ore_64_8_v1` composite type.
-- In other words, this function takes the ORE index format sent through in the
-- EQL payload from Proxy and decodes it as the composite type that we use for
-- ORE operations on the Postgres side.
CREATE FUNCTION eql_v1.jsonb_array_to_ore_64_8_v1(val jsonb)
RETURNS eql_v1.ore_64_8_v1 AS $$
DECLARE
  terms_arr eql_v1.ore_64_8_v1_term[];
BEGIN
  IF jsonb_typeof(val) = 'null' THEN
    RETURN NULL;
  END IF;

  SELECT array_agg(ROW(decode(value::text, 'hex'))::eql_v1.ore_64_8_v1_term)
    INTO terms_arr
  FROM jsonb_array_elements_text(val) AS value;

  RETURN ROW(terms_arr)::eql_v1.ore_64_8_v1;
END;
$$ LANGUAGE plpgsql;

-- extracts ore index from an encrypted column
DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1(val jsonb);

CREATE FUNCTION eql_v1.ore_64_8_v1(val jsonb)
  RETURNS eql_v1.ore_64_8_v1
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val ? 'o' THEN
      RETURN eql_v1.jsonb_array_to_ore_64_8_v1(val->'o');
    END IF;
    RAISE 'Expected an ore index (o) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;



DROP FUNCTION IF EXISTS eql_v1._first_grouped_value(jsonb, jsonb);

CREATE FUNCTION eql_v1._first_grouped_value(jsonb, jsonb)
RETURNS jsonb AS $$
  SELECT COALESCE($1, $2);
$$ LANGUAGE sql IMMUTABLE;

DROP AGGREGATE IF EXISTS eql_v1.cs_grouped_value(jsonb);

CREATE AGGREGATE eql_v1.cs_grouped_value(jsonb) (
  SFUNC = eql_v1._first_grouped_value,
  STYPE = jsonb
);
