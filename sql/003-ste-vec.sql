
---
--- SteVec types, functions, and operators
---

CREATE TYPE eql_v1.ste_vec_encrypted_term AS (
  bytes bytea
);

DROP FUNCTION IF EXISTS eql_v1.compare_ste_vec_encrypted_term(a eql_v1.ste_vec_encrypted_term, b eql_v1.ste_vec_encrypted_term);

CREATE FUNCTION eql_v1.compare_ste_vec_encrypted_term(a eql_v1.ste_vec_encrypted_term, b eql_v1.ste_vec_encrypted_term)
RETURNS INT AS $$
DECLARE
  header_a INT;
  header_b INT;
  body_a BYTEA;
  body_b BYTEA;
BEGIN
  -- `get_byte` is 0-indexed
  header_a := get_byte(a.bytes, 0);
  header_b := get_byte(b.bytes, 0);

  IF header_a != header_b THEN
    RAISE EXCEPTION 'eql_v1.compare_ste_vec_encrypted_term: expected equal header bytes';
  END IF;

  -- `substr` is 1-indexed (yes, `subtr` starts at 1 and `get_byte` starts at 0).
  body_a := substr(a.bytes, 2);
  body_b := substr(b.bytes, 2);

  CASE header_a
    WHEN 0 THEN
      RAISE EXCEPTION 'eql_v1.compare_ste_vec_encrypted_term: can not compare MAC terms';
    WHEN 1 THEN
      RETURN eql_v1.compare_ore_cllw_8_v1(ROW(body_a)::eql_v1.ore_cllw_8_v1, ROW(body_b)::eql_v1.ore_cllw_8_v1);
    WHEN 2 THEN
      RETURN eql_v1.compare_lex_ore_cllw_8_v1(ROW(body_a)::eql_v1.ore_cllw_8_variable_v1, ROW(body_b)::eql_v1.ore_cllw_8_variable_v1);
    ELSE
      RAISE EXCEPTION 'eql_v1.compare_ste_vec_encrypted_term: invalid header for ste_vec_encrypted_term: header "%", body "%', header_a, body_a;
  END CASE;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS eql_v1.ste_vec_encrypted_term_eq(a eql_v1.ste_vec_encrypted_term, b eql_v1.ste_vec_encrypted_term);

CREATE FUNCTION eql_v1.ste_vec_encrypted_term_eq(a eql_v1.ste_vec_encrypted_term, b eql_v1.ste_vec_encrypted_term) RETURNS boolean AS $$
  SELECT eql_v1.__bytea_ct_eq(a.bytes, b.bytes)
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS eql_v1.ste_vec_encrypted_term_neq(a eql_v1.ste_vec_encrypted_term, b eql_v1.ste_vec_encrypted_term);

CREATE FUNCTION eql_v1.ste_vec_encrypted_term_neq(a eql_v1.ste_vec_encrypted_term, b eql_v1.ste_vec_encrypted_term) RETURNS boolean AS $$
  SELECT not eql_v1.__bytea_ct_eq(a.bytes, b.bytes)
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS eql_v1.ste_vec_encrypted_term_lt(a eql_v1.ste_vec_encrypted_term, b eql_v1.ste_vec_encrypted_term);

CREATE FUNCTION eql_v1.ste_vec_encrypted_term_lt(a eql_v1.ste_vec_encrypted_term, b eql_v1.ste_vec_encrypted_term) RETURNS boolean AS $$
  SELECT eql_v1.compare_ste_vec_encrypted_term(a, b) = -1
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS eql_v1.ste_vec_encrypted_term_lte(a eql_v1.ste_vec_encrypted_term, b eql_v1.ste_vec_encrypted_term);

CREATE FUNCTION eql_v1.ste_vec_encrypted_term_lte(a eql_v1.ste_vec_encrypted_term, b eql_v1.ste_vec_encrypted_term) RETURNS boolean AS $$
  SELECT eql_v1.compare_ste_vec_encrypted_term(a, b) != 1
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS eql_v1.cs_ste_vec_encrypted_term_gt(a eql_v1.ste_vec_encrypted_term, b eql_v1.ste_vec_encrypted_term);

CREATE FUNCTION eql_v1.ste_vec_encrypted_term_gt(a eql_v1.ste_vec_encrypted_term, b eql_v1.ste_vec_encrypted_term) RETURNS boolean AS $$
  SELECT eql_v1.compare_ste_vec_encrypted_term(a, b) = 1
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS eql_v1.ste_vec_encrypted_term_gte(a eql_v1.ste_vec_encrypted_term, b eql_v1.ste_vec_encrypted_term);

