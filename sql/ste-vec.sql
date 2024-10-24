
---
--- SteVec types, functions, and operators
---

CREATE TYPE ste_vec_v1_entry AS (
    tokenized_selector text,
    term ore_cllw_8_v1,
    ciphertext text
);

CREATE TYPE cs_ste_vec_index_v1 AS (
    entries ste_vec_v1_entry[]
);

-- Determine if a == b (ignoring ciphertext values)
CREATE OR REPLACE FUNCTION ste_vec_v1_entry_eq(a ste_vec_v1_entry, b ste_vec_v1_entry)
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
CREATE OR REPLACE FUNCTION ste_vec_v1_logical_contains(a cs_ste_vec_index_v1, b cs_ste_vec_index_v1)
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
        intermediate_result := ste_vec_v1_entry_array_contains_entry(a.entries, b.entries[i]);
        result := result AND intermediate_result;
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Determine if a contains b (ignoring ciphertext values)
CREATE OR REPLACE FUNCTION ste_vec_v1_entry_array_contains_entry(a ste_vec_v1_entry[], b ste_vec_v1_entry)
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
CREATE OR REPLACE FUNCTION ste_vec_v1_logical_is_contained(a cs_ste_vec_index_v1, b cs_ste_vec_index_v1)
RETURNS boolean AS $$
BEGIN
    RETURN ste_vec_v1_logical_contains(b, a);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION jsonb_to_cs_ste_vec_index_v1(input jsonb)
RETURNS cs_ste_vec_index_v1 AS $$
DECLARE
    vec_entry ste_vec_v1_entry;
    entry_array ste_vec_v1_entry[];
    entry_json jsonb;
    entry_json_array jsonb[];
    entry_array_length int;
    i int;
BEGIN
    FOR entry_json IN SELECT * FROM jsonb_array_elements(input)
    LOOP
        vec_entry := ROW(
           entry_json->>0,
           ROW((entry_json->>1)::bytea)::ore_cllw_8_v1,
           entry_json->>2
        )::ste_vec_v1_entry;
        entry_array := array_append(entry_array, vec_entry);
    END LOOP;

    RETURN ROW(entry_array)::cs_ste_vec_index_v1;
END;
$$ LANGUAGE plpgsql;

CREATE CAST (jsonb AS cs_ste_vec_index_v1)
	WITH FUNCTION jsonb_to_cs_ste_vec_index_v1(jsonb) AS IMPLICIT;

CREATE OPERATOR @> (
  PROCEDURE="ste_vec_v1_logical_contains",
  LEFTARG=cs_ste_vec_index_v1,
  RIGHTARG=cs_ste_vec_index_v1,
  COMMUTATOR = <@
);

CREATE OPERATOR <@ (
  PROCEDURE="ste_vec_v1_logical_is_contained",
  LEFTARG=cs_ste_vec_index_v1,
  RIGHTARG=cs_ste_vec_index_v1,
  COMMUTATOR = @>
);
