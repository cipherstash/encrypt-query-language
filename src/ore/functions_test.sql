\set ON_ERROR_STOP on

DO $$
  BEGIN
    PERFORM assert_result(
        'Extract ore index term from encrypted',
        'SELECT eql_v1.ore_64_8_v1(''{"o": []}''::jsonb)');

    PERFORM assert_exception(
        'Missing ore index term in encrypted raises exception',
        'SELECT eql_v1.ore_64_8_v1(''{}''::jsonb)');

  END;
$$ LANGUAGE plpgsql;

--
-- ORE - ORDER BY ore_64_8_v1(eql_v1_encrypted)
--
DO $$
DECLARE
    e eql_v1_encrypted;
    ore_term eql_v1_encrypted;
  BEGIN
      SELECT ore.e FROM ore WHERE id = 42 INTO ore_term;

      PERFORM assert_count(
        'ORDER BY eql_v1.ore_64_8_v1(e) DESC',
        format('SELECT id FROM ore WHERE e < %L ORDER BY eql_v1.ore_64_8_v1(e) DESC', ore_term),
        41);

      PERFORM assert_result(
        'ORDER BY eql_v1.ore_64_8_v1(e) DESC returns correct record',
        format('SELECT id FROM ore WHERE e < %L ORDER BY eql_v1.ore_64_8_v1(e) DESC LIMIT 1', ore_term),
        '41');

      PERFORM assert_result(
        'ORDER BY eql_v1.ore_64_8_v1(e) ASC',
        format('SELECT id FROM ore WHERE e < %L ORDER BY eql_v1.ore_64_8_v1(e) ASC LIMIT 1', ore_term),
        '1');
  END;
$$ LANGUAGE plpgsql;