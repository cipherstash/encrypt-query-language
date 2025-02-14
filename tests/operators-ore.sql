\set ON_ERROR_STOP on

DROP TABLE IF EXISTS encrypted;
CREATE TABLE encrypted
(
    id bigint,
    encrypted_int2 cs_encrypted_v1,
    PRIMARY KEY(id)
);

INSERT INTO encrypted (id, encrypted_int2) VALUES (99, '{"c": "mBbLe860@9!clJM`8VX}ip6ro6vMw{Dq=G8?vJ-CE`5o0g0Pv0hQuJcV39Iw$K9)4TCQzV|J#$hgIUyEYJyfuHY>a*_OoEFWo~0~d2n=PWM64+bTYs", "i": {"table": "encrypted", "column": "encrypted_int2"}, "k": "ct", "m": null, "o": ["\\x121212121212594be28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd80132248f0640e89761a123fad8155748d764f347a29e059758575a770618ab6f82d06bad973c3fb62505d9749f4f8483c8d607c61bae7c75ef09add6d91b728449726534e65379f7b3442d2a4aa2b8c3cdb90311b53dc333bbf6b213949a8990b4300473985f60c09c6a91ac963c802e319c28bafc2be66eceb3f1924081724e44d173de2091251d1ea69ec827b94ea5ab63436f0701dd2bf299e1a66a22c4b44b32b88620949736e088bc3ec6e7974426e4b392ecece0e88a7acaf510322d1726da6bc9580dad3c8717619051c220d8654a35eb7fa0a6de4be0456522054f124bbb0bdda4bc177b35a6ca20bd996f3a3499ffd00c93d4705cc4bc05f428541c3adcc36f0b9b9aebc61a88cd4bad8f034dd4a483de9bd3291e4bee06449083c83e"], "u": "c787c0331d81d7609e828bab7b973ba88c95de0539d1a1d378b4d5cc73c3b875", "v": 1}');
INSERT INTO encrypted (id, encrypted_int2) VALUES (5, '{"c": "mBbLon>=7ftt`=*S&jse$4dOf6yJvdxSqSRPpFtGPlBHkz6(wFqQoGnB5@)Ov#bUqy)1tr`#7noW<oWA)qzY#NB?Z4Ox6CbWo~0~d2n=PWM64+bTYs", "i": {"table": "encrypted", "column": "encrypted_int2"}, "k": "ct", "m": null, "o": ["\\x121212121212591fe28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801d7a2a8638edc950e921074126382a46da05655a5205c0d5196dec740f50d1fcfa8221cd9aa78fc7b6f276f0131f9a02734b0c3dba6ac1ce512718d8f31ec80caa7a1c3c852c67a5d22890bfd6e7099572fa9cd9dcafeae9c3ce4fb60a4cbe22174ff7f2a5d345215fb748524dcaad2e615e8922ae59280463d7b35821dfefe8821fbec700de11832019654aa521b043e15b242ac711f2552ee879b03f15e55bbf0e6a79e9c86f0c6067baf78ed84a7ffae447cb01157ffa9556e81fad25aaf1686f6e9a989f2c5f24d0011c3e86d7abf14ea16005bda2d59d803f5a609fa035ef072475a8cc5645490f3de2253fe4d4ebcd4825d48108f0f485c6b0f7c5ca963c9d3d4bd6e2d86163a26aff609fe2bb59b0da6ff623958179591d1ee62226a50"], "u": "cdd6248063d3431f3fe010c5728954fd62cbf42b0c515a9991bd4fc673604e26", "v": 1}');
INSERT INTO encrypted (id, encrypted_int2) VALUES (6, '{"c": "mBbL<%|8QEvyG+jp^N33V$5g66mJf4L<h<IRqs4j`Ozp3Fy^fNy~H4!{2e<%p{tS<c1C6tKaA)CAO~u@AO)pIxGa^dve6%|Wo~0~d2n=PWM64+bTYs", "i": {"table": "encrypted", "column": "encrypted_int2"}, "k": "ct", "m": null, "o": ["\\x121212121212599de28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801a6afd969a465c445ab35c15e7ef11eba3b65e765e52eb048019b0c2aec77012d71fff7b3d18b5b28e8cfce2901a2858b7aab627e07e69bb46c1503226ade5b0f8b77f21458d2cc1bcf99dd05da127be1c8cfc5323a18b6d53ba0715b5898a43cf1b05520d8957340d34ad49f778ff78afe974ba973c2460cdfd79ce9599915f4c95ec22f93231110bb3131aa7601a26589abd32f41845a977747163113a9395a82b3cee1f316bbe586b42e14130c870d6c731d0e499ecea7a1ef3f38fc7ef8ad43b52cf8dd7cf5723ddbfa1404717d0a0e63ef7be577b5a551aafcd9c28ecdef1cb2011cf468a1fff72b72264be1a6cc26d16a08e0bd0007ff0d09527f503e97c56f16e1efbf94c7318390c9e27eb92683a63ade0864376257a81d1cf9a97c73"], "u": "a97ec70e9e4cc5c6888f1f809ec4fa551aff8633d76cfb26bb20997d4d50ca91", "v": 1}');
INSERT INTO encrypted (id, encrypted_int2) VALUES (7, '{"c": "mBbJrrih3;QyPK$Y3WOwIiLr`6slZTQ>Jgfu~pkXjCBx%`R~Qw<HR6{N%EM{_%50^eW!<b@dq+q0@u_Zi<FhYEqc!dh>6gyWo~0~d2n=PWM64+bTYs", "i": {"table": "encrypted", "column": "encrypted_int2"}, "k": "ct", "m": null, "o": ["\\x1212121212125948e28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801a901168d92ea2d7df254becc59888cf41530bacb77fa8c9aabe64574c246875cebd0c3ac7c8041d791d3091ba3b7083931be986a31d3c251479a2911c634aa1028f30852e6e213380a70a1c57bafe4467cbdd131e171c1136e2f8d144c8cd7a354edb93fe4f140b2e5a7c2d7ccfb2b77328d946ce2acbd6ddbfe50b81d2e1d4c5eacc3853876ae12ec4128332ff594c01309d32451d7a71913452476f1bb5af7b280bcb5bfa98e3c1a3d0e50ce58938b3c1fad0225ec051266ea8ac597a332313d023cc8b39732768e83feaca0ebe47c64684b192893e983c7be31489e86f3c99e76131e9e73c5733c4d79091f6182f9a4bc5b26ecf1dd8faa8124be2b87cfa7a589257aa63ac67f9d5046fc3be4feafc1f187dfa8fdb249110890aacdfdd53a"], "u": "28f3ec44eae678f9d0d8238c0b3a01a146d56ccc4c1125f0373d394c4e1e95f4", "v": 1}');
INSERT INTO encrypted (id, encrypted_int2) VALUES (8, '{"c": "mBbJZ8KCF-%TLAttT!Kh)Bdx>6d*;f`!dvyxG>#+vD}RNtB2Us7sMbp(TSJniNkU`Hw$%;<lKRfLPFxW66(MELP+}EAbbn1Wo~0~d2n=PWM64+bTYs", "i": {"table": "encrypted", "column": "encrypted_int2"}, "k": "ct", "m": null, "o": ["\\x121212121212594ee28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801783caa0b75f5aa4c005b423d7518fd4ba385e489dabd945f2894e79a6109660602d6044ebff087093acc682aeadc5e303917d328f350b20396d48a115d0db162ea4dbf0b7f83acdaf576c06edf52168a8deb8e5458c5521a45d148ad5dfc8cb8f50e0943b2041918834d84daedac15d1d88e5cb3b0cbcd731c2fcad75719a5a81a6f7a423dd27c5d00fd7ad215d06e0b34969358486e8ecd089d5d4c614b56cd47e21ee0d07adf8c6a3770f21e239ca367cd97d4168054d3b8e09fdc7da862fa021aeb21929837959cc89c091fe4c7d42c4873edef63f0adad04abdcc1ac5e4c9c8622293c6c8399085f92a6f5cf037043ccac1f69b8626d0453dda0098b45aae708b99ef44edf3c41f6509e407f76756266260c40e5080fcc8719f1e2ffea46"], "u": "9e80a31275db9e5ebc9a254864971cdef2ca68b0047712d3d106d86516bcfc6a", "v": 1}');
INSERT INTO encrypted (id, encrypted_int2) VALUES (9, '{"c": "mBbL7`X^0YW??HD))ER7q9OUj6fDxOC5>-2y!lE0z+OHrVk@cwi^L!sbglQ5m2>-BW9ogbyZjyIgeGg|W?{2<EuJMgwY+PtWo~0~d2n=PWM64+bTYs", "i": {"table": "encrypted", "column": "encrypted_int2"}, "k": "ct", "m": null, "o": ["\\x12121212121259dae28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801357205e56d3cf91febac317b17108335156373777c7a0474b8bf8f3ca4a05681debfa5ca3c19c4d272209cf423f0414911cf80c4f5da0480e6865f0929c55deda9ed42f859be162e6f307552fa56ae91bb6a197222910d78847204e53df19046c99a5cd8282748a10fc73e04dd162296c3a2bf90d293c56277c2949cca4535f75ab268725c6614cdeb6f828eea6ed428acb3ec935e6793908217044ff3062d6194f79040a43d3951ed5786682672754e0cdd044a2d6f3ac0c02c9ac45917dca0ded737028f84a058799181a750d1f60e7f77ef31cf476ffa1c9ab25c5f02924814b5cb9bf3e59c2469de963e6253f4c80db37304b32c719615669fcc2b394782addf37041e1e31eafb6000ec5ec3d1ff87167eefef767ae5cee9cc593664f48c"], "u": "94ec6ec3b6a8acb4d1b94f0c3a4a7c6359b11ce5d8fd01a7e4474e5e7a0cca8b", "v": 1}');
INSERT INTO encrypted (id, encrypted_int2) VALUES (1, '{"c": "mBbK6IM@r}>@LgnyccSYi>kTA6xiNKsfTW>4X{HWg#UqTOMZ<KA;cimU3x*AeF2K-yZJOeWo2bkij#d_=Kq;1A-L)|sB%QEWo~0~d2n=PWM64+bTYs", "i": {"table": "encrypted", "column": "encrypted_int2"}, "k": "ct", "m": null, "o": ["\\x121212121212597ee28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801f6e268e7ba5a049613d57b000f03353a911cce15580808b5a5437e7fe5f4a303847b14979a77af448fac6f39255ec13a949c2378520af48d8e5562957fb84d5f0be62ff2cc4cb4c6de243df329c676af2a0581eb40cd20b63910213afab3fdd6dfe5dc727e051e917428f5d4bca5ccda5bda99f911abffd9e3fec8019c15dad79c485192eabfb16a91af1fa88cf196123c2a6ca46069bb468281b00294bb55e2a6adae2e6549d781d6beb4b5ae35b00eef0701678c1769551eff36ed1060571707244172d212d3e5f457333003f9f4c34e42e2fe7d1cd3367a701500fe0050cbda5d59363dd5a633fb2e067ccbc1db5c33ad25c1e96a62e774ee5672247b5856f48d88ad186e58492e891f32967139ec6fab5290f0f7d0fd6b9538b0669d1597"], "u": "fd80b0e733ed4ff9fe71434b9474ae434863eb01ceff77d73736ac6600334de3", "v": 1}');


