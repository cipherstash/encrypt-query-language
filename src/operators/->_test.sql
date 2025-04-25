\set ON_ERROR_STOP on


SELECT create_table_with_encrypted();
SELECT seed_encrypted_json();

--
-- The -> operator returns an encrypted matching the selector
DO $$
  BEGIN
    PERFORM assert_result(
        'Selector -> returns at least one eql_v1_encrypted',
        'SELECT e->''bca213de9ccce676fa849ff9c4807963'' FROM encrypted;');

    PERFORM assert_count(
        'Selector -> returns all eql_v1_encrypted',
        'SELECT e->''bca213de9ccce676fa849ff9c4807963'' FROM encrypted;',
        3);
  END;
$$ LANGUAGE plpgsql;


--
-- The -> operator returns NULL if no matching selector
DO $$
  BEGIN
    PERFORM assert_no_result(
        'Unknown selector -> returns null',
        'SELECT e->''blahvtha'' FROM encrypted;');

  END;
$$ LANGUAGE plpgsql;



--
-- encrypted returned from -> operator expression called via eql_v1.ciphertext
--
DO $$
  DECLARE
    result eql_v1_encrypted;
  BEGIN
    PERFORM assert_result(
        'Fetch ciphertext via selector',
        'SELECT eql_v1.ciphertext(e->''2517068c0d1f9d4d41d2c666211f785e'') FROM encrypted;');

    PERFORM assert_count(
        'Fetch ciphertext via selector returns all eql_v1_encrypted',
        'SELECT eql_v1.ciphertext(e->''2517068c0d1f9d4d41d2c666211f785e'') FROM encrypted;',
        3);
  END;
$$ LANGUAGE plpgsql;

