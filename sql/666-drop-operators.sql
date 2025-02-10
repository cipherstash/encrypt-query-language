DROP OPERATOR FAMILY IF EXISTS cs_encrypted_ore_64_8_v1_btree_ops_v1 USING btree;
DROP OPERATOR CLASS IF EXISTS cs_encrypted_ore_64_8_v1_btree_ops_v1 USING btree;

DROP OPERATOR IF EXISTS @> (cs_encrypted_v1, cs_encrypted_v1);
DROP OPERATOR IF EXISTS @> (cs_encrypted_v1, cs_match_index_v1);
DROP OPERATOR IF EXISTS @> (cs_match_index_v1, cs_encrypted_v1);

DROP OPERATOR IF EXISTS <@ (cs_encrypted_v1, cs_encrypted_v1);
DROP OPERATOR IF EXISTS <@ (cs_encrypted_v1, cs_match_index_v1);
DROP OPERATOR IF EXISTS <@ (cs_match_index_v1, cs_encrypted_v1);

DROP OPERATOR IF EXISTS <= (ore_64_8_v1, cs_encrypted_v1);
DROP OPERATOR IF EXISTS <= (cs_encrypted_v1, ore_64_8_v1);
DROP OPERATOR IF EXISTS <= (jsonb, cs_encrypted_v1);
DROP OPERATOR IF EXISTS <= (cs_encrypted_v1, jsonb);
DROP OPERATOR IF EXISTS <= (cs_encrypted_v1, cs_encrypted_v1);

DROP OPERATOR IF EXISTS >= (ore_64_8_v1, cs_encrypted_v1);
DROP OPERATOR IF EXISTS >= (jsonb, cs_encrypted_v1);
DROP OPERATOR IF EXISTS >= (cs_encrypted_v1, ore_64_8_v1);
DROP OPERATOR IF EXISTS >= (cs_encrypted_v1, jsonb);
DROP OPERATOR IF EXISTS >= (cs_encrypted_v1, cs_encrypted_v1);

DROP OPERATOR IF EXISTS < (ore_64_8_v1, cs_encrypted_v1);
DROP OPERATOR IF EXISTS < (cs_encrypted_v1, ore_64_8_v1);
DROP OPERATOR IF EXISTS < (jsonb, cs_encrypted_v1);
DROP OPERATOR IF EXISTS < (cs_encrypted_v1, jsonb);
DROP OPERATOR IF EXISTS < (cs_encrypted_v1, cs_encrypted_v1);

DROP OPERATOR IF EXISTS > (ore_64_8_v1, cs_encrypted_v1);
DROP OPERATOR IF EXISTS > (jsonb, cs_encrypted_v1);
DROP OPERATOR IF EXISTS > (cs_encrypted_v1, ore_64_8_v1);
DROP OPERATOR IF EXISTS > (cs_encrypted_v1, jsonb);
DROP OPERATOR IF EXISTS > (cs_encrypted_v1, cs_encrypted_v1);

DROP OPERATOR IF EXISTS = (cs_encrypted_v1, cs_encrypted_v1);
DROP OPERATOR IF EXISTS = (cs_encrypted_v1, jsonb);
DROP OPERATOR IF EXISTS = (jsonb, cs_encrypted_v1);
DROP OPERATOR IF EXISTS = (cs_encrypted_v1, cs_unique_index_v1);
DROP OPERATOR IF EXISTS = (cs_unique_index_v1, cs_encrypted_v1);
DROP OPERATOR IF EXISTS = (cs_encrypted_v1, ore_64_8_v1);
DROP OPERATOR IF EXISTS = (ore_64_8_v1, cs_encrypted_v1);

DROP OPERATOR IF EXISTS <> (cs_encrypted_v1, cs_encrypted_v1);
DROP OPERATOR IF EXISTS <> (cs_encrypted_v1, jsonb);
DROP OPERATOR IF EXISTS <> (jsonb, cs_encrypted_v1);
DROP OPERATOR IF EXISTS <> (cs_encrypted_v1, cs_unique_index_v1);
DROP OPERATOR IF EXISTS <> (cs_unique_index_v1, cs_encrypted_v1);
DROP OPERATOR IF EXISTS <> (ore_64_8_v1, cs_encrypted_v1);
DROP OPERATOR IF EXISTS <> (cs_encrypted_v1, ore_64_8_v1);
