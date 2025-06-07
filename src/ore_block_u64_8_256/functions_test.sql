\set ON_ERROR_STOP on

DO $$
  BEGIN
    PERFORM assert_result(
        'Extract ore index term from encrypted',
        'SELECT eql_v2.ore_block_u64_8_256(''{"ob": []}''::jsonb)');

    PERFORM assert_exception(
        'Missing ore index term in encrypted raises exception',
        'SELECT eql_v2.ore_block_u64_8_256(''{}''::jsonb)');
  END;
$$ LANGUAGE plpgsql;



DO $$
  DECLARE
    ore_term eql_v2_encrypted;
  BEGIN
    SELECT ore.e FROM ore WHERE id = 42 INTO ore_term;

    ASSERT eql_v2.has_ore_block_u64_8_256(ore_term);

  END;
$$ LANGUAGE plpgsql;



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
        'ORDER BY eql_v2.ore_block_u64_8_256(e) DESC',
        format('SELECT id FROM ore WHERE e < %L ORDER BY eql_v2.ore_block_u64_8_256(e) DESC', ore_term),
        41);

      PERFORM assert_result(
        'ORDER BY eql_v2.ore_block_u64_8_256(e) DESC returns correct record',
        format('SELECT id FROM ore WHERE e < %L ORDER BY eql_v2.ore_block_u64_8_256(e) DESC LIMIT 1', ore_term),
        '41');

      -- PERFORM assert_result(
      --   'ORDER BY eql_v2.ore_block_u64_8_256(e) ASC',
      --   format('SELECT id FROM ore WHERE e < %L ORDER BY eql_v2.ore_block_u64_8_256(e) ASC LIMIT 1', ore_term),
      --   '1');
  END;
$$ LANGUAGE plpgsql;
