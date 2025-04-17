\set ON_ERROR_STOP on

--
-- Various Helper functions
--



--
-- Creates a table with an encrypted column for testing
--
DROP FUNCTION IF EXISTS create_table_with_encrypted();
CREATE FUNCTION create_table_with_encrypted()
  RETURNS void
AS $$
  BEGIN
    DROP TABLE IF EXISTS encrypted;
    CREATE TABLE encrypted
    (
        id bigint GENERATED ALWAYS AS IDENTITY,
        -- name_encrypted eql_v1_encrypted,
        e eql_v1_encrypted,
        PRIMARY KEY(id)
    );
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS get_high_ore();
CREATE FUNCTION get_high_ore()
  RETURNS jsonb
AS $$
  BEGIN
    RETURN '{"o": ["1212121212125932e28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd8011f94b49eaa5fa5a60e1e2adccde4185a7d6c7f83088500b677f897d4ffc276016d614708488f407c01bd3ccf2be653269062cb97f8945a621d049277d19b1c248611f25d047038928d2efeb4323c402af4c19288c7b36911dc06639af5bb34367519b66c1f525bbd3828c12067c9c579aeeb4fb3ae0918125dc1dad5fd518019a5ae67894ce1a7f7bed1a591ba8edda2fdf4cd403761fd981fb1ea5eb0bf806f919350ee60cac16d0a39a491a4d79301781f95ea3870aea82e9946053537360b2fb415b18b61aed0af81d461ad6b923f10c0df79daddc4e279ff543a282bb3a37f9fa03238348b3dac51a453b04bced1f5bd318ddd829bdfe5f37abdbeda730e21441b818302f3c5c2c4d5657accfca4c53d7a80eb3db43946d38965be5f796b"]}'::jsonb;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS get_low_ore();
CREATE FUNCTION get_low_ore()
  RETURNS jsonb
AS $$
  BEGIN
    RETURN '{"o": ["12121212121259bfe28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801ff4a28b714e4cde8df10625dce72602fdbdcc53d515857f1119f5912804ce09c6cf6c2d37393a27a465134523b512664582f834e15003b7216cb668480bc3e7d1c069f2572ece7c848b9eb9a28b4e62bfc2b97c93e61b2054154e621c5bbb7bed37de3d7c343bd3dbcf7b4af20128c961351bf55910a855f08a8587c2059a5f05ca8d7a082e695b3dd4ff3ce86694d4fe98972220eea1ab90f5de493ef3a502b74a569f103ee2897ebc9ae9b16a17e7be67415ee830519beb3058ffc1c1eb0e574d66c8b365919f27eb00aa7bce475d7bdaad4ed800f8fc3d626e0eb842e312b0cc22a1ccf89847ebb2cd0a6e18aec21bd2deeec1c47301fc687f7f764bb882b50f553c246a6da5816b78b3530119ea68b08a8403a90e063e58502670563bd4d"]}'::jsonb;
END;
$$ LANGUAGE plpgsql;



-- --
-- --
--
-- Creates a table with an encrypted column for testing
--
-- --
-- --
DROP FUNCTION IF EXISTS create_encrypted_json(integer);
CREATE FUNCTION create_encrypted_json(id integer)
  RETURNS eql_v1_encrypted
AS $$
  DECLARE
    s text;
    m jsonb;
    start integer;
    stop integer;
    random_key text;
    random_val text;
  BEGIN

    start := (10 * id);
    stop := (10 * id) + 5;
    m := array_to_json(array(SELECT generate_series(start, stop)));

    select substr(md5(random()::text), 1, 25) INTO random_key;
    select substr(md5(random()::text), 1, 25) INTO random_val;

    s := format(
      '{
          "%s": "%s",
          "c": "ciphertext",
          "i": {
              "t": "encrypted",
              "c": "e"
          },
          "u": "unique.%s",
          "m": %s,
          "o": ["12121212121259bfe28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801ff4a28b714e4cde8df10625dce72602fdbdcc53d515857f1119f5912804ce09c6cf6c2d37393a27a465134523b512664582f834e15003b7216cb668480bc3e7d1c069f2572ece7c848b9eb9a28b4e62bfc2b97c93e61b2054154e621c5bbb7bed37de3d7c343bd3dbcf7b4af20128c961351bf55910a855f08a8587c2059a5f05ca8d7a082e695b3dd4ff3ce86694d4fe98972220eea1ab90f5de493ef3a502b74a569f103ee2897ebc9ae9b16a17e7be67415ee830519beb3058ffc1c1eb0e574d66c8b365919f27eb00aa7bce475d7bdaad4ed800f8fc3d626e0eb842e312b0cc22a1ccf89847ebb2cd0a6e18aec21bd2deeec1c47301fc687f7f764bb882b50f553c246a6da5816b78b3530119ea68b08a8403a90e063e58502670563bd4d"],
          "j": [
              {
                  "c": "ciphertext.%s",
                  "s": "selector.%s",
                  "t": "term.%s"
              }
          ]
        }',
        random_key,
        random_val,
        id, m, id, id, id);

    RETURN s::eql_v1_encrypted;


  END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS create_encrypted_json();
CREATE FUNCTION create_encrypted_json()
  RETURNS eql_v1_encrypted