-- ORE LT < AND GT > OPERATORS
DO $$
  DECLARE
    ore_cs_encrypted_high cs_encrypted_v1;
    ore_cs_encrypted_low cs_encrypted_v1;
    ore_json_high jsonb;
    ore_json_low jsonb;
    row_count integer;
  BEGIN
    ore_cs_encrypted_high := '{"c": "mBbLe860@9!clJM`8VX}ip6ro6vMw{Dq=G8?vJ-CE`5o0g0Pv0hQuJcV39Iw$K9)4TCQzV|J#$hgIUyEYJyfuHY>a*_OoEFWo~0~d2n=PWM64+bTYs", "i": {"table": "encrypted", "column": "encrypted_int2"}, "k": "ct", "m": null, "o": ["\\x121212121212594be28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd80132248f0640e89761a123fad8155748d764f347a29e059758575a770618ab6f82d06bad973c3fb62505d9749f4f8483c8d607c61bae7c75ef09add6d91b728449726534e65379f7b3442d2a4aa2b8c3cdb90311b53dc333bbf6b213949a8990b4300473985f60c09c6a91ac963c802e319c28bafc2be66eceb3f1924081724e44d173de2091251d1ea69ec827b94ea5ab63436f0701dd2bf299e1a66a22c4b44b32b88620949736e088bc3ec6e7974426e4b392ecece0e88a7acaf510322d1726da6bc9580dad3c8717619051c220d8654a35eb7fa0a6de4be0456522054f124bbb0bdda4bc177b35a6ca20bd996f3a3499ffd00c93d4705cc4bc05f428541c3adcc36f0b9b9aebc61a88cd4bad8f034dd4a483de9bd3291e4bee06449083c83e"], "u": "c787c0331d81d7609e828bab7b973ba88c95de0539d1a1d378b4d5cc73c3b875", "v": 1}';
    ore_cs_encrypted_low := '{"c": "mBbK6IM@r}>@LgnyccSYi>kTA6xiNKsfTW>4X{HWg#UqTOMZ<KA;cimU3x*AeF2K-yZJOeWo2bkij#d_=Kq;1A-L)|sB%QEWo~0~d2n=PWM64+bTYs", "i": {"table": "encrypted", "column": "encrypted_int2"}, "k": "ct", "m": null, "o": ["\\x121212121212597ee28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801f6e268e7ba5a049613d57b000f03353a911cce15580808b5a5437e7fe5f4a303847b14979a77af448fac6f39255ec13a949c2378520af48d8e5562957fb84d5f0be62ff2cc4cb4c6de243df329c676af2a0581eb40cd20b63910213afab3fdd6dfe5dc727e051e917428f5d4bca5ccda5bda99f911abffd9e3fec8019c15dad79c485192eabfb16a91af1fa88cf196123c2a6ca46069bb468281b00294bb55e2a6adae2e6549d781d6beb4b5ae35b00eef0701678c1769551eff36ed1060571707244172d212d3e5f457333003f9f4c34e42e2fe7d1cd3367a701500fe0050cbda5d59363dd5a633fb2e067ccbc1db5c33ad25c1e96a62e774ee5672247b5856f48d88ad186e58492e891f32967139ec6fab5290f0f7d0fd6b9538b0669d1597"], "u": "fd80b0e733ed4ff9fe71434b9474ae434863eb01ceff77d73736ac6600334de3", "v": 1}';

    ore_json_high := '{"o": ["\\x121212121212594be28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd80132248f0640e89761a123fad8155748d764f347a29e059758575a770618ab6f82d06bad973c3fb62505d9749f4f8483c8d607c61bae7c75ef09add6d91b728449726534e65379f7b3442d2a4aa2b8c3cdb90311b53dc333bbf6b213949a8990b4300473985f60c09c6a91ac963c802e319c28bafc2be66eceb3f1924081724e44d173de2091251d1ea69ec827b94ea5ab63436f0701dd2bf299e1a66a22c4b44b32b88620949736e088bc3ec6e7974426e4b392ecece0e88a7acaf510322d1726da6bc9580dad3c8717619051c220d8654a35eb7fa0a6de4be0456522054f124bbb0bdda4bc177b35a6ca20bd996f3a3499ffd00c93d4705cc4bc05f428541c3adcc36f0b9b9aebc61a88cd4bad8f034dd4a483de9bd3291e4bee06449083c83e"]}';
    ore_json_low := '{"o": ["\\x121212121212597ee28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801f6e268e7ba5a049613d57b000f03353a911cce15580808b5a5437e7fe5f4a303847b14979a77af448fac6f39255ec13a949c2378520af48d8e5562957fb84d5f0be62ff2cc4cb4c6de243df329c676af2a0581eb40cd20b63910213afab3fdd6dfe5dc727e051e917428f5d4bca5ccda5bda99f911abffd9e3fec8019c15dad79c485192eabfb16a91af1fa88cf196123c2a6ca46069bb468281b00294bb55e2a6adae2e6549d781d6beb4b5ae35b00eef0701678c1769551eff36ed1060571707244172d212d3e5f457333003f9f4c34e42e2fe7d1cd3367a701500fe0050cbda5d59363dd5a633fb2e067ccbc1db5c33ad25c1e96a62e774ee5672247b5856f48d88ad186e58492e891f32967139ec6fab5290f0f7d0fd6b9538b0669d1597"]}';

    -- ------------------------------------------------------------------------------------------------
    -- -- cs_encrypted_v1 < cs_encrypted_v1
    SELECT
      COUNT(id)
      FROM encrypted WHERE encrypted_int2 < ore_cs_encrypted_high
    INTO row_count;

    ASSERT row_count = 6;


    -- -- cs_encrypted_v1 < jsonb
    SELECT
      COUNT(id)
      FROM encrypted WHERE encrypted_int2 < ore_json_high
    INTO row_count;

    ASSERT row_count = 6;

    -- -- jsonb < cs_encrypted_v1
    SELECT
      COUNT(id)
      FROM encrypted WHERE ore_json_low < encrypted_int2
    INTO row_count;

    ASSERT row_count = 6;


    -- -- cs_encrypted_v1 > cs_encrypted_v1
    SELECT
      COUNT(id)
      FROM encrypted WHERE encrypted_int2 > ore_cs_encrypted_low
    INTO row_count;
    ASSERT row_count = 6;

    -- -- cs_encrypted_v1 > jsonb
    SELECT
      COUNT(id)
      FROM encrypted WHERE encrypted_int2 > ore_json_low
    INTO row_count;

    ASSERT row_count = 6;

    -- -- jsonb > cs_encrypted_v1
    SELECT
      COUNT(id)
      FROM encrypted WHERE ore_json_low > encrypted_int2
    INTO row_count;

    ASSERT row_count = 0;


  END;
