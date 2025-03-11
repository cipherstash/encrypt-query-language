
---
--- SteVec types, functions, and operators
---

CREATE TYPE cs_ste_vec_encrypted_term_v1 AS (
  bytes bytea
);

DROP FUNCTION IF EXISTS compare_ste_vec_encrypted_term_v1(a cs_ste_vec_encrypted_term_v1, b cs_ste_vec_encrypted_term_v1);

CREATE FUNCTION compare_ste_vec_encrypted_term_v1(a cs_ste_vec_encrypted_term_v1, b cs_ste_vec_encrypted_term_v1)
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
    RAISE EXCEPTION 'compare_ste_vec_encrypted_term_v1: expected equal header bytes';
  END IF;

  -- `substr` is 1-indexed (yes, `subtr` starts at 1 and `get_byte` starts at 0).
  body_a := substr(a.bytes, 2);
  body_b := substr(b.bytes, 2);

  CASE header_a
    WHEN 0 THEN
      RAISE EXCEPTION 'compare_ste_vec_encrypted_term_v1: can not compare MAC terms';
    WHEN 1 THEN
      RETURN compare_ore_cllw_8_v1(ROW(body_a)::ore_cllw_8_v1, ROW(body_b)::ore_cllw_8_v1);
    WHEN 2 THEN
      RETURN compare_lex_ore_cllw_8_v1(ROW(body_a)::ore_cllw_8_variable_v1, ROW(body_b)::ore_cllw_8_variable_v1);
    ELSE
      RAISE EXCEPTION 'compare_ste_vec_encrypted_term_v1: invalid header for cs_ste_vec_encrypted_term_v1: header "%", body "%', header_a, body_a;
  END CASE;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS cs_ste_vec_encrypted_term_eq(a cs_ste_vec_encrypted_term_v1, b cs_ste_vec_encrypted_term_v1);

CREATE FUNCTION cs_ste_vec_encrypted_term_eq(a cs_ste_vec_encrypted_term_v1, b cs_ste_vec_encrypted_term_v1) RETURNS boolean AS $$
  SELECT __bytea_ct_eq(a.bytes, b.bytes)
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS cs_ste_vec_encrypted_term_neq(a cs_ste_vec_encrypted_term_v1, b cs_ste_vec_encrypted_term_v1);

CREATE FUNCTION cs_ste_vec_encrypted_term_neq(a cs_ste_vec_encrypted_term_v1, b cs_ste_vec_encrypted_term_v1) RETURNS boolean AS $$
  SELECT not __bytea_ct_eq(a.bytes, b.bytes)
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS cs_ste_vec_encrypted_term_lt(a cs_ste_vec_encrypted_term_v1, b cs_ste_vec_encrypted_term_v1);

CREATE FUNCTION cs_ste_vec_encrypted_term_lt(a cs_ste_vec_encrypted_term_v1, b cs_ste_vec_encrypted_term_v1) RETURNS boolean AS $$
  SELECT compare_ste_vec_encrypted_term_v1(a, b) = -1
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS cs_ste_vec_encrypted_term_lte(a cs_ste_vec_encrypted_term_v1, b cs_ste_vec_encrypted_term_v1);

CREATE FUNCTION cs_ste_vec_encrypted_term_lte(a cs_ste_vec_encrypted_term_v1, b cs_ste_vec_encrypted_term_v1) RETURNS boolean AS $$
  SELECT compare_ste_vec_encrypted_term_v1(a, b) != 1
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS cs_ste_vec_encrypted_term_gt(a cs_ste_vec_encrypted_term_v1, b cs_ste_vec_encrypted_term_v1);

CREATE FUNCTION cs_ste_vec_encrypted_term_gt(a cs_ste_vec_encrypted_term_v1, b cs_ste_vec_encrypted_term_v1) RETURNS boolean AS $$
  SELECT compare_ste_vec_encrypted_term_v1(a, b) = 1
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS cs_ste_vec_encrypted_term_gte(a cs_ste_vec_encrypted_term_v1, b cs_ste_vec_encrypted_term_v1);

CREATE FUNCTION cs_ste_vec_encrypted_term_gte(a cs_ste_vec_encrypted_term_v1, b cs_ste_vec_encrypted_term_v1) RETURNS boolean AS $$
  SELECT compare_ste_vec_encrypted_term_v1(a, b) != -1
$$ LANGUAGE SQL;

DROP OPERATOR IF EXISTS = (cs_ste_vec_encrypted_term_v1, cs_ste_vec_encrypted_term_v1);

