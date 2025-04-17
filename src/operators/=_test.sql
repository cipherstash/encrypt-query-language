\set ON_ERROR_STOP on

SELECT create_table_with_encrypted();
SELECT seed_encrypted_json();

SELECT e FROM encrypted WHERE e = '("{""c"": ""ciphertext"", ""i"": {""c"": ""e"", ""t"": ""encrypted""}, ""j"": [{""c"": ""ciphertext.1"", ""s"": ""selector.1"", ""t"": ""term.1""}], ""m"": [10, 11, 12, 13, 14, 15], ""u"": ""unique.1"", ""75d1219a941e4853572b60f51"": ""902cd835193393f41315d2e00""}")';

--
-- Unique equality - eql_v1_encrypted = eql_v1_encrypted
--
DO $$
DECLARE
    e eql_v1_encrypted;
  BEGIN

    for i in 1..3 loop
      e := create_encrypted_json(i)::jsonb-'o';

      PERFORM assert_result(
        format('eql_v1_encrypted = eql_v1_encrypted with unique index term %s of 3', i),
        format('SELECT e FROM encrypted WHERE e = %L;', e));

    end loop;

    -- remove the ore index term
    e := create_encrypted_json(91347)::jsonb-'o';

    PERFORM assert_no_result(
        'eql_v1_encrypted = eql_v1_encrypted with no matching record',
        format('SELECT e FROM encrypted WHERE e = %L;', e));

  END;
$$ LANGUAGE plpgsql;


--
-- Unique equality - eql_v1.eq(eql_v1_encrypted, eql_v1_encrypted)
--
DO $$
DECLARE
    e eql_v1_encrypted;
  BEGIN

    for i in 1..3 loop
      e := create_encrypted_json(i)::jsonb-'o';

      PERFORM assert_result(
        format('eql_v1.eq(eql_v1_encrypted, eql_v1_encrypted) with unique index term %s of 3', i),
        format('SELECT e FROM encrypted WHERE eql_v1.eq(e, %L);', e));
    end loop;

    -- remove the ore index term
    e := create_encrypted_json(91347)::jsonb-'o';

    PERFORM assert_no_result(
        'eql_v1.eq(eql_v1_encrypted, eql_v1_encrypted) with no matching record',
        format('SELECT e FROM encrypted WHERE eql_v1.eq(e, %L);', e));

  END;
$$ LANGUAGE plpgsql;


--
-- Unique equality - eql_v1_encrypted = jsonb
--
DO $$
DECLARE
    e jsonb;
  BEGIN
    for i in 1..3 loop

      -- remove the default
      e := create_encrypted_json(i)::jsonb-'o';

      PERFORM assert_result(
        format('eql_v1_encrypted = jsonb with unique index term %s of 3', i),
        format('SELECT e FROM encrypted WHERE e = %L::jsonb;', e));

      PERFORM assert_result(
        format('jsonb = eql_v1_encrypted with unique index term %s of 3', i),
        format('SELECT e FROM encrypted WHERE %L::jsonb = e', e));
    end loop;

    e := create_encrypted_json(91347)::jsonb-'o';

    PERFORM assert_no_result(
        'eql_v1_encrypted = jsonb with no matching record',
        format('SELECT e FROM encrypted WHERE e = %L::jsonb', e));

    PERFORM assert_no_result(
        'jsonb = eql_v1_encrypted with no matching record',
        format('SELECT e FROM encrypted WHERE %L::jsonb = e', e));

  END;
$$ LANGUAGE plpgsql;


--
-- Example ORE values are generated from an array in the form `vec![0, 1, 2, 3, 4, 5]`;
--
-- JSON values are JSON escaped on top of a PostgreSQL escaped Record
--
-- PostgreSQL value is ("{""(\\""\\\\\\\\x000102030405\\"")""}")
--
--
DO $$
DECLARE
    e eql_v1_encrypted;
    ore_term jsonb;
  BEGIN

      -- remove the unique index term
      e := create_encrypted_json()::jsonb-'u';

      PERFORM assert_result(
        format('eql_v1_encrypted = eql_v1_encrypted with ore index term'),
        format('SELECT e FROM encrypted WHERE e = %L', e));

      PERFORM assert_count(
        format('eql_v1_encrypted = eql_v1_encrypted with ore index term'),
        format('SELECT e FROM encrypted WHERE e = %L', e),
        3);


      -- -- not the same ore term
      ore_term := '{"o": ["1212121212125932e28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd8011f94b49eaa5fa5a60e1e2adccde4185a7d6c7f83088500b677f897d4ffc276016d614708488f407c01bd3ccf2be653269062cb97f8945a621d049277d19b1c248611f25d047038928d2efeb4323c402af4c19288c7b36911dc06639af5bb34367519b66c1f525bbd3828c12067c9c579aeeb4fb3ae0918125dc1dad5fd518019a5ae67894ce1a7f7bed1a591ba8edda2fdf4cd403761fd981fb1ea5eb0bf806f919350ee60cac16d0a39a491a4d79301781f95ea3870aea82e9946053537360b2fb415b18b61aed0af81d461ad6b923f10c0df79daddc4e279ff543a282bb3a37f9fa03238348b3dac51a453b04bced1f5bd318ddd829bdfe5f37abdbeda730e21441b818302f3c5c2c4d5657accfca4c53d7a80eb3db43946d38965be5f796b"]}'::jsonb;

      -- remove the unique index term and add the ore term
      e := create_encrypted_json()::jsonb-'u' || ore_term;

      PERFORM assert_no_result(
        format('eql_v1_encrypted = eql_v1_encrypted with ore index term'),
        format('SELECT e FROM encrypted WHERE e = %L', e));

  END;
