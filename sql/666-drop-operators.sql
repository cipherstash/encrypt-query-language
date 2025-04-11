DROP OPERATOR FAMILY IF EXISTS eql_v1.encrypted_ore_64_8_v1_btree_ops USING btree;
DROP OPERATOR CLASS IF EXISTS ore_64_8_v1_btree_ops USING btree;
DROP OPERATOR IF EXISTS @> (eql_v1_encrypted, eql_v1_encrypted);
DROP OPERATOR IF EXISTS @> (eql_v1_encrypted, eql_v1.match_index);
DROP OPERATOR IF EXISTS @> (eql_v1.match_index, eql_v1_encrypted);


DROP OPERATOR IF EXISTS <@ (eql_v1_encrypted, eql_v1_encrypted);
DROP OPERATOR IF EXISTS <@ (eql_v1_encrypted, eql_v1.match_index);
DROP OPERATOR IF EXISTS <@ (eql_v1.match_index, eql_v1_encrypted);

DROP OPERATOR IF EXISTS <= (eql_v1.ore_64_8_v1, eql_v1_encrypted);
DROP OPERATOR IF EXISTS <= (eql_v1_encrypted, eql_v1.ore_64_8_v1);
DROP OPERATOR IF EXISTS <= (jsonb, eql_v1_encrypted);
DROP OPERATOR IF EXISTS <= (eql_v1_encrypted, jsonb);
DROP OPERATOR IF EXISTS <= (eql_v1_encrypted, eql_v1_encrypted);

DROP OPERATOR IF EXISTS >= (eql_v1.ore_64_8_v1, eql_v1_encrypted);
DROP OPERATOR IF EXISTS >= (jsonb, eql_v1_encrypted);
DROP OPERATOR IF EXISTS >= (eql_v1_encrypted, eql_v1.ore_64_8_v1);
DROP OPERATOR IF EXISTS >= (eql_v1_encrypted, jsonb);
DROP OPERATOR IF EXISTS >= (eql_v1_encrypted, eql_v1_encrypted);

DROP OPERATOR IF EXISTS < (eql_v1.ore_64_8_v1, eql_v1_encrypted);
DROP OPERATOR IF EXISTS < (eql_v1_encrypted, eql_v1.ore_64_8_v1);
DROP OPERATOR IF EXISTS < (jsonb, eql_v1_encrypted);
DROP OPERATOR IF EXISTS < (eql_v1_encrypted, jsonb);
DROP OPERATOR IF EXISTS < (eql_v1_encrypted, eql_v1_encrypted);

DROP OPERATOR IF EXISTS > (eql_v1.ore_64_8_v1, eql_v1_encrypted);
DROP OPERATOR IF EXISTS > (jsonb, eql_v1_encrypted);
DROP OPERATOR IF EXISTS > (eql_v1_encrypted, eql_v1.ore_64_8_v1);
DROP OPERATOR IF EXISTS > (eql_v1_encrypted, jsonb);
DROP OPERATOR IF EXISTS > (eql_v1_encrypted, eql_v1_encrypted);

DROP OPERATOR IF EXISTS = (eql_v1_encrypted, eql_v1_encrypted);
DROP OPERATOR IF EXISTS = (eql_v1_encrypted, jsonb);
DROP OPERATOR IF EXISTS = (jsonb, eql_v1_encrypted);
DROP OPERATOR IF EXISTS = (eql_v1_encrypted, eql_v1.unique_index);
DROP OPERATOR IF EXISTS = (eql_v1.unique_index, eql_v1_encrypted);
DROP OPERATOR IF EXISTS = (eql_v1_encrypted, eql_v1.ore_64_8_v1);
DROP OPERATOR IF EXISTS = (eql_v1.ore_64_8_v1, eql_v1_encrypted);

DROP OPERATOR IF EXISTS <> (eql_v1_encrypted, eql_v1_encrypted);
DROP OPERATOR IF EXISTS <> (eql_v1_encrypted, jsonb);
DROP OPERATOR IF EXISTS <> (jsonb, eql_v1_encrypted);
DROP OPERATOR IF EXISTS <> (eql_v1_encrypted, eql_v1.unique_index);
DROP OPERATOR IF EXISTS <> (eql_v1.unique_index, eql_v1_encrypted);
DROP OPERATOR IF EXISTS <> (eql_v1.ore_64_8_v1, eql_v1_encrypted);
DROP OPERATOR IF EXISTS <> (eql_v1_encrypted, eql_v1.ore_64_8_v1);



DROP OPERATOR FAMILY IF EXISTS eql_v1.ste_vec_encrypted_term_btree_ops USING btree;
DROP OPERATOR CLASS IF EXISTS eql_v1.ste_vec_encrypted_term_btree_ops USING btree;

DROP OPERATOR IF EXISTS = (eql_v1.ste_vec_encrypted_term, eql_v1.ste_vec_encrypted_term);
DROP OPERATOR IF EXISTS <> (eql_v1.ste_vec_encrypted_term, eql_v1.ste_vec_encrypted_term);
DROP OPERATOR IF EXISTS > (eql_v1.ste_vec_encrypted_term, eql_v1.ste_vec_encrypted_term);
DROP OPERATOR IF EXISTS < (eql_v1.ste_vec_encrypted_term_v1, eql_v1.ste_vec_encrypted_term_v1);
DROP OPERATOR IF EXISTS >= (eql_v1.ste_vec_encrypted_term_v1, eql_v1.ste_vec_encrypted_term_v1);
DROP OPERATOR IF EXISTS <= (eql_v1.ste_vec_encrypted_term_v1, eql_v1.ste_vec_encrypted_term_v1);


DROP OPERATOR IF EXISTS ~~ (eql_v1_encrypted, eql_v1_encrypted);
DROP OPERATOR IF EXISTS ~~ (eql_v1_encrypted, eql_v1.match_index);
DROP OPERATOR IF EXISTS ~~ (eql_v1.match_index, eql_v1_encrypted);
DROP OPERATOR IF EXISTS ~~ (eql_v1.match_index, eql_v1.match_index);
DROP OPERATOR IF EXISTS ~~ (eql_v1_encrypted, jsonb);
DROP OPERATOR IF EXISTS ~~ (jsonb, eql_v1_encrypted);

DROP OPERATOR IF EXISTS ~~* (eql_v1_encrypted, eql_v1_encrypted);
DROP OPERATOR IF EXISTS ~~* (eql_v1_encrypted, eql_v1.match_index);
DROP OPERATOR IF EXISTS ~~* (eql_v1.match_index, eql_v1_encrypted);
DROP OPERATOR IF EXISTS ~~* (eql_v1.match_index, eql_v1.match_index);
DROP OPERATOR IF EXISTS ~~* (eql_v1_encrypted, jsonb);
DROP OPERATOR IF EXISTS ~~* (jsonb, eql_v1_encrypted);

