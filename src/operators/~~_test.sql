\set ON_ERROR_STOP on

SELECT create_table_with_encrypted();
SELECT seed_encrypted_json();

--
-- Match - eql_v1_encrypted ~~ eql_v1_encrypted
--
DO $$
DECLARE
    e eql_v1_encrypted;
  BEGIN

    for i in 1..3 loop
      e := create_encrypted_json(i);

      PERFORM assert_result(
        format('eql_v1_encrypted ~~ eql_v1_encrypted %s of 3', i),
        format('SELECT e FROM encrypted WHERE e ~~ %L;', e));

      PERFORM assert_result(
        format('eql_v1_encrypted LIKE eql_v1_encrypted %s of 3', i),
        format('SELECT e FROM encrypted WHERE e LIKE %L;', e));

    end loop;

    -- Partial match
    e := create_encrypted_json('m')::jsonb || '{"m": [10, 11]}';

    PERFORM assert_result(
        'eql_v1_encrypted ~~ eql_v1_encrypted with partial match',
        format('SELECT e FROM encrypted WHERE e ~~ %L;', e));

    PERFORM assert_result(
        'eql_v1_encrypted LIKE eql_v1_encrypted with partial match',
        format('SELECT e FROM encrypted WHERE e LIKE %L;', e));

  END;
$$ LANGUAGE plpgsql;


--
-- Match - eql_v1_encrypted ~~* eql_v1_encrypted
--
DO $$
DECLARE
    e eql_v1_encrypted;
  BEGIN

    for i in 1..3 loop
      e := create_encrypted_json(i, 'm');

      PERFORM assert_result(
        format('eql_v1_encrypted ~~* eql_v1_encrypted %s of 3', i),
        format('SELECT e FROM encrypted WHERE e ~~* %L;', e));

      PERFORM assert_result(
        format('eql_v1_encrypted LIKE eql_v1_encrypted %s of 3', i),
        format('SELECT e FROM encrypted WHERE e ILIKE %L;', e));

    end loop;

    -- Partial match
    e := create_encrypted_json('m')::jsonb || '{"m": [10, 11]}';

    PERFORM assert_result(
        'eql_v1_encrypted ~~* eql_v1_encrypted with partial match',
        format('SELECT e FROM encrypted WHERE e ~~* %L;', e));

    PERFORM assert_result(
        'eql_v1_encrypted LIKE eql_v1_encrypted with partial match',
        format('SELECT e FROM encrypted WHERE e ILIKE %L;', e));

  END;
$$ LANGUAGE plpgsql;


--
-- Match - eql_v1.match(eql_v1_encrypted, eql_v1_encrypted)
--
DO $$
DECLARE
    e eql_v1_encrypted;
  BEGIN

    for i in 1..3 loop
      e := create_encrypted_json(i, 'm');

      PERFORM assert_result(
        format('eql_v1.like(eql_v1_encrypted, eql_v1_encrypted)', i),
        format('SELECT e FROM encrypted WHERE eql_v1.like(e, %L);', e));

    end loop;

    -- Partial match
    e := create_encrypted_json('m')::jsonb || '{"m": [10, 11]}';

    PERFORM assert_result(
        'eql_v1.like(eql_v1_encrypted, eql_v1_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v1.like(e, %L);', e));

  END;
$$ LANGUAGE plpgsql;




SELECT drop_table_with_encrypted();