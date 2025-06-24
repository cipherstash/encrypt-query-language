\set ON_ERROR_STOP on

SELECT create_table_with_encrypted();
SELECT seed_encrypted_json();



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

    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''("{\"bf\": \"[1,2,3\"}")'';' into result;

    -- PERFORM eql_v2.log('', result);

    IF position('Bitmap Heap Scan on encrypted' in result) > 0 THEN
      RAISE EXCEPTION 'Unexpected Bitmap Heap Scan: %', result;
    ELSE
      ASSERT true;
    END IF;

    -- NO INDEX WILL BE USED
    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''("{\"hm\": \"abc\"}")'';' into result;

    -- PERFORM eql_v2.log('', result);

    IF position('Bitmap Heap Scan on encrypted' in result) > 0 THEN
      RAISE EXCEPTION 'Unexpected Bitmap Heap Scan: %', result;
    ELSE
      ASSERT true;
    END IF;

    INSERT INTO encrypted (e) VALUES ('("{\"hm\": \"abc\"}")');
    INSERT INTO encrypted (e) VALUES ('("{\"hm\": \"def\"}")');
    INSERT INTO encrypted (e) VALUES ('("{\"hm\": \"ghi\"}")');

    -- STILL NO INDEX WILL BE USED
    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''("{\"hm\": \"abc\"}")'';' into result;

    IF position('Bitmap Heap Scan on encrypted' in result) > 0 THEN
      RAISE EXCEPTION 'Unexpected Bitmap Heap Scan: %', result;
    ELSE
      ASSERT true;
    END IF;

    DROP INDEX encrypted_index;
    CREATE INDEX encrypted_index ON encrypted (e eql_v2.encrypted_operator_class);

    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''("{\"hm\": \"abc\"}")'';' into result;

    -- AND STILL NOPE
    IF position('Bitmap Heap Scan on encrypted' in result) > 0 THEN
      RAISE EXCEPTION 'Unexpected Bitmap Heap Scan: %', result;
    ELSE
      ASSERT true;
    END IF;


    TRUNCATE encrypted;
    DROP INDEX encrypted_index;
    CREATE INDEX encrypted_index ON encrypted (e eql_v2.encrypted_operator_class);

    INSERT INTO encrypted (e) VALUES ('("{\"hm\": \"abc\"}")');
    INSERT INTO encrypted (e) VALUES ('("{\"hm\": \"def\"}")');
    INSERT INTO encrypted (e) VALUES ('("{\"hm\": \"ghi\"}")');

    EXECUTE 'EXPLAIN ANALYZE SELECT e::jsonb FROM encrypted WHERE e = ''("{\"hm\": \"abc\"}")'';' into result;

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

    PERFORM eql_v2.log(result);

     IF position('Index Only Scan using encrypted' in result) > 0 THEN
      ASSERT true;
    ELSE
      RAISE EXCEPTION 'Expected Index Only Scan: %', result;
    END IF;

  END;
$$ LANGUAGE plpgsql;


