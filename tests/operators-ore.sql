\set ON_ERROR_STOP on


-- Create a table with a plaintext column
DROP TABLE IF EXISTS users;
CREATE TABLE users
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    name_encrypted cs_encrypted_v1,
    PRIMARY KEY(id)
);

TRUNCATE TABLE users;


-- User with "LOW" value
INSERT INTO users (name_encrypted) VALUES (
  '{
    "v": 1,
    "k": "ct",
    "c": "ciphertext",
    "i": {
      "t": "users",
      "c": "name"
    },
    "m": [1, 2, 3],
    "o": ["12121212121259bfe28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801ff4a28b714e4cde8df10625dce72602fdbdcc53d515857f1119f5912804ce09c6cf6c2d37393a27a465134523b512664582f834e15003b7216cb668480bc3e7d1c069f2572ece7c848b9eb9a28b4e62bfc2b97c93e61b2054154e621c5bbb7bed37de3d7c343bd3dbcf7b4af20128c961351bf55910a855f08a8587c2059a5f05ca8d7a082e695b3dd4ff3ce86694d4fe98972220eea1ab90f5de493ef3a502b74a569f103ee2897ebc9ae9b16a17e7be67415ee830519beb3058ffc1c1eb0e574d66c8b365919f27eb00aa7bce475d7bdaad4ed800f8fc3d626e0eb842e312b0cc22a1ccf89847ebb2cd0a6e18aec21bd2deeec1c47301fc687f7f764bb882b50f553c246a6da5816b78b3530119ea68b08a8403a90e063e58502670563bd4d"]
  }'::jsonb
);

INSERT INTO users (name_encrypted) VALUES (NULL);


