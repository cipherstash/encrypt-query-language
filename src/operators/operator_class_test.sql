\set ON_ERROR_STOP on

SELECT create_table_with_encrypted();
SELECT seed_encrypted_json();

--
-- ORE ORDER BY
--
DO $$
DECLARE
    ore_term eql_v1_encrypted;
  BEGIN

      PERFORM assert_id(
        'ORDER BY eql_v1_encrypted DESC',
        'SELECT id FROM ore ORDER BY e DESC LIMIT 1',
        99);

      PERFORM assert_id(
        'ORDER BY eql_v1_encrypted DESC',
        'SELECT id FROM ore ORDER BY e ASC LIMIT 1',
        1);


      SELECT e FROM ore WHERE id = 42 INTO ore_term;

      PERFORM assert_id(
        'eql_v1_encrypted < eql_v1_encrypted',
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
        'GROUP BY eql_v1_encrypted',
        'SELECT count(id) FROM encrypted GROUP BY e ORDER BY count(id) DESC',
        4);


  END;
$$ LANGUAGE plpgsql;


SELECT drop_table_with_encrypted();