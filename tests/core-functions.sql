\set ON_ERROR_STOP on


DO $$
  BEGIN
    ASSERT (SELECT EXISTS (SELECT cs_unique_v1('{"u": "u"}'::jsonb)));
    ASSERT (SELECT EXISTS (SELECT cs_match_v1('{"m": []}'::jsonb)));
  END;
$$ LANGUAGE plpgsql;

DO $$
  BEGIN
    -- sanity check
    PERFORM cs_unique_v1('{"u": "u"}'::jsonb);

    BEGIN
      PERFORM cs_unique_v1_v0('{}'::jsonb);
      RAISE NOTICE 'Missing index. Function call should have failed.';
      ASSERT false;
    EXCEPTION
      WHEN OTHERS THEN
        ASSERT true;
    END;
  END;
$$ LANGUAGE plpgsql;


DO $$
  BEGIN
    -- sanity check
    PERFORM cs_match_v1('{"m": []}'::jsonb);

    BEGIN
      PERFORM cs_match_v1('{}'::jsonb);
      RAISE NOTICE 'Missing index. Function call should have failed.';
      ASSERT false;
    EXCEPTION
      WHEN OTHERS THEN
        ASSERT true;
    END;
  END;
$$ LANGUAGE plpgsql;

