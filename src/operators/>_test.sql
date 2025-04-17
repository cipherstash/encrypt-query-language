\set ON_ERROR_STOP on

SELECT create_table_with_encrypted();
SELECT seed_encrypted_json();

--
-- ORE - eql_v1_encrypted > eql_v1_encrypted
--
DO $$
DECLARE
    e eql_v1_encrypted;
    ore_term jsonb;
  BEGIN

      -- Create a record with HIGH ore
      e := create_encrypted_json()::jsonb || get_high_ore();
      PERFORM seed_encrypted(e);

      -- Default has LOW ore
      e := create_encrypted_json();

      PERFORM assert_result(
        'eql_v1_encrypted > eql_v1_encrypted',
        format('SELECT e FROM encrypted WHERE e > %L::eql_v1_encrypted', e));

      for i in 1..3 loop
        e := create_encrypted_json(i);

        PERFORM assert_result(
          format('eql_v1_encrypted > eql_v1_encrypted %s of 3', i),
          format('SELECT e FROM encrypted WHERE e > %L;', e));
      end loop;

  END;
$$ LANGUAGE plpgsql;


--
-- ORE - eql_v1.gt(a eql_v1_encrypted, b eql_v1_encrypted)
--
DO $$
DECLARE
    e eql_v1_encrypted;
    ore_term jsonb;
  BEGIN

      -- Create a record with HIGH ore
      e := create_encrypted_json()::jsonb || get_high_ore();
      PERFORM seed_encrypted(e);

      -- Default has LOW ore
      e := create_encrypted_json();

      PERFORM assert_result(
        'eql_v1.get(a eql_v1_encrypted, b eql_v1_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v1.gt(e, %L)', e));

     PERFORM assert_count(
        'eql_v1.get(a eql_v1_encrypted, b eql_v1_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v1.gt(e, %L)', e),
        2);
  END;
$$ LANGUAGE plpgsql;


SELECT drop_table_with_encrypted();