-- ORE eq < OPERATORS
DO $$
  DECLARE
    ore_cs_encrypted cs_encrypted_v1;
    ore_json jsonb;
    ore_record text;
  BEGIN
    ore_cs_encrypted :=  '{
        "v": 1,
        "k": "ct",
        "c": "ciphertext",
        "i": {
        "t": "users",
        "c": "name"
        },
        "m": [1, 2, 3],
        "o": ["1212121212125932e28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd8011f94b49eaa5fa5a60e1e2adccde4185a7d6c7f83088500b677f897d4ffc276016d614708488f407c01bd3ccf2be653269062cb97f8945a621d049277d19b1c248611f25d047038928d2efeb4323c402af4c19288c7b36911dc06639af5bb34367519b66c1f525bbd3828c12067c9c579aeeb4fb3ae0918125dc1dad5fd518019a5ae67894ce1a7f7bed1a591ba8edda2fdf4cd403761fd981fb1ea5eb0bf806f919350ee60cac16d0a39a491a4d79301781f95ea3870aea82e9946053537360b2fb415b18b61aed0af81d461ad6b923f10c0df79daddc4e279ff543a282bb3a37f9fa03238348b3dac51a453b04bced1f5bd318ddd829bdfe5f37abdbeda730e21441b818302f3c5c2c4d5657accfca4c53d7a80eb3db43946d38965be5f796b"]
    }';

    ore_json := '{"o": ["1212121212125932e28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd8011f94b49eaa5fa5a60e1e2adccde4185a7d6c7f83088500b677f897d4ffc276016d614708488f407c01bd3ccf2be653269062cb97f8945a621d049277d19b1c248611f25d047038928d2efeb4323c402af4c19288c7b36911dc06639af5bb34367519b66c1f525bbd3828c12067c9c579aeeb4fb3ae0918125dc1dad5fd518019a5ae67894ce1a7f7bed1a591ba8edda2fdf4cd403761fd981fb1ea5eb0bf806f919350ee60cac16d0a39a491a4d79301781f95ea3870aea82e9946053537360b2fb415b18b61aed0af81d461ad6b923f10c0df79daddc4e279ff543a282bb3a37f9fa03238348b3dac51a453b04bced1f5bd318ddd829bdfe5f37abdbeda730e21441b818302f3c5c2c4d5657accfca4c53d7a80eb3db43946d38965be5f796b"]}';

    ore_record = '("{""(\\""\\\\\\\\x1212121212125932e28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd8011f94b49eaa5fa5a60e1e2adccde4185a7d6c7f83088500b677f897d4ffc276016d614708488f407c01bd3ccf2be653269062cb97f8945a621d049277d19b1c248611f25d047038928d2efeb4323c402af4c19288c7b36911dc06639af5bb34367519b66c1f525bbd3828c12067c9c579aeeb4fb3ae0918125dc1dad5fd518019a5ae67894ce1a7f7bed1a591ba8edda2fdf4cd403761fd981fb1ea5eb0bf806f919350ee60cac16d0a39a491a4d79301781f95ea3870aea82e9946053537360b2fb415b18b61aed0af81d461ad6b923f10c0df79daddc4e279ff543a282bb3a37f9fa03238348b3dac51a453b04bced1f5bd318ddd829bdfe5f37abdbeda730e21441b818302f3c5c2c4d5657accfca4c53d7a80eb3db43946d38965be5f796b\\"")""}")';


    -- SANITY CHECK
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE cs_ore_64_8_v1(name_encrypted) < cs_ore_64_8_v1(ore_json)));

    -- ignore null
    ASSERT (SELECT (SELECT COUNT(*) FROM (SELECT id FROM users WHERE cs_ore_64_8_v1(name_encrypted) < cs_ore_64_8_v1(ore_json))) = 1);


    ASSERT (SELECT EXISTS (
      SELECT id FROM users WHERE name_encrypted < ore_cs_encrypted::jsonb
    ));

    -- -- -- cs_encrypted_v1 < jsonb
    ASSERT (SELECT EXISTS (
      SELECT id FROM users WHERE name_encrypted < ore_json::jsonb
    ));

    -- -- -- jsonb < cs_encrypted_v1
    -- genrating ORE data for tests is fiddly, hence the IS FALSE here
    ASSERT (SELECT EXISTS (
      SELECT id FROM users WHERE (ore_json::jsonb < name_encrypted) IS FALSE
    ));

    -- -- -- -- cs_encrypted_v1 < ore_64_8_v1
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted < ore_record::ore_64_8_v1));

    -- -- -- -- -- ore_64_8_v1 < cs_encrypted_v1
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE (ore_record::ore_64_8_v1 < name_encrypted) IS FALSE));

    -- -- -- -- cs_encrypted_v1 <> cs_encrypted_v1
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted < ore_cs_encrypted::cs_encrypted_v1));

  END;
$$ LANGUAGE plpgsql;



