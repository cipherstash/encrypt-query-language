-- Operators for match comparisons of eql_v1_encrypted types
--
-- Support for the following comparisons:
--
--      eql_v1_encrypted ~~ eql_v1_encrypted
--      eql_v1_encrypted ~~ jsonb
--      eql_v1_encrypted ~~ eql_v1.match_index
--

DROP OPERATOR IF EXISTS ~~ (eql_v1_encrypted, eql_v1_encrypted);
DROP OPERATOR IF EXISTS ~~* (eql_v1_encrypted, eql_v1_encrypted);

DROP FUNCTION IF EXISTS eql_v1.encrypted_match(a eql_v1_encrypted, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_match(a eql_v1_encrypted, b eql_v1_encrypted)
RETURNS boolean AS $$
  SELECT eql_v1.match(a) @> eql_v1.match(b);
$$ LANGUAGE SQL;

CREATE OPERATOR ~~(
  FUNCTION=eql_v1.encrypted_match,
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1_encrypted,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

CREATE OPERATOR ~~*(
  FUNCTION=eql_v1.encrypted_match,
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1_encrypted,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS ~~ (eql_v1_encrypted, eql_v1.match_index);
DROP FUNCTION IF EXISTS eql_v1.encrypted_match(a eql_v1_encrypted, b eql_v1.match_index);

CREATE FUNCTION eql_v1.encrypted_match(a eql_v1_encrypted, b eql_v1.match_index)
RETURNS boolean AS $$
  SELECT eql_v1.match(a) @> b;
$$ LANGUAGE SQL;

CREATE OPERATOR ~~(
  FUNCTION=eql_v1.encrypted_match,
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1.match_index,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

CREATE OPERATOR ~~*(
  FUNCTION=eql_v1.encrypted_match,
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1.match_index,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);



DROP OPERATOR IF EXISTS ~~ (eql_v1.match_index, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_match(a eql_v1.match_index, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_match(a eql_v1.match_index, b eql_v1_encrypted)
RETURNS boolean AS $$
  SELECT a @> eql_v1.match(b);
$$ LANGUAGE SQL;

CREATE OPERATOR ~~(
  FUNCTION=eql_v1.encrypted_match,
  LEFTARG=eql_v1.match_index,
  RIGHTARG=eql_v1_encrypted,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

CREATE OPERATOR ~~*(
  FUNCTION=eql_v1.encrypted_match,
  LEFTARG=eql_v1.match_index,
  RIGHTARG=eql_v1_encrypted,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS ~~ (eql_v1.match_index, eql_v1.match_index);
DROP FUNCTION IF EXISTS eql_v1.encrypted_match(a eql_v1.match_index, b eql_v1.match_index);

CREATE FUNCTION eql_v1.encrypted_match(a eql_v1.match_index, b eql_v1.match_index)
RETURNS boolean AS $$
  SELECT a @> b;
$$ LANGUAGE SQL;

CREATE OPERATOR ~~(
  FUNCTION=eql_v1.encrypted_match,
  LEFTARG=eql_v1.match_index,
  RIGHTARG=eql_v1.match_index,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

CREATE OPERATOR ~~*(
  FUNCTION=eql_v1.encrypted_match,
  LEFTARG=eql_v1.match_index,
  RIGHTARG=eql_v1.match_index,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS ~~ (eql_v1_encrypted, jsonb);
DROP FUNCTION IF EXISTS eql_v1.encrypted_match(a eql_v1_encrypted, b jsonb);

CREATE FUNCTION eql_v1.encrypted_match(a eql_v1_encrypted, b jsonb)
RETURNS boolean AS $$
  SELECT eql_v1.match(a) @> eql_v1.match(b);
$$ LANGUAGE SQL;

CREATE OPERATOR ~~(
  FUNCTION=eql_v1.encrypted_match,
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=jsonb,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

CREATE OPERATOR ~~*(
  FUNCTION=eql_v1.encrypted_match,
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=jsonb,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);



DROP OPERATOR IF EXISTS ~~ (jsonb, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_match(a jsonb, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_match(a jsonb, b eql_v1_encrypted)
RETURNS boolean AS $$
  SELECT eql_v1.match(a) @> eql_v1.match(b);
$$ LANGUAGE SQL;

CREATE OPERATOR ~~(
  FUNCTION=eql_v1.encrypted_match,
  LEFTARG=jsonb,
  RIGHTARG=eql_v1_encrypted,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

CREATE OPERATOR ~~*(
  FUNCTION=eql_v1.encrypted_match,
  LEFTARG=jsonb,
  RIGHTARG=eql_v1_encrypted,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


-- -----------------------------------------------------------------------------

