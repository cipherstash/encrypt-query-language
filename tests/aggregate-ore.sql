\set ON_ERROR_STOP on

-- create table
DROP TABLE IF EXISTS agg_test;
CREATE TABLE agg_test
(
    plain_int integer,
    enc_int cs_encrypted_v1
);

-- Add data. These are saved from the psql query output connected to Proxy.
-- Decrypted `enc_int` value is the same as the `plain_int` value in the same row.
INSERT INTO agg_test (plain_int, enc_int) VALUES
(
  NULL,
  NULL
),
(
  3,
  '{"c": "mBbJyWl%QyVQT_N?b~OpQj!$J7B7H2CK@gB#`36H312|)kY;SeM7R*dAl5{R*U)AI+$~k7(JPvj;hmQK^F_}g^7Zs^WuYa^B(7y{V{&<LbY)~;X>N2hzy", "i": {"c": "encrypted_int4", "t": "encrypted"}, "k": "ct", "m": null, "o": ["ccccccccb06565ebd23d6a4c3eee512713175e673c6d995ff5d9b1d3492fe8eb289c3eb95029025f5b71fc6e06632b4a1302980e433361c7999724dbdd052739258d9444b0fbd43cc61368e60f4b0d5aeca2aa85c1c89933b53afffcc4eb0632dca75f632bb9bc792d1dbd6bced6253291f0db134552d384e9e378f4f5890c31ca9d115965a0e8fbf13ad8d1d33f88d360d5e2f9680fb158f98158443ffc769cd9aac94380f05e3226b785f58006e5b9da6b8d86a7441a88fd848099a2400ef59b494b0c30013568dc1be9bba560565fccb49309ba2ec3edcff6f9d7a67b519b3754b37b0025dff7592a6117949a04043c100353289628884fe06cb2099e7b4b49abea9797a73ee0b85283a5b6f69bcf45f87e6cd6d45ecfd1633903270781173ed9d31a682bba0e54ff355f456bf0c468e378e41cb54fcc074ad40fb4448f6fec892c1ecda15a5efffb8dde3a3b282865ac436d7e43d48d4327c439956733697d3f5b02ead4805a7f905bdae24c1b35252e34939676a07ddb5454c3580c7d76d792a97988e35142f43667112432623eda5126e9af2592dd"], "v": 1}'::cs_encrypted_v1
),
(
  5,
  '{"c": "mBbKSqWLK6yl>o%G%&x+2$jdg7F`-R(^>R1Q^wGod8-FZ5C$xFI4dN?Ap114=77xPZ9!cKxE}qmyXrhx#K`4ztbUrysQrOFqON6bV{&<LbY)~;X>N2hzy", "i": {"c": "encrypted_int4", "t": "encrypted"}, "k": "ct", "m": null, "o": ["ccccccccb065659dd23d6a4c3eee512713175e673c6d995ff5d9b1d3492fe8eb289c3eb95029025f5b71fc6e06632b4a1302980e433361c7999724dbdd052739258d9444b0fbd43cc61368e60f4b0d5aeca2aa85c1c89933b53afffcc4eb0632dca75f632bb9bc792d1dbd6bced6253291f0db134552d384bec7bfb23290d7559fd8637b85ca7510cca465570029734ef0319c77177913ad84f54852bed2e2a67b6dafcab3eb70d3a2592414a43acc03703083cf1fa1984dfc0719337d5de4eefd0d137588641a0d38c771b77ab07ebab3fc9bfd7469c4222e1a8edee71188eeb24bfffcd82f711156381d8068223e3d75f5ba8a958182bc46a0ab58c29872cd17e559ed0b935a445249dbac5b51438cebaf9d28d5c8b67cd99f990d5295c1e37470ce5b33fe01eaf31d84c9a08b267c0e9e1aadfcce7f9e2253ababa71eaf1fec309dc988e454717a3c2e3bffb1c546a7195ecf274eb7d691abcf46a61e34d4c63c45d48831dc23aa11f981de692926cd1d1d77a340c9e54baf62da61d5f88960a93e120d3828f4053577b93b536cc9b05c889dcf171865"], "v": 1}'::cs_encrypted_v1
),
(
  1,
  '{"c": "mBbJSy$p0fHEK%aOAOYi4PTJN7B@a-j{+xl7tffjGTN<-Znt3Zge#lGAX^WHzU`7ml<4vRHLKxoB%}N<H3?J~gR*ISwBlJ)X0By!V{&<LbY)~;X>N2hzy", "i": {"c": "encrypted_int4", "t": "encrypted"}, "k": "ct", "m": null, "o": ["ccccccccb0656502d23d6a4c3eee512713175e673c6d995ff5d9b1d3492fe8eb289c3eb95029025f5b71fc6e06632b4a1302980e433361c7999724dbdd052739258d9444b0fbd43cc61368e60f4b0d5aeca2aa85c1c89933b53afffcc4eb0632dca75f632bb9bc792d1dbd6bced6253291f0db134552d384250ca116ef329616ddb341917699b9ea48901124a15a4547be1ff7c672c0c1bc6bb17e2a141f46138fc314f4bf8a55068bf031bc48f038c379e54cfbb1c64eb223c18c87cd68a91fb031905e11d9478f158b561399b527038efc594bfd9fb19c963a2778b75215e1d8933b08df04d1c62742fd48a4de310792031a70ca4b157bc218ab3fbadc6dc14b939422023331c03bcf4b673c5d261a19c3d13155cbaa1b84e9e90e389fa6973dde07fba08c13847006707488e288ce780d59700197452ebc68d22032ab03f7b445e45ed7abb1af34955199440f7db2c969c60b1eb49cdcd75d5e8f7de37848ddebb40df8e14d4b92910e15fedac3f61f22ef430805ba1bbf5fccc9fe792e4c0353beee48ca03ef23c7d3fab19e9aa218aefb44e6c26d70"], "v": 1}'::cs_encrypted_v1
),
(
  3,
  '{"c": "mBbLa7Cm?&jvpfcv1d3hep>s)76qzUbwUky&M&C<M-e2q^@e798gqWcAb{9a>3mjDG_os-_y0MRaMGl@&p#AOuusN|3Lu=mBCcg_V{&<LbY)~;X>N2hzy", "i": {"c": "encrypted_int4", "t": "encrypted"}, "k": "ct", "m": null, "o": ["ccccccccb06565ebd23d6a4c3eee512713175e673c6d995ff5d9b1d3492fe8eb289c3eb95029025f5b71fc6e06632b4a1302980e433361c7999724dbdd052739258d9444b0fbd43cc61368e60f4b0d5aeca2aa85c1c89933b53afffcc4eb0632dca75f632bb9bc792d1dbd6bced6253291f0db134552d384e9e378f4f5890c31ca9d115965a0e8fb2c3c60ccce84ffc03bddb22b27a1ce278eec118496fd23f083ebb21bb4b83b89eda8c0bdea50debc5ec4f2b2d91b63a80d39386194ad9d129bee2f5168341cb41ed26dc03466cac5e2dbe7336fdb74c0d37d63b396033ce60002c9950f5ac2970dacf4caace2eef5b81544df88a7ef2a8d69550d25d39c678c8e43a3dcc2857018a2c979b45c6b19dabd28ae7388d62916e6742763d6484d1b45154e6c8e6a66e02b03f64b67ddef24747dded32e226e3a93d5d1a92d11e760403cad04a0dd07c14da336a409739e8bbeb3b3d6b92117fa2d2c941da4996ea61b29ca3fffb4594ddbeab7105a1b4c5e422ec5ab8154db545103d8c2889be2e4591198912446d8b33b8708a4cc959a1e0957dcae6a50c3"], "v": 1}'::cs_encrypted_v1
)
;

