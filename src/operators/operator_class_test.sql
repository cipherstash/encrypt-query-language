\set ON_ERROR_STOP on

--
-- ORE GROUP BY
--
DO $$
  BEGIN

      PERFORM create_table_with_encrypted();

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

--
-- Confirm index used correctly
--
DO $$
  DECLARE
    ore_term eql_v2_encrypted;
    result text;
  BEGIN

    PERFORM create_table_with_encrypted();

    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''("{\"ob\": \"abc\"}")'';' into result;

    -- PERFORM eql_v2.log('', result);

    IF position('Bitmap Heap Scan on encrypted' in result) > 0 THEN
      RAISE EXCEPTION 'Unexpected Bitmap Heap Scan: %', result;
    ELSE
      ASSERT true;
    END IF;

    -- Add index
    CREATE INDEX ON encrypted (e eql_v2.encrypted_operator_class);

    SELECT ore.e FROM ore WHERE id = 42 INTO ore_term;
    EXECUTE format('EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = %L::eql_v2_encrypted;', ore_term) into result;

    IF position('Bitmap Heap Scan on encrypted' in result) > 0 THEN
      ASSERT true;
    ELSE
      RAISE EXCEPTION 'Expected Bitmap Heap Scan: %', result;
    END IF;

    -- INDEX WILL BE USED
    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''("{\"hm\": \"abc\"}")'';' into result;

    IF position('Bitmap Heap Scan on encrypted' in result) > 0 THEN
      ASSERT true;
    ELSE
      RAISE EXCEPTION 'Expected Bitmap Heap Scan: %', result;
    END IF;

    ---
    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''("{\"blah\": \"vtha\"}")'';' into result;

    IF position('Bitmap Heap Scan on encrypted' in result) > 0 THEN
      ASSERT true;
    ELSE
      RAISE EXCEPTION 'Expected Bitmap Heap Scan: %', result;
    END IF;

  END;
$$ LANGUAGE plpgsql;



--
-- Adding index to table where values do not have an appropriate search term
--
DO $$
  DECLARE
    ore_term eql_v2_encrypted;
    result text;
  BEGIN

    PERFORM create_table_with_encrypted();

    INSERT INTO encrypted (e) VALUES ('("{\"bf\": \"[1, 2, 3]\"}")');

    -- Add index
    CREATE INDEX encrypted_index ON encrypted (e eql_v2.encrypted_operator_class);

    ANALYZE encrypted;

    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''("{\"bf\": \"[1,2,3]\"}")'';' into result;

    IF position('Seq Scan on encrypted' in result) > 0 THEN
      ASSERT true;
    ELSE
      RAISE EXCEPTION 'Unexpected Seq Scan: %', result;
    END IF;

    -- NO INDEX WILL BE USED
    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''("{\"hm\": \"abc\"}")'';' into result;

    IF position('Seq Scan on encrypted' in result) > 0 THEN
      ASSERT true;
    ELSE
      RAISE EXCEPTION 'Unexpected Seq Scan: %', result;
    END IF;

    INSERT INTO encrypted (e) VALUES ('("{\"hm\": \"abc\"}")');
    INSERT INTO encrypted (e) VALUES ('("{\"hm\": \"def\"}")');
    INSERT INTO encrypted (e) VALUES ('("{\"hm\": \"ghi\"}")');

    ANALYZE encrypted;

    -- STILL NO INDEX WILL BE USED
    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''("{\"hm\": \"abc\"}")'';' into result;

    IF position('Seq Scan on encrypted' in result) > 0 THEN
      ASSERT true;
    ELSE
      RAISE EXCEPTION 'Unexpected Seq Scan: %', result;
    END IF;

    DROP INDEX encrypted_index;
    CREATE INDEX encrypted_index ON encrypted (e eql_v2.encrypted_operator_class);

    ANALYZE encrypted;

    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''("{\"hm\": \"abc\"}")'';' into result;

    -- -- AND STILL NOPE
    IF position('Seq Scan on encrypted' in result) > 0 THEN
      ASSERT true;
    ELSE
      RAISE EXCEPTION 'Unexpected Seq Scan: %', result;
    END IF;


    TRUNCATE encrypted;
    DROP INDEX encrypted_index;
    CREATE INDEX encrypted_index ON encrypted (e eql_v2.encrypted_operator_class);

    INSERT INTO encrypted (e) VALUES ('("{\"hm\": \"abc\"}")');
    INSERT INTO encrypted (e) VALUES ('("{\"hm\": \"def\"}")');
    INSERT INTO encrypted (e) VALUES ('("{\"hm\": \"ghi\"}")');
    INSERT INTO encrypted (e) VALUES ('("{\"hm\": \"jkl\"}")');
    INSERT INTO encrypted (e) VALUES ('("{\"hm\": \"mno\"}")');

    -- Literal row type type thing
    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''("{\"hm\": \"abc\"}")'';' into result;

    IF position('Index Only Scan using encrypted' in result) > 0 THEN
      ASSERT true;
    ELSE
      RAISE EXCEPTION 'Expected Index Only Scan: %', result;
    END IF;

    -- Cast to jsonb to eql_v2_encrypted
    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''{"hm": "abc"}''::jsonb::eql_v2_encrypted;' into result;

    IF position('Index Only Scan using encrypted' in result) > 0 THEN
      ASSERT true;
    ELSE
      RAISE EXCEPTION 'Expected Index Only Scan: %', result;
    END IF;

    -- Cast to text to eql_v2_encrypted
    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''{"hm": "abc"}''::text::eql_v2_encrypted;' into result;

    IF position('Index Only Scan using encrypted' in result) > 0 THEN
      ASSERT true;
    ELSE
      RAISE EXCEPTION 'Expected Index Only Scan: %', result;
    END IF;

    -- Use to_encrypted with jsonb
    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = eql_v2.to_encrypted(''{"hm": "abc"}''::jsonb);' into result;

    IF position('Index Only Scan using encrypted' in result) > 0 THEN
      ASSERT true;
    ELSE
      RAISE EXCEPTION 'Expected Index Only Scan: %', result;
    END IF;

    -- Use to_encrypted with text
    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = eql_v2.to_encrypted(''{"hm": "abc"}'');' into result;


    IF position('Index Only Scan using encrypted' in result) > 0 THEN
      ASSERT true;
    ELSE
      RAISE EXCEPTION 'Expected Index Only Scan: %', result;
    END IF;

    --
    SELECT ore.e FROM ore WHERE id = 42 INTO ore_term;
    EXECUTE format('EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = %L::eql_v2_encrypted;', ore_term) into result;

    IF position('Index Only Scan using encrypted' in result) > 0 THEN
      ASSERT true;
    ELSE
      RAISE EXCEPTION 'Expected Index Only Scan: %', result;
    END IF;


    TRUNCATE encrypted;
    PERFORM seed_encrypted_json();

    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''("{\"blah\": \"vtha\"}")'';' into result;

     IF position('Index Only Scan using encrypted' in result) > 0 THEN
      ASSERT true;
    ELSE
      RAISE EXCEPTION 'Expected Index Only Scan: %', result;
    END IF;

  END;
$$ LANGUAGE plpgsql;