$$ LANGUAGE plpgsql;



--
-- ORE equality using the `eql_v1.ore_64_8_v1(eql_v1_encrypted)` function calls
--
-- Example ORE values are generated from an array in the form `vec![0, 1, 2, 3, 4, 5]`;
--
-- JSON values are JSON escaped on top of a PostgreSQL escaped Record
--
-- PostgreSQL value is ("{""(\\""\\\\\\\\x000102030405\\"")""}")
--
--
DO $$
DECLARE
    e eql_v1_encrypted;
    ore_term jsonb;
  BEGIN

      -- remove the unique index term
      e := create_encrypted_json()::jsonb-'u';

      PERFORM assert_result(
        format('eql_v1.ore_64_8_v1(eql_v1_encrypted) = eql_v1.ore_64_8_v1(eql_v1_encrypted)'),
        format('SELECT e FROM encrypted WHERE eql_v1.ore_64_8_v1(e) = eql_v1.ore_64_8_v1(%L::eql_v1_encrypted)', e));

      -- all seed values have the same ore term
      PERFORM assert_count(
        format('eql_v1.ore_64_8_v1(eql_v1_encrypted) = eql_v1.ore_64_8_v1(eql_v1_encrypted)'),
        format('SELECT e FROM encrypted WHERE eql_v1.ore_64_8_v1(e) = eql_v1.ore_64_8_v1(%L::eql_v1_encrypted)', e),
        3);


      -- new ore term
      ore_term := '{"o": ["1212121212125932e28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd8011f94b49eaa5fa5a60e1e2adccde4185a7d6c7f83088500b677f897d4ffc276016d614708488f407c01bd3ccf2be653269062cb97f8945a621d049277d19b1c248611f25d047038928d2efeb4323c402af4c19288c7b36911dc06639af5bb34367519b66c1f525bbd3828c12067c9c579aeeb4fb3ae0918125dc1dad5fd518019a5ae67894ce1a7f7bed1a591ba8edda2fdf4cd403761fd981fb1ea5eb0bf806f919350ee60cac16d0a39a491a4d79301781f95ea3870aea82e9946053537360b2fb415b18b61aed0af81d461ad6b923f10c0df79daddc4e279ff543a282bb3a37f9fa03238348b3dac51a453b04bced1f5bd318ddd829bdfe5f37abdbeda730e21441b818302f3c5c2c4d5657accfca4c53d7a80eb3db43946d38965be5f796b"]}'::jsonb;

      -- remove the unique index term and add the ore term
      e := create_encrypted_json()::jsonb-'u' || ore_term;
      -- -- PERFORM eql_v1.log('e', e::text);

      PERFORM assert_no_result(
        format('eql_v1.ore_64_8_v1(eql_v1_encrypted) = eql_v1.ore_64_8_v1(eql_v1_encrypted)'),
        format('SELECT e FROM encrypted WHERE eql_v1.ore_64_8_v1(e) = eql_v1.ore_64_8_v1(%L::eql_v1_encrypted)', e));

  END;
$$ LANGUAGE plpgsql;



--
-- ORE equality using the `eql_v1.eq(eql_v1_encrypted, eql_v1_encrypted)'
--
-- Example ORE values are generated from an array in the form `vec![0, 1, 2, 3, 4, 5]`;
--
-- JSON values are JSON escaped on top of a PostgreSQL escaped Record
--
-- PostgreSQL value is ("{""(\\""\\\\\\\\x000102030405\\"")""}")
--
--
DO $$
DECLARE
    e eql_v1_encrypted;
    ore_term jsonb;
  BEGIN

      -- remove the unique index term
      e := create_encrypted_json()::jsonb-'u';

      PERFORM assert_result(
        'eql_v1.eq(eql_v1_encrypted, eql_v1_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v1.eq(e, %L);', e));

      -- all seed values have the same ore term
      PERFORM assert_count(
        'eql_v1.eq(eql_v1_encrypted, eql_v1_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v1.eq(e, %L);', e),
        3);


      -- new ore term
      ore_term := '{"o": ["1212121212125932e28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd8011f94b49eaa5fa5a60e1e2adccde4185a7d6c7f83088500b677f897d4ffc276016d614708488f407c01bd3ccf2be653269062cb97f8945a621d049277d19b1c248611f25d047038928d2efeb4323c402af4c19288c7b36911dc06639af5bb34367519b66c1f525bbd3828c12067c9c579aeeb4fb3ae0918125dc1dad5fd518019a5ae67894ce1a7f7bed1a591ba8edda2fdf4cd403761fd981fb1ea5eb0bf806f919350ee60cac16d0a39a491a4d79301781f95ea3870aea82e9946053537360b2fb415b18b61aed0af81d461ad6b923f10c0df79daddc4e279ff543a282bb3a37f9fa03238348b3dac51a453b04bced1f5bd318ddd829bdfe5f37abdbeda730e21441b818302f3c5c2c4d5657accfca4c53d7a80eb3db43946d38965be5f796b"]}'::jsonb;

      -- remove the unique index term and add the ore term
      e := create_encrypted_json()::jsonb-'u' || ore_term;

      PERFORM assert_no_result(
        'eql_v1.eq(eql_v1_encrypted, eql_v1_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v1.eq(e, %L);', e));
  END;
$$ LANGUAGE plpgsql;



SELECT drop_table_with_encrypted();