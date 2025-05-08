\set ON_ERROR_STOP on

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
        'ORDER BY eql_v1.order_by(e) DESC',
        format('SELECT id FROM ore WHERE e < %L ORDER BY eql_v1.order_by(e) DESC', ore_term),
        41);

      PERFORM assert_result(
        'ORDER BY eql_v1.order_by(e) DESC returns correct record',
        format('SELECT id FROM ore WHERE e < %L ORDER BY eql_v1.order_by(e) DESC LIMIT 1', ore_term),
        '41');

      PERFORM assert_result(
        'ORDER BY eql_v1.order_by(e) ASC',
        format('SELECT id FROM ore WHERE e < %L ORDER BY eql_v1.order_by(e) ASC LIMIT 1', ore_term),
        '1');
  END;
$$ LANGUAGE plpgsql;