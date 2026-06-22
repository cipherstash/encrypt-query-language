-- NOT A BUILD FILE: matched by the `*_test.sql` build-glob exclusion.
-- Run against a DB with the combined release installed:
--   psql "$CONN" -v ON_ERROR_STOP=1 -f src/v3/jsonb/jsonb_test.sql

DO $$
DECLARE
  doc eql_v3.json;
  needle eql_v3.json;
  entry_a eql_v3.ste_vec_entry;
  entry_b eql_v3.ste_vec_entry;
  entry_count integer;
  raised boolean;
BEGIN
  -- A two-element sv document: one hm leaf, one oc leaf.
  doc := '{
    "i": {"c": "col", "t": "encrypted"}, "v": 2, "sv": [
      {"s": "sel_hm", "c": "ct1", "hm": "8067db44a848ab32c3056a3dbe4edf16"},
      {"s": "sel_oc", "c": "ct2", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cad9eda1b"}
    ]
  }'::eql_v3.json;

  -- domain CHECK: missing envelope keys must reject.
  BEGIN
    raised := false;
    PERFORM '{"sv": []}'::eql_v3.json;
  EXCEPTION WHEN check_violation THEN raised := true;
  END;
  IF NOT raised THEN RAISE EXCEPTION 'eql_v3.json accepted a payload missing v/i'; END IF;

  -- domain CHECK: wrong envelope version must reject.
  BEGIN
    raised := false;
    PERFORM '{"i":{},"v":3,"sv":[]}'::eql_v3.json;
  EXCEPTION WHEN check_violation THEN raised := true;
  END;
  IF NOT raised THEN RAISE EXCEPTION 'eql_v3.json accepted an envelope with v != 2'; END IF;

  -- ste_vec_entry CHECK: both hm and oc must reject.
  BEGIN
    raised := false;
    PERFORM '{"s":"x","c":"y","hm":"aa","oc":"bb"}'::eql_v3.ste_vec_entry;
  EXCEPTION WHEN check_violation THEN raised := true;
  END;
  IF NOT raised THEN RAISE EXCEPTION 'ste_vec_entry accepted both hm and oc'; END IF;

  -- -> extracts an entry by selector. NOTE: the selector literal MUST be typed
  -- (`::text`). A bare untyped literal (`doc -> 'sel_hm'`) resolves to the native
  -- `jsonb -> text` operator because PostgreSQL reduces the `eql_v3.json` domain to
  -- its base type during operator resolution of an unknown-typed RHS — see the
  -- "Typed operands" caveat in docs/reference/json-support.md. Typed operands (the
  -- Proxy interface) always resolve to our operator.
  entry_a := doc -> 'sel_hm'::text;
  IF eql_v3.selector(entry_a) <> 'sel_hm' THEN RAISE EXCEPTION '-> selector mismatch'; END IF;

  -- ->> returns text (selector typed for the same reason as above).
  IF (doc ->> 'sel_hm'::text) IS NULL THEN RAISE EXCEPTION '->> returned NULL'; END IF;

  -- path/array functions return ste_vec_entry values, not eql_v3.json documents.
  SELECT count(*) INTO entry_count FROM eql_v3.jsonb_path_query(doc::jsonb, 'sel_hm') AS e;
  IF entry_count <> 1 THEN RAISE EXCEPTION 'jsonb_path_query did not return one matching entry'; END IF;

  entry_b := eql_v3.jsonb_path_query_first(doc::jsonb, 'sel_hm');
  IF eql_v3.selector(entry_b) <> 'sel_hm' THEN RAISE EXCEPTION 'jsonb_path_query_first selector mismatch'; END IF;

  SELECT count(*) INTO entry_count
  FROM eql_v3.jsonb_array_elements(
    '{"i":{},"v":2,"a":true,"sv":[{"s":"aa","c":"x","hm":"00"},{"s":"bb","c":"y","hm":"11"}]}'::eql_v3.json::jsonb
  ) AS e;
  IF entry_count <> 2 THEN RAISE EXCEPTION 'jsonb_array_elements did not return two entries'; END IF;

  -- entry equality across hm leaves (same hm in needle).
  entry_b := '{"s":"sel_hm","c":"other","hm":"8067db44a848ab32c3056a3dbe4edf16"}'::eql_v3.ste_vec_entry;
  IF NOT (entry_a = entry_b) THEN RAISE EXCEPTION 'eq_term equality failed for hm leaf'; END IF;

  -- ordered comparison on oc leaves: a smaller oc < a larger oc.
  IF NOT (
    '{"s":"o","c":"x","oc":"fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cad9eda1b"}'::eql_v3.ste_vec_entry
    <
    '{"s":"o","c":"x","oc":"fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cad9edbca"}'::eql_v3.ste_vec_entry
  ) THEN RAISE EXCEPTION 'ordered < on oc leaves failed'; END IF;

  -- containment: doc contains itself.
  needle := doc;
  IF NOT (doc @> needle) THEN RAISE EXCEPTION '@> self-containment failed'; END IF;

  -- each blocked operator raises. Operands are typed so resolution reaches our
  -- blocker rather than native jsonb (see the -> note above): `'sel_hm'::text`,
  -- `ARRAY[...]::text[]`, `'{}'::jsonb`.
  raised := false;
  BEGIN PERFORM doc ? 'sel_hm'::text; EXCEPTION WHEN OTHERS THEN raised := true; END;
  IF NOT raised THEN RAISE EXCEPTION 'blocker ? did not raise'; END IF;

  raised := false;
  BEGIN PERFORM doc #> ARRAY['sel_hm']; EXCEPTION WHEN OTHERS THEN raised := true; END;
  IF NOT raised THEN RAISE EXCEPTION 'blocker #> did not raise'; END IF;

  raised := false;
  BEGIN PERFORM doc || '{}'::jsonb; EXCEPTION WHEN OTHERS THEN raised := true; END;
  IF NOT raised THEN RAISE EXCEPTION 'blocker || did not raise'; END IF;

  RAISE NOTICE 'v3 jsonb smoke OK';
END;
$$;
