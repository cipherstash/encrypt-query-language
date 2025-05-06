\set ON_ERROR_STOP on

SELECT create_table_with_encrypted();
SELECT seed_encrypted_json();


--
-- ORE - eql_v1_encrypted = eql_v1_encrypted
--
DO $$
DECLARE
    e eql_v1_encrypted;
    ore_term jsonb;
  BEGIN

      -- Record with a Numeric ORE term of 42
      e := create_encrypted_ore_json(42);
      PERFORM seed_encrypted(e);

      PERFORM assert_result(
        'eql_v1_encrypted = eql_v1_encrypted',
        format('SELECT e FROM encrypted WHERE e = %L::eql_v1_encrypted', e));

      PERFORM assert_count(
          format('eql_v1_encrypted = eql_v1_encrypted'),
          format('SELECT e FROM encrypted WHERE e = %L;', e),
          1);

      e := create_encrypted_ore_json(20);

      PERFORM assert_result(
        'eql_v1_encrypted = eql_v1_encrypted',
        format('SELECT e FROM encrypted WHERE e = %L::eql_v1_encrypted', e));

      PERFORM assert_count(
        format('eql_v1_encrypted = eql_v1_encrypted'),
        format('SELECT e FROM encrypted WHERE e = %L;', e),
        1);
  END;
$$ LANGUAGE plpgsql;


--
-- ORE - eql_v1.gte(a eql_v1_encrypted, b eql_v1_encrypted)
--
DO $$
DECLARE
    e eql_v1_encrypted;
    ore_term jsonb;
  BEGIN
      -- Reset data
      PERFORM seed_encrypted_json();

      -- Record with a Numeric ORE term of 20
      e := create_encrypted_ore_json(20);
      PERFORM seed_encrypted(e);

     PERFORM assert_result(
        'eql_v1.eq(a eql_v1_encrypted, b eql_v1_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v1.eq(e, %L)', e));

     -- include
     PERFORM assert_count(
        'eql_v1.eq(a eql_v1_encrypted, b eql_v1_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v1.eq(e, %L)', e),
        2);

      -- Record with a Numeric ORE term of 30
      e := create_encrypted_ore_json(30);

      PERFORM assert_result(
        'eql_v1.get(a eql_v1_encrypted, b eql_v1_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v1.eq(e, %L)', e));

     PERFORM assert_count(
        'eql_v1.get(a eql_v1_encrypted, b eql_v1_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v1.eq(e, %L)', e),
        1);
  END;
$$ LANGUAGE plpgsql;



-- ========================================================================


SELECT drop_table_with_encrypted();