CREATE FUNCTION eql_v1.ste_vec_encrypted_term_gte(a eql_v1.ste_vec_encrypted_term, b eql_v1.ste_vec_encrypted_term) RETURNS boolean AS $$
  SELECT eql_v1.compare_ste_vec_encrypted_term(a, b) != -1
$$ LANGUAGE SQL;

DROP OPERATOR IF EXISTS = (eql_v1.ste_vec_encrypted_term, eql_v1.ste_vec_encrypted_term);

CREATE OPERATOR = (
  PROCEDURE="eql_v1.ste_vec_encrypted_term_eq",
  LEFTARG=eql_v1.ste_vec_encrypted_term,
  RIGHTARG=eql_v1.ste_vec_encrypted_term,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS <> (eql_v1.ste_vec_encrypted_term, eql_v1.ste_vec_encrypted_term);

CREATE OPERATOR <> (
  PROCEDURE="eql_v1.ste_vec_encrypted_term_neq",
  LEFTARG=eql_v1.ste_vec_encrypted_term,
  RIGHTARG=eql_v1.ste_vec_encrypted_term,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS > (eql_v1.ste_vec_encrypted_term, eql_v1.ste_vec_encrypted_term);

CREATE OPERATOR > (
  PROCEDURE="eql_v1.ste_vec_encrypted_term_gt",
  LEFTARG=eql_v1.ste_vec_encrypted_term,
  RIGHTARG=eql_v1.ste_vec_encrypted_term,
  NEGATOR = <=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS < (eql_v1.ste_vec_encrypted_term_v1, eql_v1.ste_vec_encrypted_term_v1);

CREATE OPERATOR < (
  PROCEDURE="eql_v1.ste_vec_encrypted_term_lt",
  LEFTARG=eql_v1.ste_vec_encrypted_term,
  RIGHTARG=eql_v1.ste_vec_encrypted_term,
  NEGATOR = >=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS >= (eql_v1.ste_vec_encrypted_term_v1, eql_v1.ste_vec_encrypted_term_v1);

CREATE OPERATOR >= (
  PROCEDURE="eql_v1.ste_vec_encrypted_term_gte",
  LEFTARG=eql_v1.ste_vec_encrypted_term,
  RIGHTARG=eql_v1.ste_vec_encrypted_term,
  NEGATOR = <,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS <= (eql_v1.ste_vec_encrypted_term_v1, eql_v1.ste_vec_encrypted_term_v1);

CREATE OPERATOR <= (
  PROCEDURE="eql_v1.ste_vec_encrypted_term_lte",
  LEFTARG=eql_v1.ste_vec_encrypted_term,
  RIGHTARG=eql_v1.ste_vec_encrypted_term,
  NEGATOR = >,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR FAMILY IF EXISTS eql_v1.ste_vec_encrypted_term_btree_ops USING btree;

CREATE OPERATOR FAMILY eql_v1.ste_vec_encrypted_term_btree_ops USING btree;

DROP OPERATOR CLASS IF EXISTS eql_v1.ste_vec_encrypted_term_btree_ops USING btree;

CREATE OPERATOR CLASS eql_v1.ste_vec_encrypted_term_btree_ops DEFAULT FOR TYPE eql_v1.ste_vec_encrypted_term USING btree FAMILY eql_v1.ste_vec_encrypted_term_btree_ops  AS
        OPERATOR 1 <,
        OPERATOR 2 <=,
        OPERATOR 3 =,
        OPERATOR 4 >=,
        OPERATOR 5 >,
        FUNCTION 1 eql_v1.compare_ste_vec_encrypted_term(a eql_v1.ste_vec_encrypted_term, b eql_v1.ste_vec_encrypted_term);

CREATE TYPE eql_v1.ste_vec_entry AS (
    tokenized_selector text,
    term eql_v1.ste_vec_encrypted_term,
    ciphertext text
);

CREATE TYPE eql_v1.ste_vec_index AS (
    entries eql_v1.ste_vec_entry[]
);

DROP FUNCTION IF EXISTS eql_v1.ste_vec_value(col jsonb, selector jsonb);

-- col: already encrypted payload
-- selector: already encrypted payload
-- returns a value in the format of our custom jsonb schema that will be decrypted
CREATE FUNCTION eql_v1.cs_ste_vec_value(col jsonb, selector jsonb)
RETURNS jsonb AS $$
DECLARE
  ste_vec_index eql_v1.cs_ste_vec_index;
  target_selector text;
  found text;
  ignored text;
  i integer;
BEGIN
  ste_vec_index := eql_v1.ste_vec(col);

  IF ste_vec_index IS NULL THEN
    RETURN NULL;
  END IF;

  target_selector := selector->>'svs';

  FOR i IN 1..array_length(ste_vec_index.entries, 1) LOOP
      -- The ELSE part is to help ensure constant time operation.
      -- The result is thrown away.
      IF ste_vec_index.entries[i].tokenized_selector = target_selector THEN
        found := ste_vec_index.entries[i].ciphertext;
      ELSE
        ignored := ste_vec_index.entries[i].ciphertext;
      END IF;
  END LOOP;

  IF found IS NOT NULL THEN
    RETURN jsonb_build_object(
      'k', 'ct',
      'c', found,
      'o', NULL,
      'm', NULL,
      'u', NULL,
      'i', col->'i',
      'v', 1
    );
  ELSE
    RETURN NULL;
  END IF;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS eql_v1.ste_vec_terms(col jsonb, selector jsonb);

CREATE FUNCTION eql_v1.ste_vec_terms(col jsonb, selector jsonb)
RETURNS eql_v1.ste_vec_encrypted_term[] AS $$
DECLARE
  ste_vec_index eql_v1.ste_vec_index;
  target_selector text;
  found eql_v1.ste_vec_encrypted_term;
  ignored eql_v1.ste_vec_encrypted_term;
  i integer;
  term_array eql_v1.ste_vec_encrypted_term_v1[];
BEGIN
  ste_vec_index := eql_v1.ste_vec(col);

  IF ste_vec_index IS NULL THEN
    RETURN NULL;
  END IF;

  target_selector := selector->>'svs';

  FOR i IN 1..array_length(ste_vec_index.entries, 1) LOOP
      -- The ELSE part is to help ensure constant time operation.
      -- The result is thrown away.
      IF ste_vec_index.entries[i].tokenized_selector = target_selector THEN
        found := ste_vec_index.entries[i].term;
        term_array := array_append(term_array, found);
      ELSE
        ignored := ste_vec_index.entries[i].term;
      END IF;
  END LOOP;

  RETURN term_array;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS eql_v1.ste_vec_term(col jsonb, selector jsonb);

-- col: already encrypted payload
-- selector: already encrypted payload
-- returns a value that can be used for comparison operations
CREATE OR REPLACE FUNCTION eql_v1._ste_vec_term(col jsonb, selector jsonb)
RETURNS eql_v1.ste_vec_encrypted_term AS $$
DECLARE
  ste_vec_index eql_v1.ste_vec_index;
  target_selector text;
  found eql_v1.ste_vec_encrypted_term;
  ignored eql_v1.ste_vec_encrypted_term;
  i integer;
BEGIN
  ste_vec_index := eql_v1.ste_vec(col);

  IF ste_vec_index IS NULL THEN
    RETURN NULL;
  END IF;

  target_selector := selector->>'svs';

  FOR i IN 1..array_length(ste_vec_index.entries, 1) LOOP
      -- The ELSE part is to help ensure constant time operation.
      -- The result is thrown away.
      IF ste_vec_index.entries[i].tokenized_selector = target_selector THEN
        found := ste_vec_index.entries[i].term;
      ELSE
        ignored := ste_vec_index.entries[i].term;
      END IF;
  END LOOP;

  RETURN found;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS eql_v1.ste_vec_term(col jsonb);

CREATE FUNCTION eql_v1.ste_vec_term(col jsonb)
RETURNS eql_v1.ste_vec_encrypted_term AS $$
DECLARE
  ste_vec_index eql_v1.ste_vec_index;
BEGIN
  ste_vec_index := eql_v1.ste_vec(col);

  IF ste_vec_index IS NULL THEN
    RETURN NULL;
  END IF;

  RETURN ste_vec_index.entries[1].term;
END;
$$ LANGUAGE plpgsql;

-- Determine if a == b (ignoring ciphertext values)
DROP FUNCTION IF EXISTS eql_v1.ste_vec_entry_eq(a eql_v1.ste_vec_entry, b eql_v1.ste_vec_entry);

CREATE FUNCTION eql_v1.ste_vec_entry_eq(a eql_v1.ste_vec_entry, b eql_v1.ste_vec_entry)
RETURNS boolean AS $$
DECLARE
    sel_cmp int;
    term_cmp int;
BEGIN
    -- Constant time comparison
    IF a.tokenized_selector = b.tokenized_selector THEN
        sel_cmp := 1;
    ELSE
        sel_cmp := 0;
    END IF;
    IF a.term = b.term THEN
        term_cmp := 1;
    ELSE
        term_cmp := 0;
    END IF;
    RETURN (sel_cmp # term_cmp) = 0;
END;
$$ LANGUAGE plpgsql;

-- Determine if a contains b (ignoring ciphertext values)
DROP FUNCTION IF EXISTS eql_v1.ste_vec_logical_contains(a eql_v1.ste_vec_index, b eql_v1.ste_vec_index);

CREATE FUNCTION eql_v1.ste_vec_logical_contains(a eql_v1.ste_vec_index, b eql_v1.ste_vec_index)
RETURNS boolean AS $$
DECLARE
    result boolean;
    intermediate_result boolean;
BEGIN
    result := true;
    IF array_length(b.entries, 1) IS NULL THEN
        RETURN result;
    END IF;
    FOR i IN 1..array_length(b.entries, 1) LOOP
        intermediate_result := eql_v1.ste_vec_entry_array_contains_entry(a.entries, b.entries[i]);
        result := result AND intermediate_result;
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Determine if a contains b (ignoring ciphertext values)
DROP FUNCTION IF EXISTS eql_v1.ste_vec_entry_array_contains_entry(a eql_v1.ste_vec_entry[], b eql_v1.ste_vec_entry);

CREATE FUNCTION eql_v1.ste_vec_entry_array_contains_entry(a eql_v1.ste_vec_entry[], b eql_v1.ste_vec_entry)
RETURNS boolean AS $$
DECLARE
    result boolean;
    intermediate_result boolean;
BEGIN
    IF array_length(a, 1) IS NULL THEN
        RETURN false;
    END IF;

    result := false;
    FOR i IN 1..array_length(a, 1) LOOP
        intermediate_result := a[i].tokenized_selector = b.tokenized_selector AND a[i].term = b.term;
        result := result OR intermediate_result;
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Determine if a is contained by b (ignoring ciphertext values)
DROP FUNCTION IF EXISTS eql_v1.ste_vec_logical_is_contained(a eql_v1.ste_vec_index, b eql_v1.ste_vec_index);

CREATE FUNCTION eql_v1.ste_vec_logical_is_contained(a eql_v1.ste_vec_index, b eql_v1.ste_vec_index)
RETURNS boolean AS $$
BEGIN
    RETURN eql_v1.ste_vec_logical_contains(b, a);
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS eql_v1.jsonb_to_cs_ste_vec_index(input jsonb);

CREATE FUNCTION eql_v1.jsonb_to_cs_ste_vec_index(input jsonb)
RETURNS eql_v1.ste_vec_index AS $$
DECLARE
    vec_entry eql_v1._ste_vec_entry;
    entry_array eql_v1.ste_vec_v1_entry[];
    entry_json jsonb;
    entry_json_array jsonb[];
    entry_array_length int;
    i int;
BEGIN
    FOR entry_json IN SELECT * FROM jsonb_array_elements(input)
    LOOP
        vec_entry := ROW(
           entry_json->>0,
           ROW(decode(entry_json->>1, 'hex'))::eql_v1.ste_vec_encrypted_term,
           entry_json->>2
        )::eql_v1.ste_vec_entry;
        entry_array := array_append(entry_array, vec_entry);
    END LOOP;

    RETURN ROW(entry_array)::eql_v1.ste_vec_index;
END;
$$ LANGUAGE plpgsql;

DROP CAST IF EXISTS (jsonb AS eql_v1.ste_vec_index);

CREATE CAST (jsonb AS eql_v1.ste_vec_index)
	WITH FUNCTION eql_v1.jsonb_to_ste_vec_index(jsonb) AS IMPLICIT;

DROP OPERATOR IF EXISTS @> (eql_v1.ste_vec_index, eql_v1.ste_vec_index);

CREATE OPERATOR @> (
  PROCEDURE="eql_v1.ste_vec_logical_contains",
  LEFTARG=eql_v1.ste_vec_index,
  RIGHTARG=eql_v1.ste_vec_index,
  COMMUTATOR = <@
);

DROP OPERATOR IF EXISTS <@ (eql_v1.ste_vec_index, eql_v1.ste_vec_index);

CREATE OPERATOR <@ (
  PROCEDURE="eql_v1.ste_vec_logical_is_contained",
  LEFTARG=eql_v1.ste_vec_index,
  RIGHTARG=eql_v1.ste_vec_index,
  COMMUTATOR = @>
);