CREATE OPERATOR = (
  PROCEDURE="cs_ste_vec_encrypted_term_eq",
  LEFTARG=cs_ste_vec_encrypted_term_v1,
  RIGHTARG=cs_ste_vec_encrypted_term_v1,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS <> (cs_ste_vec_encrypted_term_v1, cs_ste_vec_encrypted_term_v1);

CREATE OPERATOR <> (
  PROCEDURE="cs_ste_vec_encrypted_term_neq",
  LEFTARG=cs_ste_vec_encrypted_term_v1,
  RIGHTARG=cs_ste_vec_encrypted_term_v1,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS > (cs_ste_vec_encrypted_term_v1, cs_ste_vec_encrypted_term_v1);

CREATE OPERATOR > (
  PROCEDURE="cs_ste_vec_encrypted_term_gt",
  LEFTARG=cs_ste_vec_encrypted_term_v1,
  RIGHTARG=cs_ste_vec_encrypted_term_v1,
  NEGATOR = <=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS < (cs_ste_vec_encrypted_term_v1, cs_ste_vec_encrypted_term_v1);

CREATE OPERATOR < (
  PROCEDURE="cs_ste_vec_encrypted_term_lt",
  LEFTARG=cs_ste_vec_encrypted_term_v1,
  RIGHTARG=cs_ste_vec_encrypted_term_v1,
  NEGATOR = >=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS >= (cs_ste_vec_encrypted_term_v1, cs_ste_vec_encrypted_term_v1);

CREATE OPERATOR >= (
  PROCEDURE="cs_ste_vec_encrypted_term_gte",
  LEFTARG=cs_ste_vec_encrypted_term_v1,
  RIGHTARG=cs_ste_vec_encrypted_term_v1,
  NEGATOR = <,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS <= (cs_ste_vec_encrypted_term_v1, cs_ste_vec_encrypted_term_v1);

CREATE OPERATOR <= (
  PROCEDURE="cs_ste_vec_encrypted_term_lte",
  LEFTARG=cs_ste_vec_encrypted_term_v1,
  RIGHTARG=cs_ste_vec_encrypted_term_v1,
  NEGATOR = >,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR FAMILY IF EXISTS cs_ste_vec_encrypted_term_v1_btree_ops USING btree;

CREATE OPERATOR FAMILY cs_ste_vec_encrypted_term_v1_btree_ops USING btree;

DROP OPERATOR CLASS IF EXISTS cs_ste_vec_encrypted_term_v1_btree_ops USING btree;

CREATE OPERATOR CLASS cs_ste_vec_encrypted_term_v1_btree_ops DEFAULT FOR TYPE cs_ste_vec_encrypted_term_v1 USING btree FAMILY cs_ste_vec_encrypted_term_v1_btree_ops  AS
        OPERATOR 1 <,
        OPERATOR 2 <=,
        OPERATOR 3 =,
        OPERATOR 4 >=,
        OPERATOR 5 >,
        FUNCTION 1 compare_ste_vec_encrypted_term_v1(a cs_ste_vec_encrypted_term_v1, b cs_ste_vec_encrypted_term_v1);

CREATE TYPE cs_ste_vec_v1_entry AS (
    tokenized_selector text,
    term cs_ste_vec_encrypted_term_v1,
    ciphertext text
);

CREATE TYPE cs_ste_vec_index_v1 AS (
    entries cs_ste_vec_v1_entry[]
);

DROP FUNCTION IF EXISTS cs_ste_vec_value_v1(col jsonb, selector jsonb);

-- col: already encrypted payload
-- selector: already encrypted payload
-- returns a value in the format of our custom jsonb schema that will be decrypted
CREATE FUNCTION cs_ste_vec_value_v1(col jsonb, selector jsonb)
RETURNS jsonb AS $$
DECLARE
  ste_vec_index cs_ste_vec_index_v1;
  target_selector text;
  found text;
  ignored text;
  i integer;
BEGIN
  ste_vec_index := cs_ste_vec_v1(col);

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

DROP FUNCTION IF EXISTS cs_ste_vec_terms_v1(col jsonb, selector jsonb);

CREATE FUNCTION cs_ste_vec_terms_v1(col jsonb, selector jsonb)
RETURNS cs_ste_vec_encrypted_term_v1[] AS $$
DECLARE
  ste_vec_index cs_ste_vec_index_v1;
  target_selector text;
  found cs_ste_vec_encrypted_term_v1;
  ignored cs_ste_vec_encrypted_term_v1;
  i integer;
  term_array cs_ste_vec_encrypted_term_v1[];
BEGIN
  ste_vec_index := cs_ste_vec_v1(col);

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

DROP FUNCTION IF EXISTS cs_ste_vec_term_v1(col jsonb, selector jsonb);

-- col: already encrypted payload
-- selector: already encrypted payload
-- returns a value that can be used for comparison operations
CREATE OR REPLACE FUNCTION cs_ste_vec_term_v1(col jsonb, selector jsonb)
RETURNS cs_ste_vec_encrypted_term_v1 AS $$
DECLARE
  ste_vec_index cs_ste_vec_index_v1;
  target_selector text;
  found cs_ste_vec_encrypted_term_v1;
  ignored cs_ste_vec_encrypted_term_v1;
  i integer;
BEGIN
  ste_vec_index := cs_ste_vec_v1(col);

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

DROP FUNCTION IF EXISTS cs_ste_vec_term_v1(col jsonb);

CREATE FUNCTION cs_ste_vec_term_v1(col jsonb)
RETURNS cs_ste_vec_encrypted_term_v1 AS $$
DECLARE
  ste_vec_index cs_ste_vec_index_v1;
BEGIN
  ste_vec_index := cs_ste_vec_v1(col);

  IF ste_vec_index IS NULL THEN
    RETURN NULL;
  END IF;

  RETURN ste_vec_index.entries[1].term;
END;
$$ LANGUAGE plpgsql;

-- Determine if a == b (ignoring ciphertext values)
DROP FUNCTION IF EXISTS cs_ste_vec_v1_entry_eq(a cs_ste_vec_v1_entry, b cs_ste_vec_v1_entry);

CREATE FUNCTION cs_ste_vec_v1_entry_eq(a cs_ste_vec_v1_entry, b cs_ste_vec_v1_entry)
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
DROP FUNCTION IF EXISTS ste_vec_v1_logical_contains(a cs_ste_vec_index_v1, b cs_ste_vec_index_v1);

CREATE FUNCTION ste_vec_v1_logical_contains(a cs_ste_vec_index_v1, b cs_ste_vec_index_v1)
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
        intermediate_result := cs_ste_vec_v1_entry_array_contains_entry(a.entries, b.entries[i]);
        result := result AND intermediate_result;
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Determine if a contains b (ignoring ciphertext values)
DROP FUNCTION IF EXISTS cs_ste_vec_v1_entry_array_contains_entry(a cs_ste_vec_v1_entry[], b cs_ste_vec_v1_entry);

CREATE FUNCTION cs_ste_vec_v1_entry_array_contains_entry(a cs_ste_vec_v1_entry[], b cs_ste_vec_v1_entry)
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
DROP FUNCTION IF EXISTS ste_vec_v1_logical_is_contained(a cs_ste_vec_index_v1, b cs_ste_vec_index_v1);

CREATE FUNCTION ste_vec_v1_logical_is_contained(a cs_ste_vec_index_v1, b cs_ste_vec_index_v1)
RETURNS boolean AS $$
BEGIN
    RETURN ste_vec_v1_logical_contains(b, a);
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS jsonb_to_cs_ste_vec_index_v1(input jsonb);

CREATE FUNCTION jsonb_to_cs_ste_vec_index_v1(input jsonb)
RETURNS cs_ste_vec_index_v1 AS $$
DECLARE
    vec_entry cs_ste_vec_v1_entry;
    entry_array cs_ste_vec_v1_entry[];
    entry_json jsonb;
    entry_json_array jsonb[];
    entry_array_length int;
    i int;
BEGIN
    FOR entry_json IN SELECT * FROM jsonb_array_elements(input)
    LOOP
        vec_entry := ROW(
           entry_json->>0,
           ROW(decode(entry_json->>1, 'hex'))::cs_ste_vec_encrypted_term_v1,
           entry_json->>2
        )::cs_ste_vec_v1_entry;
        entry_array := array_append(entry_array, vec_entry);
    END LOOP;

    RETURN ROW(entry_array)::cs_ste_vec_index_v1;
END;
$$ LANGUAGE plpgsql;

DROP CAST IF EXISTS (jsonb AS cs_ste_vec_index_v1);

CREATE CAST (jsonb AS cs_ste_vec_index_v1)
	WITH FUNCTION jsonb_to_cs_ste_vec_index_v1(jsonb) AS IMPLICIT;

DROP OPERATOR IF EXISTS @> (cs_ste_vec_index_v1, cs_ste_vec_index_v1);

CREATE OPERATOR @> (
  PROCEDURE="ste_vec_v1_logical_contains",
  LEFTARG=cs_ste_vec_index_v1,
  RIGHTARG=cs_ste_vec_index_v1,
  COMMUTATOR = <@
);

DROP OPERATOR IF EXISTS <@ (cs_ste_vec_index_v1, cs_ste_vec_index_v1);

CREATE OPERATOR <@ (
  PROCEDURE="ste_vec_v1_logical_is_contained",
  LEFTARG=cs_ste_vec_index_v1,
  RIGHTARG=cs_ste_vec_index_v1,
  COMMUTATOR = @>
);
