DROP FUNCTION IF EXISTS cs_ciphertext_v1_v0_0(val jsonb);

CREATE FUNCTION cs_ciphertext_v1(val jsonb)
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


-----------------------------------------------------------------------------


-- extracts match index from an emcrypted column
DROP FUNCTION IF EXISTS cs_match_v1(val jsonb);

CREATE FUNCTION cs_match_v1(val jsonb)
  RETURNS cs_match_index_v1
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val ? 'm' THEN
      RETURN ARRAY(SELECT jsonb_array_elements(val->'m'))::cs_match_index_v1;
    END IF;
    RAISE 'Expected a match index (m) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------


-- extracts unique index from an encrypted column
DROP FUNCTION IF EXISTS  cs_unique_v1(val jsonb);

CREATE FUNCTION cs_unique_v1(val jsonb)
  RETURNS cs_unique_index_v1
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val ? 'u' THEN
      RETURN val->>'u';
    END IF;
    RAISE 'Expected a unique index (u) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;


-----------------------------------------------------------------------------

-- extracts json ste_vec index from an encrypted column
DROP FUNCTION IF EXISTS cs_ste_vec_v1(val jsonb);

CREATE FUNCTION cs_ste_vec_v1(val jsonb)
  RETURNS cs_ste_vec_index_v1
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val ? 'sv' THEN
      RETURN (val->'sv')::cs_ste_vec_index_v1;
    END IF;
    RAISE 'Expected a structured vector index (sv) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------


DROP FUNCTION IF EXISTS jsonb_array_to_bytea_array(val jsonb);

CREATE FUNCTION jsonb_array_to_bytea_array(val jsonb)
RETURNS bytea[] AS $$
    SELECT array_agg(decode(value::text, 'hex'))
    FROM jsonb_array_elements_text(val) AS value;
$$ LANGUAGE sql;


DROP FUNCTION IF EXISTS cs_ore_64_8_v1(val jsonb);

CREATE FUNCTION cs_ore_64_8_v1(val jsonb)
  RETURNS ore_64_8_index_v1
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val ? 'o' THEN
      RETURN jsonb_array_to_bytea_array(val->'o');
    END IF;
    RAISE 'Expected an ore index (o) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------


DROP FUNCTION IF EXISTS _cs_first_grouped_value(jsonb, jsonb);

CREATE FUNCTION _cs_first_grouped_value(jsonb, jsonb)
RETURNS jsonb AS $$
  SELECT COALESCE($1, $2);
$$ LANGUAGE sql IMMUTABLE;

DROP AGGREGATE IF EXISTS cs_grouped_value_v1(jsonb);

CREATE AGGREGATE cs_grouped_value_v1(jsonb) (
  SFUNC = _cs_first_grouped_value,
  STYPE = jsonb
);
