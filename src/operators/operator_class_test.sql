\set ON_ERROR_STOP on

SELECT create_table_with_encrypted();
SELECT seed_encrypted_json();

--
-- ORE ORDER BY
--
DO $$
DECLARE
    ore_term eql_v2_encrypted;
  BEGIN

      PERFORM assert_id(
        'ORDER BY eql_v2_encrypted DESC',
        'SELECT id FROM ore ORDER BY e DESC LIMIT 1',
        99);

      PERFORM assert_id(
        'ORDER BY eql_v2_encrypted DESC',
        'SELECT id FROM ore ORDER BY e ASC LIMIT 1',
        1);


      SELECT e FROM ore WHERE id = 42 INTO ore_term;

      PERFORM assert_id(
        'eql_v2_encrypted < eql_v2_encrypted',
        format('SELECT id FROM ore WHERE e < %L ORDER BY e DESC LIMIT 1', ore_term),
        41);

  END;
$$ LANGUAGE plpgsql;



--
-- ORE GROUP BY
--
DO $$
  BEGIN

      -- Copy ORE data into encrypted
      INSERT INTO encrypted(e) SELECT e FROM ore WHERE ore.id=42;
      INSERT INTO encrypted(e) SELECT e FROM ore WHERE ore.id=42;
      INSERT INTO encrypted(e) SELECT e FROM ore WHERE ore.id=42;
      INSERT INTO encrypted(e) SELECT e FROM ore WHERE ore.id=42;
      INSERT INTO encrypted(e) SELECT e FROM ore WHERE ore.id=99;
      INSERT INTO encrypted(e) SELECT e FROM ore WHERE ore.id=99;

      -- Should be the rows with value of 42
      PERFORM assert_id(
        'GROUP BY eql_v2_encrypted',
        'SELECT count(id) FROM encrypted GROUP BY e ORDER BY count(id) DESC',
        4);


  END;
$$ LANGUAGE plpgsql;

SELECT * FROM encrypted;

--
-- ORE GROUP BY
--
DO $$
  DECLARE
    ore_term eql_v2_encrypted;
    result text;
  BEGIN

    PERFORM create_table_with_encrypted();

    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''("{\"hm\": \"abc\"}")'';' into result;

    PERFORM eql_v2.log('', result);

    IF position('Bitmap Heap Scan on encrypted' in result) > 0 THEN
      RAISE EXCEPTION 'Unexpected Bitmap Heap Scan: %', result;
    ELSE
      ASSERT true;
    END IF;

    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''("{\"ob\": \"abc\"}")'';' into result;

    PERFORM eql_v2.log('', result);

    IF position('Bitmap Heap Scan on encrypted' in result) > 0 THEN
      RAISE EXCEPTION 'Unexpected Bitmap Heap Scan: %', result;
    ELSE
      ASSERT true;
    END IF;


    -- Add index
    CREATE INDEX ON encrypted (e);

    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''("{\"hm\": \"abc\"}")'';' into result;

    PERFORM eql_v2.log(result);

    IF position('Bitmap Heap Scan on encrypted' in result) > 0 THEN
      ASSERT true;
    ELSE
      RAISE EXCEPTION 'Expected Bitmap Heap Scan: %', result;
    END IF;

    PERFORM seed_encrypted_json();

    SELECT ore.e FROM ore WHERE id = 42 INTO ore_term;
    EXECUTE format('EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = %L::eql_v2_encrypted;', ore_term) into result;

    PERFORM eql_v2.log(result);

    IF position('Bitmap Heap Scan on encrypted' in result) > 0 THEN
      ASSERT true;
    ELSE
      RAISE EXCEPTION 'Expected Bitmap Heap Scan: %', result;
    END IF;


    -- ---
    -- EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''("{\"blah\": \"vtha\"}")'';' into result;

    -- IF position('Bitmap Heap Scan on encrypted' in result) > 0 THEN
    --   ASSERT true;
    -- ELSE
    --   RAISE EXCEPTION 'Expected Bitmap Heap Scan: %', result;
    -- END IF;

  END;
$$ LANGUAGE plpgsql;

SELECT drop_table_with_encrypted();