\set ON_ERROR_STOP on

DROP TABLE IF EXISTS encrypted;
CREATE TABLE encrypted
(
    id bigint,
    encrypted_int2 cs_encrypted_v1,
    PRIMARY KEY(id)
);

INSERT INTO encrypted (id, encrypted_int2) VALUES (99, '{"c": "99", "i": {"table": "encrypted", "column": "encrypted_int2"}, "k": "ct", "u": "unique-99", "o": ["121212121212594be28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd80132248f0640e89761a123fad8155748d764f347a29e059758575a770618ab6f82d06bad973c3fb62505d9749f4f8483c8d607c61bae7c75ef09add6d91b728449726534e65379f7b3442d2a4aa2b8c3cdb90311b53dc333bbf6b213949a8990b4300473985f60c09c6a91ac963c802e319c28bafc2be66eceb3f1924081724e44d173de2091251d1ea69ec827b94ea5ab63436f0701dd2bf299e1a66a22c4b44b32b88620949736e088bc3ec6e7974426e4b392ecece0e88a7acaf510322d1726da6bc9580dad3c8717619051c220d8654a35eb7fa0a6de4be0456522054f124bbb0bdda4bc177b35a6ca20bd996f3a3499ffd00c93d4705cc4bc05f428541c3adcc36f0b9b9aebc61a88cd4bad8f034dd4a483de9bd3291e4bee06449083c83e"], "v": 1}');
INSERT INTO encrypted (id, encrypted_int2) VALUES (1, '{"c": "1", "i": {"table": "encrypted", "column": "encrypted_int2"}, "k": "ct", "u": "unique-1", "o": ["121212121212597ee28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801f6e268e7ba5a049613d57b000f03353a911cce15580808b5a5437e7fe5f4a303847b14979a77af448fac6f39255ec13a949c2378520af48d8e5562957fb84d5f0be62ff2cc4cb4c6de243df329c676af2a0581eb40cd20b63910213afab3fdd6dfe5dc727e051e917428f5d4bca5ccda5bda99f911abffd9e3fec8019c15dad79c485192eabfb16a91af1fa88cf196123c2a6ca46069bb468281b00294bb55e2a6adae2e6549d781d6beb4b5ae35b00eef0701678c1769551eff36ed1060571707244172d212d3e5f457333003f9f4c34e42e2fe7d1cd3367a701500fe0050cbda5d59363dd5a633fb2e067ccbc1db5c33ad25c1e96a62e774ee5672247b5856f48d88ad186e58492e891f32967139ec6fab5290f0f7d0fd6b9538b0669d1597"], "v": 1}');



