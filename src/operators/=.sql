-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/unique/types.sql
-- REQUIRE: src/unique/functions.sql
-- REQUIRE: src/ore/types.sql
-- REQUIRE: src/ore/functions.sql
-- REQUIRE: src/ore/operators.sql
-- REQUIRE: src/blake3/types.sql
-- REQUIRE: src/blake3/functions.sql
-- REQUIRE: src/ore_cllw_u64_8/types.sql
-- REQUIRE: src/ore_cllw_u64_8/functions.sql
-- REQUIRE: src/ore_cllw_u64_8/operators.sql

-- Operators for equality comparisons of eql_v1_encrypted types
--
-- Support for the following comparisons:
--
--      eql_v1_encrypted = eql_v1_encrypted
--      eql_v1_encrypted = jsonb
--      jsonb = eql_v1_encrypted
--
-- There are multiple index terms that provide equality comparisons
--   - unique
--   - ore_64_8_v1
--
--
-- We check these index terms in this order and use the first one that exists for both parameters
--
--

-- DROP FUNCTION IF EXISTS eql_v1.eq(a eql_v1_encrypted, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.eq(a eql_v1_encrypted, b eql_v1_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN

    BEGIN
      RETURN eql_v1.unique(a) = eql_v1.unique(b);
    EXCEPTION WHEN OTHERS THEN
      -- PERFORM eql_v1.log('No unique index');
    END;

    BEGIN
      RETURN eql_v1.blake3(a) = eql_v1.blake3(b);
    EXCEPTION WHEN OTHERS THEN
      -- PERFORM eql_v1.log('No blake3 index');
    END;

    BEGIN
      RETURN eql_v1.ore_cllw_u64_8(a) = eql_v1.ore_cllw_u64_8(b);
    EXCEPTION WHEN OTHERS THEN
      -- PERFORM eql_v1.log('No ore_cllw_u64_8 index');
    END;

    BEGIN
      RETURN eql_v1.ore_cllw_var_8(a) = eql_v1.ore_cllw_var_8(b);
    EXCEPTION WHEN OTHERS THEN
      -- PERFORM eql_v1.log('No ore_cllw_u64_8 index');
    END;

    BEGIN
      RETURN eql_v1.ore_64_8_v1(a) = eql_v1.ore_64_8_v1(b);
    EXCEPTION WHEN OTHERS THEN
      -- PERFORM eql_v1.log('No ore_64_8_v1 index');
    END;

    RETURN false;
  END;
$$ LANGUAGE plpgsql;


-- DROP OPERATOR IF EXISTS = (eql_v1_encrypted, eql_v1_encrypted) CASCADE;
-- DROP FUNCTION IF EXISTS eql_v1."="(a eql_v1_encrypted, b eql_v1_encrypted);

CREATE FUNCTION eql_v1."="(a eql_v1_encrypted, b eql_v1_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN eql_v1.eq(a, b);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR = (
  FUNCTION=eql_v1."=",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1_encrypted,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

-- DROP OPERATOR IF EXISTS = (eql_v1_encrypted, jsonb);
-- DROP FUNCTION IF EXISTS eql_v1."="(a eql_v1_encrypted, b jsonb);

CREATE FUNCTION eql_v1."="(a eql_v1_encrypted, b jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN eql_v1.eq(a, b::eql_v1_encrypted);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR = (
  FUNCTION=eql_v1."=",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=jsonb,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

-- DROP OPERATOR IF EXISTS = (jsonb, eql_v1_encrypted);
-- DROP FUNCTION IF EXISTS eql_v1."="(a jsonb, b eql_v1_encrypted);

CREATE FUNCTION eql_v1."="(a jsonb, b eql_v1_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN eql_v1.eq(a::eql_v1_encrypted, b);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR = (
  FUNCTION=eql_v1."=",
  LEFTARG=jsonb,
  RIGHTARG=eql_v1_encrypted,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

