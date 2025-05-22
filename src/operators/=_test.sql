\set ON_ERROR_STOP on

SELECT create_table_with_encrypted();
SELECT seed_encrypted_json();


--
-- Unique equality - eql_v2_encrypted = eql_v2_encrypted
--
DO $$
DECLARE
    e eql_v2_encrypted;
  BEGIN

    for i in 1..3 loop
      e := create_encrypted_json(i, 'u');

      PERFORM assert_result(
        format('eql_v2_encrypted = eql_v2_encrypted with unique index term %s of 3', i),
        format('SELECT e FROM encrypted WHERE e = %L;', e));

    end loop;

    -- remove the ore index term
    e := create_encrypted_json(91347, 'u');

    PERFORM assert_no_result(
        'eql_v2_encrypted = eql_v2_encrypted with no matching record',
        format('SELECT e FROM encrypted WHERE e = %L;', e));

  END;
$$ LANGUAGE plpgsql;


--
-- Unique equality - eql_v2.eq(eql_v2_encrypted, eql_v2_encrypted)
--
DO $$
DECLARE
    e eql_v2_encrypted;
  BEGIN

    for i in 1..3 loop
      e := create_encrypted_json(i)::jsonb-'o';

      PERFORM assert_result(
        format('eql_v2.eq(eql_v2_encrypted, eql_v2_encrypted) with unique index term %s of 3', i),
        format('SELECT e FROM encrypted WHERE eql_v2.eq(e, %L);', e));
    end loop;

    -- remove the ore index term
    e := create_encrypted_json(91347)::jsonb-'o';

    PERFORM assert_no_result(
        'eql_v2.eq(eql_v2_encrypted, eql_v2_encrypted) with no matching record',
        format('SELECT e FROM encrypted WHERE eql_v2.eq(e, %L);', e));

  END;
$$ LANGUAGE plpgsql;


--
-- Unique equality - eql_v2_encrypted = jsonb
--
DO $$
DECLARE
    e jsonb;
  BEGIN
    for i in 1..3 loop

      -- remove the default
      e := create_encrypted_json(i)::jsonb-'o';

      PERFORM assert_result(
        format('eql_v2_encrypted = jsonb with unique index term %s of 3', i),
        format('SELECT e FROM encrypted WHERE e = %L::jsonb;', e));

      PERFORM assert_result(
        format('jsonb = eql_v2_encrypted with unique index term %s of 3', i),
        format('SELECT e FROM encrypted WHERE %L::jsonb = e', e));
    end loop;

    e := create_encrypted_json(91347)::jsonb-'o';

    PERFORM assert_no_result(
        'eql_v2_encrypted = jsonb with no matching record',
        format('SELECT e FROM encrypted WHERE e = %L::jsonb', e));

    PERFORM assert_no_result(
        'jsonb = eql_v2_encrypted with no matching record',
        format('SELECT e FROM encrypted WHERE %L::jsonb = e', e));

  END;
$$ LANGUAGE plpgsql;



-- ========================================================================

-- ------------------------------------------------------------------------
-- ------------------------------------------------------------------------
--
-- Blake  equality - eql_v2_encrypted = eql_v2_encrypted
--
DO $$
DECLARE
    e eql_v2_encrypted;
  BEGIN

    for i in 1..3 loop
      e := create_encrypted_json(i, 'b3');

      PERFORM assert_result(
        format('eql_v2_encrypted = eql_v2_encrypted with unique index term %s of 3', i),
        format('SELECT e FROM encrypted WHERE e = %L;', e));

    end loop;

    -- remove the ore index term
    e := create_encrypted_json(91347, 'b3');

    PERFORM assert_no_result(
        'eql_v2_encrypted = eql_v2_encrypted with no matching record',
        format('SELECT e FROM encrypted WHERE e = %L;', e));

  END;
$$ LANGUAGE plpgsql;


-- ------------------------------------------------------------------------
-- ------------------------------------------------------------------------
--
-- Blake3 equality - eql_v2.eq(eql_v2_encrypted, eql_v2_encrypted)
--
DO $$
DECLARE
    e eql_v2_encrypted;
  BEGIN

    for i in 1..3 loop
      e := create_encrypted_json(i, 'b3');

      PERFORM assert_result(
        format('eql_v2.eq(eql_v2_encrypted, eql_v2_encrypted) with unique index term %s of 3', i),
        format('SELECT e FROM encrypted WHERE eql_v2.eq(e, %L);', e));
    end loop;

    -- remove the ore index term
    e := create_encrypted_json(91347, 'b3');

    PERFORM assert_no_result(
        'eql_v2.eq(eql_v2_encrypted, eql_v2_encrypted) with no matching record',
        format('SELECT e FROM encrypted WHERE eql_v2.eq(e, %L);', e));

  END;
$$ LANGUAGE plpgsql;


-- ------------------------------------------------------------------------
-- ------------------------------------------------------------------------
--
-- Blake3 equality - eql_v2_encrypted = jsonb
--
DO $$
DECLARE
    e jsonb;
  BEGIN
    for i in 1..3 loop

      -- remove the default
      e := create_encrypted_json(i, 'b3');

      PERFORM assert_result(
        format('eql_v2_encrypted = jsonb with unique index term %s of 3', i),
        format('SELECT e FROM encrypted WHERE e = %L::jsonb;', e));

      PERFORM assert_result(
        format('jsonb = eql_v2_encrypted with unique index term %s of 3', i),
        format('SELECT e FROM encrypted WHERE %L::jsonb = e', e));
    end loop;

    e := create_encrypted_json(91347, 'b3');

    PERFORM assert_no_result(
        'eql_v2_encrypted = jsonb with no matching record',
        format('SELECT e FROM encrypted WHERE e = %L::jsonb', e));

    PERFORM assert_no_result(
        'jsonb = eql_v2_encrypted with no matching record',
        format('SELECT e FROM encrypted WHERE %L::jsonb = e', e));

  END;
$$ LANGUAGE plpgsql;


SELECT drop_table_with_encrypted();