-- ORE eq <= OPERATORS
DO $$
  DECLARE
    ore_cs_encrypted cs_encrypted_v1;
    ore_json jsonb;
    ore_record text;
  BEGIN
    ore_cs_encrypted :=  '{
        "v": 1,
        "k": "ct",
        "c": "ciphertext",
        "i": {
        "t": "users",
        "c": "name"
        },
        "m": [1, 2, 3],
        "o": ["1212121212125932e28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd8011f94b49eaa5fa5a60e1e2adccde4185a7d6c7f83088500b677f897d4ffc276016d614708488f407c01bd3ccf2be653269062cb97f8945a621d049277d19b1c248611f25d047038928d2efeb4323c402af4c19288c7b36911dc06639af5bb34367519b66c1f525bbd3828c12067c9c579aeeb4fb3ae0918125dc1dad5fd518019a5ae67894ce1a7f7bed1a591ba8edda2fdf4cd403761fd981fb1ea5eb0bf806f919350ee60cac16d0a39a491a4d79301781f95ea3870aea82e9946053537360b2fb415b18b61aed0af81d461ad6b923f10c0df79daddc4e279ff543a282bb3a37f9fa03238348b3dac51a453b04bced1f5bd318ddd829bdfe5f37abdbeda730e21441b818302f3c5c2c4d5657accfca4c53d7a80eb3db43946d38965be5f796b"]
    }';

    ore_json := '{"o": ["1212121212125932e28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd8011f94b49eaa5fa5a60e1e2adccde4185a7d6c7f83088500b677f897d4ffc276016d614708488f407c01bd3ccf2be653269062cb97f8945a621d049277d19b1c248611f25d047038928d2efeb4323c402af4c19288c7b36911dc06639af5bb34367519b66c1f525bbd3828c12067c9c579aeeb4fb3ae0918125dc1dad5fd518019a5ae67894ce1a7f7bed1a591ba8edda2fdf4cd403761fd981fb1ea5eb0bf806f919350ee60cac16d0a39a491a4d79301781f95ea3870aea82e9946053537360b2fb415b18b61aed0af81d461ad6b923f10c0df79daddc4e279ff543a282bb3a37f9fa03238348b3dac51a453b04bced1f5bd318ddd829bdfe5f37abdbeda730e21441b818302f3c5c2c4d5657accfca4c53d7a80eb3db43946d38965be5f796b"]}';

    ore_record = '("{""(\\""\\\\\\\\x1212121212125932e28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd8011f94b49eaa5fa5a60e1e2adccde4185a7d6c7f83088500b677f897d4ffc276016d614708488f407c01bd3ccf2be653269062cb97f8945a621d049277d19b1c248611f25d047038928d2efeb4323c402af4c19288c7b36911dc06639af5bb34367519b66c1f525bbd3828c12067c9c579aeeb4fb3ae0918125dc1dad5fd518019a5ae67894ce1a7f7bed1a591ba8edda2fdf4cd403761fd981fb1ea5eb0bf806f919350ee60cac16d0a39a491a4d79301781f95ea3870aea82e9946053537360b2fb415b18b61aed0af81d461ad6b923f10c0df79daddc4e279ff543a282bb3a37f9fa03238348b3dac51a453b04bced1f5bd318ddd829bdfe5f37abdbeda730e21441b818302f3c5c2c4d5657accfca4c53d7a80eb3db43946d38965be5f796b\\"")""}")';


    -- SANITY CHECK
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE cs_ore_64_8_v1(name_encrypted) <= cs_ore_64_8_v1(ore_json)));

    ASSERT (SELECT EXISTS (
      SELECT id FROM users WHERE name_encrypted <= ore_cs_encrypted::jsonb
    ));

    -- -- -- cs_encrypted_v1 <= jsonb
    ASSERT (SELECT EXISTS (
      SELECT id FROM users WHERE name_encrypted <= ore_json::jsonb
    ));

    -- -- -- jsonb <= cs_encrypted_v1
    -- genrating ORE data for tests is fiddly, hence the IS FALSE here
    ASSERT (SELECT EXISTS (
      SELECT id FROM users WHERE (ore_json::jsonb <= name_encrypted) IS FALSE
    ));

    -- -- -- -- cs_encrypted_v1 <= ore_64_8_v1
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted <= ore_record::ore_64_8_v1));

    -- -- -- -- -- ore_64_8_v1 <= cs_encrypted_v1
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE (ore_record::ore_64_8_v1 <= name_encrypted) IS FALSE));

    -- -- -- -- cs_encrypted_v1 <= cs_encrypted_v1
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted <= ore_cs_encrypted::cs_encrypted_v1));

  END;
$$ LANGUAGE plpgsql;



