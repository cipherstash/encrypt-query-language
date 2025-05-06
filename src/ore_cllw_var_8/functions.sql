-- REQUIRE: src/schema.sql
-- REQUIRE: src/common.sql
-- REQUIRE: src/ore_cllw_var_8/types.sql
-- REQUIRE: src/ore_cllw_u64_8/functions.sql



-- extracts ore_cllw_var_8 index from a jsonb value
-- DROP FUNCTION IF EXISTS  eql_v1.ore_cllw_var_8(val jsonb);

CREATE FUNCTION eql_v1.ore_cllw_var_8(val jsonb)
  RETURNS eql_v1.ore_cllw_var_8
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN

    IF NOT (val ? 'ocv') THEN
        RAISE 'Expected a ore_cllw_var_8 index (ocv) value in json: %', val;
    END IF;

    IF val->>'ocv' IS NULL THEN
      RETURN NULL;
    END IF;

    RETURN ROW(decode(val->>'ocv', 'hex'));
  END;
$$ LANGUAGE plpgsql;


-- extracts ore_cllw_var_8 index from an eql_v1_encrypted value
-- DROP FUNCTION IF EXISTS  eql_v1.ore_cllw_var_8(val eql_v1_encrypted);

CREATE FUNCTION eql_v1.ore_cllw_var_8(val eql_v1_encrypted)
  RETURNS eql_v1.ore_cllw_var_8
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v1.ore_cllw_var_8(val.data));
  END;
$$ LANGUAGE plpgsql;


-- DROP FUNCTION IF EXISTS eql_v1.compare_ore_cllw_var_8(a eql_v1.ore_cllw_var_8, b eql_v1.ore_cllw_var_8);

CREATE FUNCTION eql_v1.compare_ore_cllw_var_8(a eql_v1.ore_cllw_var_8, b eql_v1.ore_cllw_var_8)
RETURNS int AS $$
DECLARE
    len_a INT;
    len_b INT;
    -- length of the common part of the two bytea values
    common_len INT;
    cmp_result INT;
BEGIN
    IF a IS NULL OR b IS NULL THEN
      RETURN NULL;
    END IF;

    -- Get the lengths of both bytea inputs
    len_a := LENGTH(a.bytes);
    len_b := LENGTH(b.bytes);

    -- Handle empty cases
    IF len_a = 0 AND len_b = 0 THEN
        RETURN 0;
    ELSIF len_a = 0 THEN
        RETURN -1;
    ELSIF len_b = 0 THEN
        RETURN 1;
    END IF;

    -- Find the length of the shorter bytea
    IF len_a < len_b THEN
        common_len := len_a;
    ELSE
        common_len := len_b;
    END IF;

    -- Use the compare_bytea function to compare byte by byte
    cmp_result := eql_v1.compare_ore_cllw(
      SUBSTRING(a.bytes FROM 1 FOR common_len),
      SUBSTRING(b.bytes FROM 1 FOR common_len)
    );

    -- If the comparison returns 'less' or 'greater', return that result
    IF cmp_result = -1 THEN
        RETURN -1;
    ELSIF cmp_result = 1 THEN
        RETURN 1;
    END IF;

    -- If the bytea comparison is 'equal', compare lengths
    IF len_a < len_b THEN
        RETURN -1;
    ELSIF len_a > len_b THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;
