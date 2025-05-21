\set ON_ERROR_STOP on

SELECT create_table_with_encrypted();
SELECT seed_encrypted_json();

--
-- The ->> operator returns ciphertext matching the selector
DO $$
  BEGIN
    PERFORM assert_result(
        'Selector ->> returns at least one eql_v2_encrypted',
        'SELECT e->>''bca213de9ccce676fa849ff9c4807963'' FROM encrypted;');

    PERFORM assert_count(
        'Selector ->> returns all eql_v2_encrypted',
        'SELECT e->>''bca213de9ccce676fa849ff9c4807963'' FROM encrypted;',
        3);
  END;
$$ LANGUAGE plpgsql;


--
-- The ->> operator returns NULL if no matching selector
DO $$
  BEGIN
    PERFORM assert_no_result(
        'Unknown selector -> returns null',
        'SELECT e->>''blahvtha'' FROM encrypted;');

  END;
$$ LANGUAGE plpgsql;


--
-- The ->> operator returns ciphertext matching the selector
DO $$
  BEGIN

    PERFORM assert_result(
        'Selector ->> returns all eql_v2_encrypted',
        'SELECT e->>''bca213de9ccce676fa849ff9c4807963'' FROM encrypted LIMIT 1;',
        'mBbLGB9xHAGzLvUj-`@Wmf=IhD87n7r3ir3n!Sk6AKir_YawR=0c>pk(OydB;ntIEXK~c>V&4>)rNkf<JN7fmlO)c^iBv;-X0+3XyK5d`&&I-oeIEOcwPf<3zy');
  END;
$$ LANGUAGE plpgsql;