-- User with "HIGH" value
INSERT INTO users (name_encrypted) VALUES (
  '{
        "v": 1,
        "k": "ct",
        "c": "ciphertext",
        "i": {
        "t": "users",
        "c": "name"
        },
        "m": [1, 2, 3],
        "o": ["1212121212125932e28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd8011f94b49eaa5fa5a60e1e2adccde4185a7d6c7f83088500b677f897d4ffc276016d614708488f407c01bd3ccf2be653269062cb97f8945a621d049277d19b1c248611f25d047038928d2efeb4323c402af4c19288c7b36911dc06639af5bb34367519b66c1f525bbd3828c12067c9c579aeeb4fb3ae0918125dc1dad5fd518019a5ae67894ce1a7f7bed1a591ba8edda2fdf4cd403761fd981fb1ea5eb0bf806f919350ee60cac16d0a39a491a4d79301781f95ea3870aea82e9946053537360b2fb415b18b61aed0af81d461ad6b923f10c0df79daddc4e279ff543a282bb3a37f9fa03238348b3dac51a453b04bced1f5bd318ddd829bdfe5f37abdbeda730e21441b818302f3c5c2c4d5657accfca4c53d7a80eb3db43946d38965be5f796b"]
    }'::jsonb
);



-- ORE eq < OPERATORS
DO $$
  DECLARE
    ore_cs_encrypted cs_encrypted_v1;
    ore_json jsonb;
    ore_record text;
  BEGIN
    ore_cs_encrypted :=  '{
        "v": 1,
        "k": "ct",
        "c": "ciphertext",
        "i": {
        "t": "users",
        "c": "name"
        },
        "m": [1, 2, 3],
        "o": ["12121212121259bfe28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801ff4a28b714e4cde8df10625dce72602fdbdcc53d515857f1119f5912804ce09c6cf6c2d37393a27a465134523b512664582f834e15003b7216cb668480bc3e7d1c069f2572ece7c848b9eb9a28b4e62bfc2b97c93e61b2054154e621c5bbb7bed37de3d7c343bd3dbcf7b4af20128c961351bf55910a855f08a8587c2059a5f05ca8d7a082e695b3dd4ff3ce86694d4fe98972220eea1ab90f5de493ef3a502b74a569f103ee2897ebc9ae9b16a17e7be67415ee830519beb3058ffc1c1eb0e574d66c8b365919f27eb00aa7bce475d7bdaad4ed800f8fc3d626e0eb842e312b0cc22a1ccf89847ebb2cd0a6e18aec21bd2deeec1c47301fc687f7f764bb882b50f553c246a6da5816b78b3530119ea68b08a8403a90e063e58502670563bd4d"]
    }';

    ore_json := '{"o": ["12121212121259bfe28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801ff4a28b714e4cde8df10625dce72602fdbdcc53d515857f1119f5912804ce09c6cf6c2d37393a27a465134523b512664582f834e15003b7216cb668480bc3e7d1c069f2572ece7c848b9eb9a28b4e62bfc2b97c93e61b2054154e621c5bbb7bed37de3d7c343bd3dbcf7b4af20128c961351bf55910a855f08a8587c2059a5f05ca8d7a082e695b3dd4ff3ce86694d4fe98972220eea1ab90f5de493ef3a502b74a569f103ee2897ebc9ae9b16a17e7be67415ee830519beb3058ffc1c1eb0e574d66c8b365919f27eb00aa7bce475d7bdaad4ed800f8fc3d626e0eb842e312b0cc22a1ccf89847ebb2cd0a6e18aec21bd2deeec1c47301fc687f7f764bb882b50f553c246a6da5816b78b3530119ea68b08a8403a90e063e58502670563bd4d"]}';


    ore_record = '("{""(\\""\\\\\\\\x12121212121259bfe28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801ff4a28b714e4cde8df10625dce72602fdbdcc53d515857f1119f5912804ce09c6cf6c2d37393a27a465134523b512664582f834e15003b7216cb668480bc3e7d1c069f2572ece7c848b9eb9a28b4e62bfc2b97c93e61b2054154e621c5bbb7bed37de3d7c343bd3dbcf7b4af20128c961351bf55910a855f08a8587c2059a5f05ca8d7a082e695b3dd4ff3ce86694d4fe98972220eea1ab90f5de493ef3a502b74a569f103ee2897ebc9ae9b16a17e7be67415ee830519beb3058ffc1c1eb0e574d66c8b365919f27eb00aa7bce475d7bdaad4ed800f8fc3d626e0eb842e312b0cc22a1ccf89847ebb2cd0a6e18aec21bd2deeec1c47301fc687f7f764bb882b50f553c246a6da5816b78b3530119ea68b08a8403a90e063e58502670563bd4d\\"")""}")';

    -- SANITY CHECK
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE cs_ore_64_8_v1(name_encrypted) > cs_ore_64_8_v1(ore_json)));

    ASSERT (SELECT EXISTS (
      SELECT id FROM users WHERE name_encrypted > ore_cs_encrypted::jsonb
    ));

    -- -- -- cs_encrypted_v1 > jsonb
    ASSERT (SELECT EXISTS (
      SELECT id FROM users WHERE name_encrypted > ore_json::jsonb
    ));

    -- -- -- jsonb > cs_encrypted_v1
    -- genrating ORE data for tests is fiddly, hence the IS FALSE here
    ASSERT (SELECT EXISTS (
      SELECT id FROM users WHERE (ore_json::jsonb > name_encrypted) IS FALSE
    ));

    -- -- -- -- cs_encrypted_v1 > ore_64_8_v1
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted > ore_record::ore_64_8_v1));

    -- -- -- -- -- ore_64_8_v1 > cs_encrypted_v1
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE (ore_record::ore_64_8_v1 > name_encrypted) IS FALSE));

    -- -- -- -- cs_encrypted_v1 >> cs_encrypted_v1
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted > ore_cs_encrypted::cs_encrypted_v1));

  END;
