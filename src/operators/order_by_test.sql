\set ON_ERROR_STOP on

--
-- ORE - ORDER BY ore_block_u64_8_256(eql_v2_encrypted)
--
DO $$
DECLARE
    e eql_v2_encrypted;
    ore_term eql_v2_encrypted;
  BEGIN
      SELECT ore.e FROM ore WHERE id = 42 INTO ore_term;

      PERFORM assert_count(
        'ORDER BY eql_v2.order_by(e) DESC',
        format('SELECT id FROM ore WHERE e < %L ORDER BY eql_v2.order_by(e) DESC', ore_term),
        41);

      PERFORM assert_result(
        'ORDER BY eql_v2.order_by(e) DESC returns correct record',
        format('SELECT id FROM ore WHERE e < %L ORDER BY eql_v2.order_by(e) DESC LIMIT 1', ore_term),
        '41');

      PERFORM assert_result(
        'ORDER BY eql_v2.order_by(e) ASC',
        format('SELECT id FROM ore WHERE e < %L ORDER BY eql_v2.order_by(e) ASC LIMIT 1', ore_term),
        '1');
  END;
$$ LANGUAGE plpgsql;


--
-- ORE - ORDER BY without function
--
DO $$
DECLARE
    e eql_v2_encrypted;
    ore_term eql_v2_encrypted;
  BEGIN
      -- Pull a record from the ore table with value of "42"
      SELECT ore.e FROM ore WHERE id = 42 INTO ore_term;

      -- lt
      PERFORM assert_count(
        'ORDER BY eql_v2.order_by(e) DESC',
        format('SELECT id FROM ore WHERE e < %L ORDER BY e DESC', ore_term),
        41);

      PERFORM assert_result(
        'ORDER BY e DESC returns correct record',
        format('SELECT id FROM ore WHERE e < %L ORDER BY e DESC LIMIT 1', ore_term),
        '41');

      PERFORM assert_result(
        'ORDER BY e ASC',
        format('SELECT id FROM ore WHERE e < %L ORDER BY e ASC LIMIT 1', ore_term),
        '1');

      -- gt
      PERFORM assert_count(
        'ORDER BY eql_v2.order_by(e) DESC',
        format('SELECT id FROM ore WHERE e > %L ORDER BY e ASC', ore_term),
        57);

      PERFORM assert_result(
        'ORDER BY e DESC returns correct record',
        format('SELECT id FROM ore WHERE e > %L ORDER BY e DESC LIMIT 1', ore_term),
        '99');

      PERFORM assert_result(
        'ORDER BY e ASC',
        format('SELECT id FROM ore WHERE e > %L ORDER BY e ASC LIMIT 1', ore_term),
        '43');

  END;
$$ LANGUAGE plpgsql;


SELECT create_table_with_encrypted();

--
-- ORE - ORDER BY NULL handling
--
DO $$
DECLARE
    e eql_v2_encrypted;
    ore_term eql_v2_encrypted;
  BEGIN

      -- Insert records with NULL values
      -- record with ID=1 and e=NULL
      INSERT INTO encrypted(e) VALUES (NULL::jsonb::eql_v2_encrypted);


      -- Pull records from the ore table and insert
      SELECT ore.e FROM ore WHERE id = 42 INTO ore_term;
      -- record with ID=2 and e=42
      INSERT INTO encrypted(e) VALUES (ore_term);


      SELECT ore.e FROM ore WHERE id = 3 INTO ore_term;
      -- record with ID=3 and e=3
      INSERT INTO encrypted(e) VALUES (ore_term);


      -- record with ID=4 and e=NULL
      INSERT INTO encrypted(e) VALUES (NULL::jsonb::eql_v2_encrypted);

      PERFORM assert_result(
        'ORDER BY encrypted',
        format('SELECT id FROM encrypted ORDER BY e'),
        '3');

      PERFORM assert_result(
        'ORDER BY encrypted ASC',
        format('SELECT id FROM encrypted ORDER BY e ASC'),
        '3');

      PERFORM assert_result(
        'ORDER BY eql_v2.order_by(e) ASC NULLS FIRST',
        format('SELECT id FROM encrypted ORDER BY e ASC NULLS FIRST'),
        '1');

      PERFORM assert_result(
        'ORDER BY eql_v2.order_by(e) ASC NULLS LAST',
        format('SELECT id FROM encrypted ORDER BY e ASC NULLS LAST'),
        '3');

      -- NULLS FIRST when DESC
      PERFORM assert_result(
        'ORDER BY encrypted DESC',
        format('SELECT id FROM encrypted ORDER BY e DESC'),
        '1');

      PERFORM assert_result(
        'ORDER BY eql_v2.order_by(e) DESC NULLS FIRST',
        format('SELECT id FROM encrypted ORDER BY e DESC NULLS FIRST'),
        '1');

      PERFORM assert_result(
        'ORDER BY eql_v2.order_by(e) DESC NULLS LAST',
        format('SELECT id FROM encrypted ORDER BY e DESC NULLS LAST'),
        '2');

  END;
$$ LANGUAGE plpgsql;

PERFORM drop_table_with_encrypted();