-- REQUIRE: src/schema.sql
-- REQUIRE: src/common.sql
-- REQUIRE: src/ore_cllw_u64_8/types.sql



-- extracts ste_vec index from a jsonb value

-- extracts ore_cllw_u64_8 index from a jsonb value

CREATE FUNCTION eql_v2.ore_cllw_u64_8(val jsonb)
  RETURNS eql_v2.ore_cllw_u64_8
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val IS NULL THEN
      RETURN NULL;
    END IF;

    IF NOT (val ? 'ocf') THEN
        RAISE 'Expected a ore_cllw_u64_8 index (ocf) value in json: %', val;
    END IF;

    IF val->>'ocf' IS NULL THEN
      RETURN NULL;
    END IF;

    RETURN ROW(decode(val->>'ocf', 'hex'));
  END;
$$ LANGUAGE plpgsql;


-- extracts ore_cllw_u64_8 index from an eql_v2_encrypted value

CREATE FUNCTION eql_v2.ore_cllw_u64_8(val eql_v2_encrypted)
  RETURNS eql_v2.ore_cllw_u64_8
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.ore_cllw_u64_8(val.data));
  END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION eql_v2.has_ore_cllw_u64_8(val jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN val ? 'ocf';
  END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION eql_v2.has_ore_cllw_u64_8(val eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2.has_ore_cllw_u64_8(val.data);
  END;
$$ LANGUAGE plpgsql;



--
-- Compare ore cllw bytes
-- Used by both fixed and variable ore cllw variants
--

CREATE FUNCTION eql_v2.compare_ore_cllw(a bytea, b bytea)
RETURNS int AS $$
DECLARE
    len_a INT;
    x BYTEA;
    y BYTEA;
    i INT;
    differing RECORD;
BEGIN
    len_a := LENGTH(a);

    -- Iterate over each byte and compare them
    FOR i IN 1..len_a LOOP
        x := SUBSTRING(a FROM i FOR 1);
        y := SUBSTRING(b FROM i FOR 1);

        -- Check if there's a difference
        IF x != y THEN
            differing := (x, y);
            EXIT;
        END IF;
    END LOOP;

    -- If a difference is found, compare the bytes as in Rust logic
    IF differing IS NOT NULL THEN
        IF (get_byte(y, 0) + 1) % 256 = get_byte(x, 0) THEN
            RETURN 1;
        ELSE
            RETURN -1;
        END IF;
    ELSE
        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;




CREATE FUNCTION eql_v2.compare_ore_cllw_u64_8(a eql_v2.ore_cllw_u64_8, b eql_v2.ore_cllw_u64_8)
RETURNS int AS $$
DECLARE
    len_a INT;
    len_b INT;
BEGIN
    IF a IS NULL OR b IS NULL THEN
      RETURN NULL;
    END IF;

    -- Check if the lengths of the two bytea arguments are the same
    len_a := LENGTH(a.bytes);
    len_b := LENGTH(b.bytes);

    IF len_a != len_b THEN
      RAISE EXCEPTION 'ore_cllw_u64_8 index terms are not the same length';
    END IF;

    RETURN eql_v2.compare_ore_cllw(a.bytes, b.bytes);
END;
$$ LANGUAGE plpgsql;