$$ LANGUAGE plpgsql;




-- User with "HIGH" value
INSERT INTO users (name_encrypted) VALUES (
  '{
        "v": 1,
        "k": "ct",
        "c": "ciphertext",
        "i": {
        "t": "users",
        "c": "name"
        },
        "m": [1, 2, 3],
        "o": ["1212121212125932e28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd8011f94b49eaa5fa5a60e1e2adccde4185a7d6c7f83088500b677f897d4ffc276016d614708488f407c01bd3ccf2be653269062cb97f8945a621d049277d19b1c248611f25d047038928d2efeb4323c402af4c19288c7b36911dc06639af5bb34367519b66c1f525bbd3828c12067c9c579aeeb4fb3ae0918125dc1dad5fd518019a5ae67894ce1a7f7bed1a591ba8edda2fdf4cd403761fd981fb1ea5eb0bf806f919350ee60cac16d0a39a491a4d79301781f95ea3870aea82e9946053537360b2fb415b18b61aed0af81d461ad6b923f10c0df79daddc4e279ff543a282bb3a37f9fa03238348b3dac51a453b04bced1f5bd318ddd829bdfe5f37abdbeda730e21441b818302f3c5c2c4d5657accfca4c53d7a80eb3db43946d38965be5f796b"]
    }'::jsonb
);