-- run normal cases
DO $$
  BEGIN
  -- min null finds null
  ASSERT ((SELECT cs_min_v1(enc_int) FROM agg_test where enc_int IS NULL) IS NULL);

  -- min enc_int finds the minimum (1)
  ASSERT ((SELECT enc_int FROM agg_test WHERE plain_int = 1) = (SELECT cs_min_v1(enc_int) FROM agg_test));

  -- max null finds null
  ASSERT ((SELECT cs_max_v1(enc_int) FROM agg_test where enc_int IS NULL) IS NULL);

  -- max enc_int finds the maximum (5)
  ASSERT ((SELECT enc_int FROM agg_test WHERE plain_int = 5) = (SELECT cs_max_v1(enc_int) FROM agg_test));
  END;
$$ LANGUAGE plpgsql;

-- insert data without "o" (ore index value)
INSERT INTO agg_test (plain_int, enc_int) VALUES
(
  3,
  '{"c": "mBbLa7Cm?&jvpfcv1d3hep>s)76qzUbwUky&M&C<M-e2q^@e798gqWcAb{9a>3mjDG_os-_y0MRaMGl@&p#AOuusN|3Lu=mBCcg_V{&<LbY)~;X>N2hzy", "i": {"c": "encrypted_int4", "t": "encrypted"}, "k": "ct", "m": null, "v": 1}'::cs_encrypted_v1
);

-- run exceptional case
DO $$
  DECLARE
    error_message text;
  BEGIN
    -- min enc_int raises exception
    SELECT cs_min_v1(enc_int) FROM agg_test;
  EXCEPTION
    WHEN others THEN
      error_message := SQLERRM;

      IF error_message LIKE '%' || 'Expected an ore index (o) value in json' || '%' THEN
        ASSERT true;
      ELSE
        RAISE EXCEPTION 'Unexpected exception: %', error_message;
      END IF;
  END;
$$ LANGUAGE plpgsql;

-- run exceptional case
DO $$
  DECLARE
    error_message text;
  BEGIN
    -- max enc_int raises exception
    SELECT cs_max_v1(enc_int) FROM agg_test;
  EXCEPTION
    WHEN others THEN
      error_message := SQLERRM;

      IF error_message LIKE '%' || 'Expected an ore index (o) value in json' || '%' THEN
        ASSERT true;
      ELSE
        RAISE EXCEPTION 'Unexpected exception: %', error_message;
      END IF;
  END;
$$ LANGUAGE plpgsql;
