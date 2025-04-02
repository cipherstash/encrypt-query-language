-- Aggregate functions for ORE
DROP FUNCTION IF EXISTS cs_min_encrypted_v1;
CREATE FUNCTION cs_min_encrypted_v1(a cs_encrypted_v1, b cs_encrypted_v1)
RETURNS cs_encrypted_v1
LANGUAGE plpgsql
STRICT
AS $$
  BEGIN
    IF cs_ore_64_8_v1(a) < cs_ore_64_8_v1(b) THEN
      RETURN  a;
    ELSE
      RETURN b;
    END IF;
  END;
$$;

CREATE AGGREGATE cs_min_v1(cs_encrypted_v1)
(
  sfunc = cs_min_encrypted_v1,
  stype = cs_encrypted_v1
);

DROP FUNCTION IF EXISTS cs_max_encrypted_v1;
CREATE FUNCTION cs_max_encrypted_v1(a cs_encrypted_v1, b cs_encrypted_v1)
RETURNS cs_encrypted_v1
LANGUAGE plpgsql
STRICT
AS $$
  BEGIN
    IF cs_ore_64_8_v1(a) > cs_ore_64_8_v1(b) THEN
      RETURN  a;
    ELSE
      RETURN b;
    END IF;
  END;
$$;

CREATE AGGREGATE cs_max_v1(cs_encrypted_v1)
(
  sfunc = cs_max_encrypted_v1,
  stype = cs_encrypted_v1
);