-- UNIQUE eq = OPERATORS
DO $$
  BEGIN


    -- SANITY CHECK
    ASSERT (SELECT EXISTS (SELECT id FROM encrypted WHERE cs_unique_v1(encrypted_int2) = cs_unique_v1('{"u":"unique-99"}')));

    ASSERT (SELECT EXISTS (
      SELECT id FROM encrypted WHERE encrypted_int2 = '{
          "v": 1,
          "k": "ct",
          "c": "ciphertext",
          "i": {
            "t": "users",
            "c": "name"
          },
          "u": "unique-1"
      }'::jsonb
    ));

    -- cs_encrypted_v1 = jsonb
    ASSERT (SELECT EXISTS (
      SELECT id FROM encrypted WHERE encrypted_int2 = '{"u": "unique-1"}'::jsonb
    ));

    -- jsonb = cs_encrypted_v1
    ASSERT (SELECT EXISTS (
      SELECT id FROM encrypted WHERE  '{"u": "unique-99"}'::jsonb = encrypted_int2
    ));

    -- cs_encrypted_v1 = text
    ASSERT (SELECT EXISTS (SELECT id FROM encrypted WHERE encrypted_int2 = 'unique-1'::text));
    ASSERT (SELECT EXISTS (SELECT id FROM encrypted WHERE encrypted_int2 = 'unique-99'::cs_unique_index_v1));

    -- text = cs_encrypted_v1
    ASSERT (SELECT EXISTS (SELECT id FROM encrypted WHERE 'unique-1'::text = encrypted_int2));

    -- cs_encrypted_v1 = cs_encrypted_v1
    ASSERT (SELECT EXISTS (SELECT id FROM encrypted WHERE encrypted_int2 = '{
            "v": 1,
            "k": "ct",
            "c": "ciphertext",
            "i": {
            "t": "users",
            "c": "name"
            },
            "u": "unique-99"
        }'::cs_encrypted_v1));

  END;
$$ LANGUAGE plpgsql;


-- UNIQUE inequality <> OPERATORS
DO $$
  BEGIN
    -- SANITY CHECK
    ASSERT (SELECT EXISTS (SELECT id FROM encrypted WHERE cs_unique_v1(encrypted_int2) != cs_unique_v1('{"u":"random-text"}')));
    ASSERT (SELECT EXISTS (SELECT id FROM encrypted WHERE cs_unique_v1(encrypted_int2) <> cs_unique_v1('{"u":"random-text"}')));

    -- cs_encrypted_v1 = jsonb
    ASSERT (SELECT EXISTS (SELECT id FROM encrypted WHERE encrypted_int2 != '{"u":"random-text"}'::jsonb));
    ASSERT (SELECT EXISTS (SELECT id FROM encrypted WHERE encrypted_int2 <> '{"u":"random-text"}'::jsonb));

    -- cs_encrypted_v1 = text
    ASSERT (SELECT EXISTS (SELECT id FROM encrypted WHERE encrypted_int2 != 'random-text'::text));
    ASSERT (SELECT EXISTS (SELECT id FROM encrypted WHERE encrypted_int2 <> 'random-text'::text));

    -- cs_encrypted_v1 = cs_encrypted_v1
    ASSERT (SELECT EXISTS (SELECT id FROM encrypted WHERE encrypted_int2 != '{
            "v": 1,
            "k": "ct",
            "c": "ciphertext",
            "i": {
            "t": "users",
            "c": "name"
            },
            "u": "random-text"
        }'::cs_encrypted_v1));

    ASSERT (SELECT EXISTS (SELECT id FROM encrypted WHERE encrypted_int2 <> '{
            "v": 1,
            "k": "ct",
            "c": "ciphertext",
            "i": {
            "t": "users",
            "c": "name"
            },
            "u": "random-text"
        }'::cs_encrypted_v1));


  END;
$$ LANGUAGE plpgsql;



-- ORE eq = OPERATORS
DO $$
  DECLARE
    ore_cs_encrypted_99 cs_encrypted_v1;
    ore_cs_encrypted_1 cs_encrypted_v1;
    ore_json_1 jsonb;
  BEGIN
    ore_cs_encrypted_99 := '{"c": "mBbLe860@9!clJM`8VX}ip6ro6vMw{Dq=G8?vJ-CE`5o0g0Pv0hQuJcV39Iw$K9)4TCQzV|J#$hgIUyEYJyfuHY>a*_OoEFWo~0~d2n=PWM64+bTYs", "i": {"table": "encrypted", "column": "encrypted_int2"}, "k": "ct", "u": "unique-99", "o": ["121212121212594be28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd80132248f0640e89761a123fad8155748d764f347a29e059758575a770618ab6f82d06bad973c3fb62505d9749f4f8483c8d607c61bae7c75ef09add6d91b728449726534e65379f7b3442d2a4aa2b8c3cdb90311b53dc333bbf6b213949a8990b4300473985f60c09c6a91ac963c802e319c28bafc2be66eceb3f1924081724e44d173de2091251d1ea69ec827b94ea5ab63436f0701dd2bf299e1a66a22c4b44b32b88620949736e088bc3ec6e7974426e4b392ecece0e88a7acaf510322d1726da6bc9580dad3c8717619051c220d8654a35eb7fa0a6de4be0456522054f124bbb0bdda4bc177b35a6ca20bd996f3a3499ffd00c93d4705cc4bc05f428541c3adcc36f0b9b9aebc61a88cd4bad8f034dd4a483de9bd3291e4bee06449083c83e"], "u": "c787c0331d81d7609e828bab7b973ba88c95de0539d1a1d378b4d5cc73c3b875", "v": 1}';

    ore_cs_encrypted_1 := '{"c": "1", "i": {"table": "encrypted", "column": "encrypted_int2"}, "k": "ct", "u": "unique-1", "o": ["121212121212597ee28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801f6e268e7ba5a049613d57b000f03353a911cce15580808b5a5437e7fe5f4a303847b14979a77af448fac6f39255ec13a949c2378520af48d8e5562957fb84d5f0be62ff2cc4cb4c6de243df329c676af2a0581eb40cd20b63910213afab3fdd6dfe5dc727e051e917428f5d4bca5ccda5bda99f911abffd9e3fec8019c15dad79c485192eabfb16a91af1fa88cf196123c2a6ca46069bb468281b00294bb55e2a6adae2e6549d781d6beb4b5ae35b00eef0701678c1769551eff36ed1060571707244172d212d3e5f457333003f9f4c34e42e2fe7d1cd3367a701500fe0050cbda5d59363dd5a633fb2e067ccbc1db5c33ad25c1e96a62e774ee5672247b5856f48d88ad186e58492e891f32967139ec6fab5290f0f7d0fd6b9538b0669d1597"], "u": "fd80b0e733ed4ff9fe71434b9474ae434863eb01ceff77d73736ac6600334de3", "v": 1}';

    ore_json_1 := '{"o": ["121212121212597ee28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801f6e268e7ba5a049613d57b000f03353a911cce15580808b5a5437e7fe5f4a303847b14979a77af448fac6f39255ec13a949c2378520af48d8e5562957fb84d5f0be62ff2cc4cb4c6de243df329c676af2a0581eb40cd20b63910213afab3fdd6dfe5dc727e051e917428f5d4bca5ccda5bda99f911abffd9e3fec8019c15dad79c485192eabfb16a91af1fa88cf196123c2a6ca46069bb468281b00294bb55e2a6adae2e6549d781d6beb4b5ae35b00eef0701678c1769551eff36ed1060571707244172d212d3e5f457333003f9f4c34e42e2fe7d1cd3367a701500fe0050cbda5d59363dd5a633fb2e067ccbc1db5c33ad25c1e96a62e774ee5672247b5856f48d88ad186e58492e891f32967139ec6fab5290f0f7d0fd6b9538b0669d1597"]}';


    -- SANITY CHECK
    ASSERT (SELECT EXISTS (SELECT id FROM encrypted WHERE cs_ore_64_8_v1(encrypted_int2) = cs_ore_64_8_v1(ore_json_1)));

    ASSERT (SELECT EXISTS (
      SELECT id FROM encrypted WHERE encrypted_int2 = ore_cs_encrypted_99::jsonb
    ));

    -- -- cs_encrypted_v1 = jsonb
    ASSERT (SELECT EXISTS (
      SELECT id FROM encrypted WHERE encrypted_int2 = ore_json_1::jsonb
    ));

    -- -- jsonb = cs_encrypted_v1
    ASSERT (SELECT EXISTS (
      SELECT id FROM encrypted WHERE ore_json_1::jsonb = encrypted_int2
    ));

    -- -- -- cs_encrypted_v1 = cs_encrypted_v1
    ASSERT (SELECT EXISTS (SELECT id FROM encrypted WHERE encrypted_int2 = ore_cs_encrypted_1::cs_encrypted_v1));

  END;
$$ LANGUAGE plpgsql;



-- ORE eq <> OPERATORS
DO $$
  DECLARE
    ore_cs_encrypted_99 cs_encrypted_v1;
    ore_cs_encrypted_1 cs_encrypted_v1;
    ore_json_1 jsonb;
  BEGIN
    ore_cs_encrypted_99 := '{"c": "mBbLe860@9!clJM`8VX}ip6ro6vMw{Dq=G8?vJ-CE`5o0g0Pv0hQuJcV39Iw$K9)4TCQzV|J#$hgIUyEYJyfuHY>a*_OoEFWo~0~d2n=PWM64+bTYs", "i": {"table": "encrypted", "column": "encrypted_int2"}, "k": "ct", "u": "unique-99", "o": ["121212121212594be28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd80132248f0640e89761a123fad8155748d764f347a29e059758575a770618ab6f82d06bad973c3fb62505d9749f4f8483c8d607c61bae7c75ef09add6d91b728449726534e65379f7b3442d2a4aa2b8c3cdb90311b53dc333bbf6b213949a8990b4300473985f60c09c6a91ac963c802e319c28bafc2be66eceb3f1924081724e44d173de2091251d1ea69ec827b94ea5ab63436f0701dd2bf299e1a66a22c4b44b32b88620949736e088bc3ec6e7974426e4b392ecece0e88a7acaf510322d1726da6bc9580dad3c8717619051c220d8654a35eb7fa0a6de4be0456522054f124bbb0bdda4bc177b35a6ca20bd996f3a3499ffd00c93d4705cc4bc05f428541c3adcc36f0b9b9aebc61a88cd4bad8f034dd4a483de9bd3291e4bee06449083c83e"], "u": "c787c0331d81d7609e828bab7b973ba88c95de0539d1a1d378b4d5cc73c3b875", "v": 1}';

    ore_cs_encrypted_1 := '{"c": "1", "i": {"table": "encrypted", "column": "encrypted_int2"}, "k": "ct", "u": "unique-1", "o": ["121212121212597ee28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801f6e268e7ba5a049613d57b000f03353a911cce15580808b5a5437e7fe5f4a303847b14979a77af448fac6f39255ec13a949c2378520af48d8e5562957fb84d5f0be62ff2cc4cb4c6de243df329c676af2a0581eb40cd20b63910213afab3fdd6dfe5dc727e051e917428f5d4bca5ccda5bda99f911abffd9e3fec8019c15dad79c485192eabfb16a91af1fa88cf196123c2a6ca46069bb468281b00294bb55e2a6adae2e6549d781d6beb4b5ae35b00eef0701678c1769551eff36ed1060571707244172d212d3e5f457333003f9f4c34e42e2fe7d1cd3367a701500fe0050cbda5d59363dd5a633fb2e067ccbc1db5c33ad25c1e96a62e774ee5672247b5856f48d88ad186e58492e891f32967139ec6fab5290f0f7d0fd6b9538b0669d1597"], "u": "fd80b0e733ed4ff9fe71434b9474ae434863eb01ceff77d73736ac6600334de3", "v": 1}';

    ore_json_1 := '{"o": ["121212121212597ee28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801f6e268e7ba5a049613d57b000f03353a911cce15580808b5a5437e7fe5f4a303847b14979a77af448fac6f39255ec13a949c2378520af48d8e5562957fb84d5f0be62ff2cc4cb4c6de243df329c676af2a0581eb40cd20b63910213afab3fdd6dfe5dc727e051e917428f5d4bca5ccda5bda99f911abffd9e3fec8019c15dad79c485192eabfb16a91af1fa88cf196123c2a6ca46069bb468281b00294bb55e2a6adae2e6549d781d6beb4b5ae35b00eef0701678c1769551eff36ed1060571707244172d212d3e5f457333003f9f4c34e42e2fe7d1cd3367a701500fe0050cbda5d59363dd5a633fb2e067ccbc1db5c33ad25c1e96a62e774ee5672247b5856f48d88ad186e58492e891f32967139ec6fab5290f0f7d0fd6b9538b0669d1597"]}';


    -- SANITY CHECK
    ASSERT (SELECT EXISTS (SELECT id FROM encrypted WHERE cs_ore_64_8_v1(encrypted_int2) <> cs_ore_64_8_v1(ore_json_1)));

    ASSERT (SELECT EXISTS (
      SELECT id FROM encrypted WHERE encrypted_int2 <> ore_cs_encrypted_99::jsonb
    ));

    -- -- cs_encrypted_v1 = jsonb
    ASSERT (SELECT EXISTS (
      SELECT id FROM encrypted WHERE encrypted_int2 <> ore_json_1::jsonb
    ));

    -- -- jsonb = cs_encrypted_v1
    ASSERT (SELECT EXISTS (
      SELECT id FROM encrypted WHERE ore_json_1::jsonb <> encrypted_int2
    ));

    -- -- -- cs_encrypted_v1 = cs_encrypted_v1
    ASSERT (SELECT EXISTS (SELECT id FROM encrypted WHERE encrypted_int2 <> ore_cs_encrypted_1::cs_encrypted_v1));

  END;
$$ LANGUAGE plpgsql;