$$ LANGUAGE plpgsql;


-- ORE LTE <= AND GTE >= OPERATORS
DO $$
  DECLARE
    ore_cs_encrypted_high cs_encrypted_v1;
    ore_cs_encrypted_low cs_encrypted_v1;
    ore_json_high jsonb;
    ore_json_low jsonb;
    row_count integer;
  BEGIN
    ore_cs_encrypted_high := '{"c": "mBbLe860@9!clJM`8VX}ip6ro6vMw{Dq=G8?vJ-CE`5o0g0Pv0hQuJcV39Iw$K9)4TCQzV|J#$hgIUyEYJyfuHY>a*_OoEFWo~0~d2n=PWM64+bTYs", "i": {"table": "encrypted", "column": "encrypted_int2"}, "k": "ct", "m": null, "o": ["\\x121212121212594be28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd80132248f0640e89761a123fad8155748d764f347a29e059758575a770618ab6f82d06bad973c3fb62505d9749f4f8483c8d607c61bae7c75ef09add6d91b728449726534e65379f7b3442d2a4aa2b8c3cdb90311b53dc333bbf6b213949a8990b4300473985f60c09c6a91ac963c802e319c28bafc2be66eceb3f1924081724e44d173de2091251d1ea69ec827b94ea5ab63436f0701dd2bf299e1a66a22c4b44b32b88620949736e088bc3ec6e7974426e4b392ecece0e88a7acaf510322d1726da6bc9580dad3c8717619051c220d8654a35eb7fa0a6de4be0456522054f124bbb0bdda4bc177b35a6ca20bd996f3a3499ffd00c93d4705cc4bc05f428541c3adcc36f0b9b9aebc61a88cd4bad8f034dd4a483de9bd3291e4bee06449083c83e"], "u": "c787c0331d81d7609e828bab7b973ba88c95de0539d1a1d378b4d5cc73c3b875", "v": 1}';
    ore_cs_encrypted_low := '{"c": "mBbK6IM@r}>@LgnyccSYi>kTA6xiNKsfTW>4X{HWg#UqTOMZ<KA;cimU3x*AeF2K-yZJOeWo2bkij#d_=Kq;1A-L)|sB%QEWo~0~d2n=PWM64+bTYs", "i": {"table": "encrypted", "column": "encrypted_int2"}, "k": "ct", "m": null, "o": ["\\x121212121212597ee28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801f6e268e7ba5a049613d57b000f03353a911cce15580808b5a5437e7fe5f4a303847b14979a77af448fac6f39255ec13a949c2378520af48d8e5562957fb84d5f0be62ff2cc4cb4c6de243df329c676af2a0581eb40cd20b63910213afab3fdd6dfe5dc727e051e917428f5d4bca5ccda5bda99f911abffd9e3fec8019c15dad79c485192eabfb16a91af1fa88cf196123c2a6ca46069bb468281b00294bb55e2a6adae2e6549d781d6beb4b5ae35b00eef0701678c1769551eff36ed1060571707244172d212d3e5f457333003f9f4c34e42e2fe7d1cd3367a701500fe0050cbda5d59363dd5a633fb2e067ccbc1db5c33ad25c1e96a62e774ee5672247b5856f48d88ad186e58492e891f32967139ec6fab5290f0f7d0fd6b9538b0669d1597"], "u": "fd80b0e733ed4ff9fe71434b9474ae434863eb01ceff77d73736ac6600334de3", "v": 1}';

    ore_json_high := '{"o": ["\\x121212121212594be28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd80132248f0640e89761a123fad8155748d764f347a29e059758575a770618ab6f82d06bad973c3fb62505d9749f4f8483c8d607c61bae7c75ef09add6d91b728449726534e65379f7b3442d2a4aa2b8c3cdb90311b53dc333bbf6b213949a8990b4300473985f60c09c6a91ac963c802e319c28bafc2be66eceb3f1924081724e44d173de2091251d1ea69ec827b94ea5ab63436f0701dd2bf299e1a66a22c4b44b32b88620949736e088bc3ec6e7974426e4b392ecece0e88a7acaf510322d1726da6bc9580dad3c8717619051c220d8654a35eb7fa0a6de4be0456522054f124bbb0bdda4bc177b35a6ca20bd996f3a3499ffd00c93d4705cc4bc05f428541c3adcc36f0b9b9aebc61a88cd4bad8f034dd4a483de9bd3291e4bee06449083c83e"]}';
    ore_json_low := '{"o": ["\\x121212121212597ee28282d03415e7714fccd69eb7eb476c70743e485e20331f59cbc1c848dcdeda716f351eb20588c406a7df5fb8917ebf816739aa1414ac3b8498e493bf0badea5c9fdb3cc34da8b152b995957591880c523beb1d3f12487c38d18f62dd26209a727674e5a5fe3a3e3037860839afd801f6e268e7ba5a049613d57b000f03353a911cce15580808b5a5437e7fe5f4a303847b14979a77af448fac6f39255ec13a949c2378520af48d8e5562957fb84d5f0be62ff2cc4cb4c6de243df329c676af2a0581eb40cd20b63910213afab3fdd6dfe5dc727e051e917428f5d4bca5ccda5bda99f911abffd9e3fec8019c15dad79c485192eabfb16a91af1fa88cf196123c2a6ca46069bb468281b00294bb55e2a6adae2e6549d781d6beb4b5ae35b00eef0701678c1769551eff36ed1060571707244172d212d3e5f457333003f9f4c34e42e2fe7d1cd3367a701500fe0050cbda5d59363dd5a633fb2e067ccbc1db5c33ad25c1e96a62e774ee5672247b5856f48d88ad186e58492e891f32967139ec6fab5290f0f7d0fd6b9538b0669d1597"]}';

    -- ------------------------------------------------------------------------------------------------
    -- -- cs_encrypted_v1 < cs_encrypted_v1
    SELECT
      COUNT(id)
      FROM encrypted WHERE encrypted_int2 <= ore_cs_encrypted_high
    INTO row_count;
    ASSERT row_count = 7;

    -- -- cs_encrypted_v1 < jsonb
    SELECT
      COUNT(id)
      FROM encrypted WHERE encrypted_int2 <= ore_json_high
    INTO row_count;

    ASSERT row_count = 7;

    -- -- jsonb < cs_encrypted_v1
    SELECT
      COUNT(id)
      FROM encrypted WHERE encrypted_int2 <= ore_json_low
    INTO row_count;

    ASSERT row_count = 1;


    -- -- cs_encrypted_v1 >= cs_encrypted_v1
    SELECT
      COUNT(id)
      FROM encrypted WHERE encrypted_int2 >= ore_cs_encrypted_low
    INTO row_count;
    ASSERT row_count = 7;

    -- -- cs_encrypted_v1 > jsonb
    SELECT
      COUNT(id)
      FROM encrypted WHERE encrypted_int2 >= ore_json_high
    INTO row_count;

    ASSERT row_count = 1;

    -- -- jsonb >= cs_encrypted_v1
    SELECT
      COUNT(id)
      FROM encrypted WHERE ore_json_low >= encrypted_int2
    INTO row_count;

    ASSERT row_count = 1;


  END;
$$ LANGUAGE plpgsql;