AS $$
  BEGIN
    RETURN (create_encrypted_json(1));
  END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS seed_encrypted(eql_v1_encrypted);
CREATE FUNCTION seed_encrypted(e eql_v1_encrypted)
  RETURNS void
AS $$
  BEGIN
    INSERT INTO encrypted (e) VALUES (e);
  END;
$$ LANGUAGE plpgsql;


--
-- Creates a table with an encrypted column for testing
--
DROP FUNCTION IF EXISTS seed_encrypted_json();
CREATE FUNCTION seed_encrypted_json()
  RETURNS void
AS $$
  BEGIN
    PERFORM seed_encrypted(create_encrypted_json(1));
    PERFORM seed_encrypted(create_encrypted_json(2));
    PERFORM seed_encrypted(create_encrypted_json(3));
  END;
$$ LANGUAGE plpgsql;


--
-- Creates a table with an encrypted column for testing
--
DROP FUNCTION IF EXISTS drop_table_with_encrypted();
CREATE FUNCTION drop_table_with_encrypted()
  RETURNS void
AS $$
  BEGIN
    DROP TABLE IF EXISTS encrypted;
END;
$$ LANGUAGE plpgsql;


--
-- Convenience function to describe a test
--
DROP FUNCTION IF EXISTS describe(text);
CREATE FUNCTION describe(s text)
    RETURNS void
AS $$
  BEGIN
    RAISE NOTICE '%', s;
END;
$$ LANGUAGE plpgsql;


--
-- Assert the the provided SQL statement returns a non-null result
--
DROP FUNCTION IF EXISTS assert_result(describe text, sql text);

CREATE FUNCTION assert_result(describe text, sql text)
  RETURNS void
AS $$
  DECLARE
    result record;
	BEGIN
    RAISE NOTICE '%', describe;
    EXECUTE sql into result;

    if result IS NULL THEN
      RAISE NOTICE 'ASSERTION FAILED';
      RAISE NOTICE '%', regexp_replace(sql, '^\s+|\s*$', '', 'g');
      ASSERT false;
    END IF;

	END;
$$ LANGUAGE plpgsql;


--
-- Assert the the provided SQL statement returns a non-null result
--
DROP FUNCTION IF EXISTS assert_id(describe text, sql text, id integer);

CREATE FUNCTION assert_id(describe text, sql text, id integer)
  RETURNS void
AS $$
  DECLARE
    result_id integer;
	BEGIN
    RAISE NOTICE '%', describe;
    EXECUTE sql into result_id;

    IF result_id <> id THEN
      RAISE NOTICE 'ASSERTION FAILED';
      RAISE NOTICE 'Expected row with id % but returned %', id, result_id;
      RAISE NOTICE '%', regexp_replace(sql, '^\s+|\s*$', '', 'g');
      ASSERT false;
    END IF;

	END;
$$ LANGUAGE plpgsql;


--
-- Assert the the provided SQL statement returns a non-null result
--
DROP FUNCTION IF EXISTS assert_no_result(describe text, sql text);

CREATE FUNCTION assert_no_result(describe text, sql text)
  RETURNS void
AS $$
  DECLARE
    result record;
	BEGIN
    RAISE NOTICE '%', describe;
    EXECUTE sql into result;

    IF result IS NOT NULL THEN
      RAISE NOTICE 'ASSERTION FAILED';
      RAISE NOTICE '%', regexp_replace(sql, '^\s+|\s*$', '', 'g');
      ASSERT false;
    END IF;

	END;
$$ LANGUAGE plpgsql;



--
-- Assert the the provided SQL statement returns a non-null result
--
DROP FUNCTION IF EXISTS assert_count(describe text, sql text, expected integer);

CREATE FUNCTION assert_count(describe text, sql text, expected integer)
  RETURNS void
AS $$
  DECLARE
    result integer;
	BEGIN
    RAISE NOTICE '%', describe;

    -- Remove any trailing ; so that the query can be wrapped with count(*) below
    sql := TRIM(TRAILING ';' FROM sql);

    EXECUTE format('SELECT COUNT(*) FROM (%s) as q', sql) INTO result;

    if result <> expected THEN
      RAISE NOTICE 'ASSERTION FAILED';
      RAISE NOTICE 'Expected % rows and returned %', expected, result;
      RAISE NOTICE '%', regexp_replace(sql, '^\s+|\s*$', '', 'g');
      ASSERT false;
    END IF;

	END;
$$ LANGUAGE plpgsql;



--
-- Assert the the provided SQL statement raises an exception
--
DROP FUNCTION IF EXISTS assert_exception(describe text, sql text);

CREATE FUNCTION assert_exception(describe text, sql text)
  RETURNS void
AS $$
	BEGIN
    RAISE NOTICE '%', describe;

    BEGIN
      EXECUTE sql;
      RAISE NOTICE 'ASSERTION FAILED';
      RAISE NOTICE 'EXPECTED STATEMENT TO RAISE EXCEPTION';
      RAISE NOTICE '%', regexp_replace(sql, '^\s+|\s*$', '', 'g');
      ASSERT false;
    EXCEPTION
      WHEN OTHERS THEN
        ASSERT true;
    END;

	END;
$$ LANGUAGE plpgsql;
