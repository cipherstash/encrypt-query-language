\set ON_ERROR_STOP on


DO $$
  BEGIN
    ASSERT (SELECT EXISTS (SELECT eql_v1.unique('{"u": "u"}'::jsonb)));
    ASSERT (SELECT EXISTS (SELECT eql_v1.match('{"m": []}'::jsonb)));
    ASSERT (SELECT EXISTS (SELECT eql_v1.ste_vec('{"sv": [[]]}'::jsonb)));
    ASSERT (SELECT EXISTS (SELECT eql_v1.ore_64_8_v1('{"o": []}'::jsonb)));

  END;
$$ LANGUAGE plpgsql;

DO $$
  BEGIN
    -- sanity check
    PERFORM eql_v1.ore_64_8_v1('{"o": []}'::jsonb);

    BEGIN
      PERFORM eql_v1.ore_64_8_v1('{}'::jsonb);
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
    PERFORM eql_v1.ste_vec('{"sv": [[]] }'::jsonb);

    BEGIN
      PERFORM eql_v1.ste_vec('{}'::jsonb);
      RAISE NOTICE 'Missing index. Function call should have failed.';
      ASSERT false;
    EXCEPTION
      WHEN OTHERS THEN
        ASSERT true;
    END;
  END;
$$ LANGUAGE plpgsql;


-- DO $$
--   BEGIN
--     -- sanity check
--     PERFORM eql_v1.unique('{"u": "u"}'::jsonb);

--     BEGIN
--       PERFORM eql_v1.unique_v1('{}'::jsonb);
--       RAISE NOTICE 'Missing index. Function call should have failed.';
--       ASSERT false;
--     EXCEPTION
--       WHEN OTHERS THEN
--         ASSERT true;
--     END;
--   END;
-- $$ LANGUAGE plpgsql;


-- DO $$
--   BEGIN
--     -- sanity check
--     PERFORM eql_v1.match('{"m": []}'::jsonb);

--     BEGIN
--       PERFORM eql_v1.match('{}'::jsonb);
--       RAISE NOTICE 'Missing index. Function call should have failed.';
--       ASSERT false;
--     EXCEPTION
--       WHEN OTHERS THEN
--         ASSERT true;
--     END;
--   END;
-- $$ LANGUAGE plpgsql;