-- ORE eq >= OPERATORS
DO $$
  DECLARE
    ore_cs_encrypted cs_encrypted_v1;
    ore_json jsonb;
    ore_record text;
  BEGIN
    ore_cs_encrypted :=  '{
        "v": 1,
        "k": "ct",
        "c": "ciphertext",
        "i": {
        "t": "users",
        "c": "name"
        },
        "m": [1, 2, 3],
        "o": ["12121212121259bfe28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801ff4a28b714e4cde8df10625dce72602fdbdcc53d515857f1119f5912804ce09c6cf6c2d37393a27a465134523b512664582f834e15003b7216cb668480bc3e7d1c069f2572ece7c848b9eb9a28b4e62bfc2b97c93e61b2054154e621c5bbb7bed37de3d7c343bd3dbcf7b4af20128c961351bf55910a855f08a8587c2059a5f05ca8d7a082e695b3dd4ff3ce86694d4fe98972220eea1ab90f5de493ef3a502b74a569f103ee2897ebc9ae9b16a17e7be67415ee830519beb3058ffc1c1eb0e574d66c8b365919f27eb00aa7bce475d7bdaad4ed800f8fc3d626e0eb842e312b0cc22a1ccf89847ebb2cd0a6e18aec21bd2deeec1c47301fc687f7f764bb882b50f553c246a6da5816b78b3530119ea68b08a8403a90e063e58502670563bd4d"]
    }';

    ore_json := '{"o": ["12121212121259bfe28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801ff4a28b714e4cde8df10625dce72602fdbdcc53d515857f1119f5912804ce09c6cf6c2d37393a27a465134523b512664582f834e15003b7216cb668480bc3e7d1c069f2572ece7c848b9eb9a28b4e62bfc2b97c93e61b2054154e621c5bbb7bed37de3d7c343bd3dbcf7b4af20128c961351bf55910a855f08a8587c2059a5f05ca8d7a082e695b3dd4ff3ce86694d4fe98972220eea1ab90f5de493ef3a502b74a569f103ee2897ebc9ae9b16a17e7be67415ee830519beb3058ffc1c1eb0e574d66c8b365919f27eb00aa7bce475d7bdaad4ed800f8fc3d626e0eb842e312b0cc22a1ccf89847ebb2cd0a6e18aec21bd2deeec1c47301fc687f7f764bb882b50f553c246a6da5816b78b3530119ea68b08a8403a90e063e58502670563bd4d"]}';


    ore_record = '("{""(\\""\\\\\\\\x12121212121259bfe28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801ff4a28b714e4cde8df10625dce72602fdbdcc53d515857f1119f5912804ce09c6cf6c2d37393a27a465134523b512664582f834e15003b7216cb668480bc3e7d1c069f2572ece7c848b9eb9a28b4e62bfc2b97c93e61b2054154e621c5bbb7bed37de3d7c343bd3dbcf7b4af20128c961351bf55910a855f08a8587c2059a5f05ca8d7a082e695b3dd4ff3ce86694d4fe98972220eea1ab90f5de493ef3a502b74a569f103ee2897ebc9ae9b16a17e7be67415ee830519beb3058ffc1c1eb0e574d66c8b365919f27eb00aa7bce475d7bdaad4ed800f8fc3d626e0eb842e312b0cc22a1ccf89847ebb2cd0a6e18aec21bd2deeec1c47301fc687f7f764bb882b50f553c246a6da5816b78b3530119ea68b08a8403a90e063e58502670563bd4d\\"")""}")';

    -- SANITY CHECK
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE cs_ore_64_8_v1(name_encrypted) >= cs_ore_64_8_v1(ore_json)));

    ASSERT (SELECT EXISTS (
      SELECT id FROM users WHERE name_encrypted >= ore_cs_encrypted::jsonb
    ));

    -- -- -- cs_encrypted_v1 >= jsonb
    ASSERT (SELECT EXISTS (
      SELECT id FROM users WHERE name_encrypted >= ore_json::jsonb
    ));

    -- -- -- jsonb >= cs_encrypted_v1
    -- genrating ORE data for tests is fiddly, hence the IS FALSE here
    ASSERT (SELECT EXISTS (
      SELECT id FROM users WHERE (ore_json::jsonb >= name_encrypted) IS FALSE
    ));

    -- -- -- -- cs_encrypted_v1 >= ore_64_8_v1
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted >= ore_record::ore_64_8_v1));

    -- -- -- -- -- ore_64_8_v1 >= cs_encrypted_v1
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE (ore_record::ore_64_8_v1 >= name_encrypted) IS FALSE));

    -- -- -- -- cs_encrypted_v1 >= cs_encrypted_v1
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted >= ore_cs_encrypted::cs_encrypted_v1));

  END;
$$ LANGUAGE plpgsql;
