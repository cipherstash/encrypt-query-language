-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql


-- Should include an ident field
CREATE FUNCTION eql_v2._encrypted_check_i(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF val ? 'i' THEN
      RETURN true;
    END IF;
    RAISE 'Encrypted column missing ident (i) field: %', val;
  END;
$$ LANGUAGE plpgsql;


-- Ident field should include table and column
CREATE FUNCTION eql_v2._encrypted_check_i_ct(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF (val->'i' ?& array['t', 'c']) THEN
      RETURN true;
    END IF;
    RAISE 'Encrypted column ident (i) missing table (t) or column (c) fields: %', val;
  END;
$$ LANGUAGE plpgsql;

-- -- Should include a version field
CREATE FUNCTION eql_v2._encrypted_check_v(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF (val ? 'v') THEN

      IF val->>'v' <> '2' THEN
        RAISE 'Expected encrypted column version (v) 2';
        RETURN false;
      END IF;

      RETURN true;
    END IF;
    RAISE 'Encrypted column missing version (v) field: %', val;
  END;
$$ LANGUAGE plpgsql;


-- -- Should include a ciphertext field
CREATE FUNCTION eql_v2._encrypted_check_c(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF (val ? 'c') THEN
      RETURN true;
    END IF;
    RAISE 'Encrypted column missing ciphertext (c) field: %', val;
  END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION eql_v2.check_encrypted(val jsonb)
  RETURNS BOOLEAN
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
    RETURN (
      eql_v2._encrypted_check_v(val) AND
      eql_v2._encrypted_check_c(val) AND
      eql_v2._encrypted_check_i(val) AND
      eql_v2._encrypted_check_i_ct(val)
    );
END;


CREATE FUNCTION eql_v2.check_encrypted(val eql_v2_encrypted)
  RETURNS BOOLEAN
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
    RETURN eql_v2.check_encrypted(val.data);
END;

