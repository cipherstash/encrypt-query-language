\set ON_ERROR_STOP on

--
-- Various Helper functions
--



--
-- Creates a table with an encrypted column for testing
--
DROP FUNCTION IF EXISTS create_table_with_encrypted();
CREATE FUNCTION create_table_with_encrypted()
  RETURNS void
AS $$
  BEGIN
    DROP TABLE IF EXISTS encrypted;
    CREATE TABLE encrypted
    (
        id bigint GENERATED ALWAYS AS IDENTITY,
        -- name_encrypted eql_v2_encrypted,
        e eql_v2_encrypted,
        PRIMARY KEY(id)
    );
END;
$$ LANGUAGE plpgsql;

--
-- Creates a table with an encrypted column for testing
--
DROP FUNCTION IF EXISTS truncate_table_with_encrypted();
CREATE FUNCTION truncate_table_with_encrypted()
  RETURNS void
AS $$
  BEGIN
    TRUNCATE encrypted;
  END;
$$ LANGUAGE plpgsql;



DROP FUNCTION IF EXISTS get_numeric_ste_vec_10();
CREATE FUNCTION get_numeric_ste_vec_10()
  RETURNS jsonb
AS $$
  BEGIN
    RETURN '{
      "sv": [
          {
              "b3": "7b4ffe5d60e4e4300dc3e28d9c300c87",
              "c": "mBbLGB9xHAGzLvUj-`@Wmf=IhD87n7r3ir3n!Sk6AKir_YawR=0c>pk(OydB;ntIEXK~c>V&4>)rNkf<JN7fmlO)c^iBv;-X0+3XyK5d`&&I-oeIEOcwPf<3zy",
              "s": "bca213de9ccce676fa849ff9c4807963"
          },
          {
              "c": "mBbLGB9xHAGzLvUj-`@Wmf=Ih7X?t+{4AB8TRzjVbAmVdj@IwROb`M?#2^$q_A|<pB+kc)R6~1aw9|*XYaU?F#=?Vr9{Y~9Wb&ZE",
              "ocv": "af96e1d96a9e8f99169c111add9c8aaaab2af0a738867349",
              "s": "a7cea93975ed8c01f861ccb6bd082784"
          },
          {
              "c": "mBbLGB9xHAGzLvUj-`@Wmf=Ih6yr9Oe`5a2_Z$Yr5@uqJZFdv!-^3skJN7fmlO)c^iBv;-X0+3XyK5d`&&I-oeIEOcwPf<3zy",
              "ocf": "b0c13d4a4a9ffcb2ef853958ffda424567e1a647f6454352363d7119477ba27fb905460bf5a358d7de9a46d356f0f39178132f5cec1d032d0eba2fbbc2378e1e",
              "s": "2517068c0d1f9d4d41d2c666211f785e"
          }
      ]
    }'::jsonb;
  END;
$$ LANGUAGE plpgsql;

-- Test data '{"hello": "world", "n": 20}'

DROP FUNCTION IF EXISTS get_numeric_ste_vec_20();
CREATE FUNCTION get_numeric_ste_vec_20()
  RETURNS jsonb
AS $$
  BEGIN
    RETURN '{
      "sv": [
            {
                "b3": "7b4ffe5d60e4e4300dc3e28d9c300c87",
                "c": "mBbJ`WPCW@ifNK3@++t4I%$E#DC8yBXbTwDs-nff1*Ug?f<icvvAaiqXfmPqD#S)r*2IUxCWIn{^28wV{TP}lqWol}K{;1%c;CDw21Y#EyOWiy884b7XQ@e`zy",
                "s": "bca213de9ccce676fa849ff9c4807963"
            },
            {
                "c": "mBbJ`WPCW@ifNK3@++t4I%$E#7w$X{t!BivNxhStM0A&D#1>F<v=&5Z#31qg7@8@f{A8p-IahCZ-@GLTMm*ZPla;I)FPbE0sY#%~",
                "ocv": "af96e1dabbec581f36d71e3b3dbab85d38ccc3c097f98c45",
                "s": "a7cea93975ed8c01f861ccb6bd082784"
            },
            {
                "c": "mBbJ`WPCW@ifNK3@++t4I%$E#6q#Z1z0`1$sX#Ud75~MsN61uu`otjd{TP}lqWol}K{;1%c;CDw21Y#EyOWiy884b7XQ@e`zy",
                "ocf": "b0c13d4a4a9ffcb2ef853959fad91ee86a25329303d62e384c5007a2840ccb81e09bac960add3469d291a9e2eeb1df3245b62ae7eb28507d32095d2844630352",
                "s": "2517068c0d1f9d4d41d2c666211f785e"
            }
        ]
    }'::jsonb;
  END;
$$ LANGUAGE plpgsql;

--
-- "{\"hello\": \"four\", \"n\": 20, \"a\": [1, 2, 3, 4, 5] }",
--
--
-- $.a
-- -> eql_v2_encrypted[]
-- a [
--    1
-- ]
--

-- ORIGINAL $.a encoding
-- {
--     "b3": "8258356162d2415d55244abf49e40da3",
--     "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR9iI)K4Nzk-ea`~#Lx@wBSDPSmkp-h+tNEHoo@T@#vwh?Ejvk%78G}b+je+xufQA5mSwHSid)iEOkg@>mpuh",
--     "s": "f510853730e1c3dbd31b86963f029dd5"
-- },

DROP FUNCTION IF EXISTS get_array_ste_vec();
CREATE FUNCTION get_array_ste_vec()
  RETURNS jsonb
AS $$
  BEGIN
    RETURN '{
    "sv": [
        {
            "b3": "7b4ffe5d60e4e4300dc3e28d9c300c87",
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FRIg79JJM`MCq+nE0*U^ca-cViL884d-TInfY&E9HW@X>!U&lkYne2!EecKG8xwLYb0X#y7|05rrPvwh?Ejvk%78G}b+je+xufQA5mSwHSid)iEOkg@>mpuh",
            "s": "bca213de9ccce676fa849ff9c4807963"
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6Z{(4c^$CD^7q>z{xl^%5S4=m#2~YM<M@sqoxB-?M`DeE^NN6m0Df6N?oWH#Om&d50PLW^",
            "ocf": "b0c0a7385cb2f7dfe32a2649a9d8294794b8fc05585a240c1315f1e45ee7d9012616db3f01b43fa94351618670a29c24fc75df1392d52764c757b34495888b1c",
            "s": "f510853730e1c3dbd31b86963f029dd5",
            "a": 1
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6O>W7y15TC<^_oBO-6ni$TotY#2~YM<M@sqoxB-?M`DeE^NN6m0Df6N?oWH#Om&d50PLW^",
            "ocf": "b0c13d4a4a9ffcb2ef853868eb0b5bfb4f9321f4e94ea52a407246305f5982a4eb935f48b5c94030e8faa84bc0505075aa40c2dbf8c916183c371b5f110d796e",
            "s": "f510853730e1c3dbd31b86963f029dd5",
            "a": 1
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6I1D+phqU}j#iX1<;Jw*5%P5k#2~YM<M@sqoxB-?M`DeE^NN6m0Df6N?oWH#Om&d50PLW^",
            "ocf": "b0c13d4a4a9ffcb2ef853868ec9146175332740eb29cb6e7676743c9002d0800bcc8a86def024cc965e1a1113f85840f7c048c85d18deebafb1badbd553f49a8",
            "s": "f510853730e1c3dbd31b86963f029dd5",
            "a": 1
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6W-p1W+#!C?F+J)OTGl*bE5q@#2~YM<M@sqoxB-?M`DeE^NN6m0Df6N?oWH#Om&d50PLW^",
            "ocf": "b0c13d4a4a9ffcb2ef85386996861f7f0232e345b1136090999fe886e1e507fc76c7521af695c91e0b4c30b220ea6c0d5c7651f29bd2ec6811f10fc01d454064",
            "s": "f510853730e1c3dbd31b86963f029dd5",
            "a": 1
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6SMb-%jgZ0hcbtWu1s`Ve@lL;#2~YM<M@sqoxB-?M`DeE^NN6m0Df6N?oWH#Om&d50PLW^",
            "ocf": "b0c13d4a4a9ffcb2ef853869968725a730f60abc8fe2140c7355410494567a87a486240dece45e3bb42852945074e36e55dab5fd5cf5cdb325d675d64f0b2719",
            "s": "f510853730e1c3dbd31b86963f029dd5",
            "a": 1
        },

        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6Z{(4c^$CD^7q>z{xl^%5S4=m#2~YM<M@sqoxB-?M`DeE^NN6m0Df6N?oWH#Om&d50PLW^",
            "ocf": "b0c0a7385cb2f7dfe32a2649a9d8294794b8fc05585a240c1315f1e45ee7d9012616db3f01b43fa94351618670a29c24fc75df1392d52764c757b34495888b1c",
            "s": "33743aed3ae636f6bf05cff11ac4b519"
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6O>W7y15TC<^_oBO-6ni$TotY#2~YM<M@sqoxB-?M`DeE^NN6m0Df6N?oWH#Om&d50PLW^",
            "ocf": "b0c13d4a4a9ffcb2ef853868eb0b5bfb4f9321f4e94ea52a407246305f5982a4eb935f48b5c94030e8faa84bc0505075aa40c2dbf8c916183c371b5f110d796e",
            "s": "33743aed3ae636f6bf05cff11ac4b519"
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6I1D+phqU}j#iX1<;Jw*5%P5k#2~YM<M@sqoxB-?M`DeE^NN6m0Df6N?oWH#Om&d50PLW^",
            "ocf": "b0c13d4a4a9ffcb2ef853868ec9146175332740eb29cb6e7676743c9002d0800bcc8a86def024cc965e1a1113f85840f7c048c85d18deebafb1badbd553f49a8",
            "s": "33743aed3ae636f6bf05cff11ac4b519"
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6W-p1W+#!C?F+J)OTGl*bE5q@#2~YM<M@sqoxB-?M`DeE^NN6m0Df6N?oWH#Om&d50PLW^",
            "ocf": "b0c13d4a4a9ffcb2ef85386996861f7f0232e345b1136090999fe886e1e507fc76c7521af695c91e0b4c30b220ea6c0d5c7651f29bd2ec6811f10fc01d454064",
            "s": "33743aed3ae636f6bf05cff11ac4b519"
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6SMb-%jgZ0hcbtWu1s`Ve@lL;#2~YM<M@sqoxB-?M`DeE^NN6m0Df6N?oWH#Om&d50PLW^",
            "ocf": "b0c13d4a4a9ffcb2ef853869968725a730f60abc8fe2140c7355410494567a87a486240dece45e3bb42852945074e36e55dab5fd5cf5cdb325d675d64f0b2719",
            "s": "33743aed3ae636f6bf05cff11ac4b519"
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR7}D3d-^`fltk2Cg%EF6{!Q^!Dq>oG#B*Y-IedG9!9-X`ygGXYGf%A%hh5&w9KkiR^+DvtjvH<L$zy",
            "ocv": "af96e1d969ccd0a03ffe6dfbc7712038903cdc88635994c765b6b7e9a00c0799",
            "s": "a7cea93975ed8c01f861ccb6bd082784"
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6lO>G(8jjwtt=6Wr{!%WJ?vt(v&0~?edG9!9-X`ygGXYGf%A%hh5&w9KkiR^+DvtjvH<L$zy",
            "ocf": "b0c13d4a4a9ffcb2ef853959fad91ee86a25329303d62e384c5007a2840ccb81e09bac960add3469d291a9e2eeb1df3245b62ae7eb28507d32095d2844630352",
            "s": "2517068c0d1f9d4d41d2c666211f785e"
        }
      ]
    }'::jsonb;
  END;
$$ LANGUAGE plpgsql;

-- Test data '{"hello": "world", "n": 30}'
DROP FUNCTION IF EXISTS get_numeric_ste_vec_30();
CREATE FUNCTION get_numeric_ste_vec_30()
  RETURNS jsonb
AS $$
  BEGIN
    -- e->'$.n' -> '2517068c0d1f9d4d41d2c666211f785e'
    -- e->'2517068c0d1f9d4d41d2c666211f785e'
    -- e->>'2517068c0d1f9d4d41d2c666211f785e' ciphertext/c

    RETURN '{
      "sv": [
          {
              "b3": "7b4ffe5d60e4e4300dc3e28d9c300c87",
              "c": "mBbM0#UZON2jQ3@LiWcvns2YfD7#?5ZXlp8Wk1R*iA%o6cD0VZWqPY%l%_z!JC9wAR4?XKSouV_AjBXFod39C7TF-SiCD-NgkG)l%Vw=l!tX>H*P<PfE$+0Szy",
              "s": "bca213de9ccce676fa849ff9c4807963"
          },
          {
              "c": "mBbM0#UZON2jQ3@LiWcvns2Yf7wMQ^;8WN>jq@SFR7iRajU#?{(K%x=#2^Zs|F~fm*&w!wSjZQIUaj-XX01=c??f8cq8*Vf?zEu5",
              "ocv": "af96e1dabbec581f36d71e3a48ffb427f54832851b4fefa6989887ccaf7e038f66f8cb40e6959458",
              "s": "a7cea93975ed8c01f861ccb6bd082784"
          },
          {
              "c": "mBbM0#UZON2jQ3@LiWcvns2Yf6y3L;hykEh`}*fX#aF;n*=>+*o5Uarod39C7TF-SiCD-NgkG)l%Vw=l!tX>H*P<PfE$+0Szy",
              "ocf": "b0c13d4a4a9ffcb2ef853959fb2d26236337244ed86d66470d08963ed703356a1cee600a9a75a70aaefc1b4ca03b7918a7df25b7cd4ca774fd5b8616e6b9adb8",
              "s": "2517068c0d1f9d4d41d2c666211f785e"
          }
      ]
    }'::jsonb;
  END;
$$ LANGUAGE plpgsql;

-- Test data '{"hello": "world", "n": 42}'
DROP FUNCTION IF EXISTS get_numeric_ste_vec_42();
CREATE FUNCTION get_numeric_ste_vec_42()
  RETURNS jsonb
AS $$
  BEGIN
    RETURN '{
      "sv": [
          {
              "c": "mBbK0Cob5dQ5Jki69vRd75f9kDqkudQIbo}$J)f!EYW$7#FJ{kA1^NPL~KtPnCJ^MjEZiv5-P~GgJu!LAm>kiFH&De7C+d}sDugsc?JuI*>$AsG83nsXvrND0-(S",
              "b3": "7b4ffe5d60e4e4300dc3e28d9c300c87",
              "s": "bca213de9ccce676fa849ff9c4807963"
          },
          {
              "c": "mBbK0Cob5dQ5Jki69vRd75f9k8Rn)lVSgZ9Q3jQYu)}sv8};==6AExb8MwqC=TCnxQeQ_FKiJQxgbDw71`CJTb)@Vv6Q`bN$sH2{puh",
              "ocv": "af96e1dabbec5913707844664eb160923982fdec75bda4bcd063e26b4254a9f334ce7ebc2612713c",
              "s": "a7cea93975ed8c01f861ccb6bd082784"
          },
          {
              "c": "mBbK0Cob5dQ5Jki69vRd75f9k6yc;BV`COqamPOX6P`g5TMr)AeZ(N=Pk%%2`Uq=={*w3hh3IBNp3y0Ztr0g;ir=DoZ9TNhezy",
              "ocf": "b0c13d4a4a9ffcb2ef8629d60d5e32db453fad8792b2450d02f37ec5fe207b42da30093fd14c4975c9b192ecbf939b2d5a56a7ae2db1254e6532aa7569971462",
              "s": "2517068c0d1f9d4d41d2c666211f785e"
          }
      ]
    }'::jsonb;
  END;
$$ LANGUAGE plpgsql;


-- --
-- --
--
-- Creates a table with an encrypted column for testing
--
-- JSON -- '{"hello": "world", "n": 42}'
--
-- Paths
-- $       -> bca213de9ccce676fa849ff9c4807963
-- $.hello -> a7cea93975ed8c01f861ccb6bd082784
-- $.n     -> 2517068c0d1f9d4d41d2c666211f785e
--
-- --
-- --
DROP FUNCTION IF EXISTS create_encrypted_json(integer);
CREATE FUNCTION create_encrypted_json(id integer)
  RETURNS eql_v2_encrypted
AS $$
  DECLARE
    s text;
    m jsonb;
    start integer;
    stop integer;
    random_key text;
    random_val text;
    sv jsonb;
    ore_term jsonb;
  BEGIN

    start := (10 * id);
    stop := (10 * id) + 5;
    m := array_to_json(array(SELECT generate_series(start, stop)));

    select substr(md5(random()::text), 1, 25) INTO random_key;
    select substr(md5(random()::text), 1, 25) INTO random_val;

    CASE id
        WHEN 1 THEN
          sv := get_numeric_ste_vec_10();
        WHEN 2 THEN
          sv := get_numeric_ste_vec_20();
        WHEN 3 THEN
          sv := get_numeric_ste_vec_30();
        ELSE
          sv := get_numeric_ste_vec_42();
    END CASE;


    SELECT ore.e FROM ore WHERE ore.id = start INTO ore_term;

    -- PERFORM eql_v2.log('ore_term: ', ore_term::text);

    s := format(
      '{
          "%s": "%s",
          "c": "ciphertext",
          "i": {
              "t": "encrypted",
              "c": "e"
          },
          "u": "unique.%s",
          "b3": "blake3.%s",
          "bf": %s
        }',
        random_key,
        random_val,
        id, id, m);

    s := s::jsonb || sv || ore_term;

    -- PERFORM eql_v2.log('json: %', s);

    RETURN s::eql_v2_encrypted;
  END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS create_encrypted_json(integer, VARIADIC indexes text[]);
CREATE FUNCTION create_encrypted_json(id integer, VARIADIC indexes text[])
  RETURNS eql_v2_encrypted
AS $$
  DECLARE
    j jsonb;
  BEGIN
    j := create_encrypted_json(id);

    j := (
        SELECT jsonb_object_agg(key, value)
        FROM jsonb_each(j)
        WHERE key = ANY(indexes)
      );

    RETURN j::eql_v2_encrypted;

  END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS create_encrypted_json(VARIADIC indexes text[]);
CREATE FUNCTION create_encrypted_json(VARIADIC indexes text[])
  RETURNS eql_v2_encrypted
AS $$
 DECLARE
    default_indexes text[];
    j jsonb;
  BEGIN

    default_indexes := ARRAY['c', 'i', 'v'];

    j := create_encrypted_json(1);

    j := (
        SELECT jsonb_object_agg(key, value)
        FROM jsonb_each(j)
        WHERE key = ANY(indexes || default_indexes)
      );

    RETURN j::eql_v2_encrypted;

  END;
$$ LANGUAGE plpgsql;



DROP FUNCTION IF EXISTS create_encrypted_ore_json(val integer);
CREATE FUNCTION create_encrypted_ore_json(val integer)
  RETURNS eql_v2_encrypted
AS $$
 DECLARE
    e eql_v2_encrypted;
    ore_term jsonb;
  BEGIN
    EXECUTE format('SELECT ore.e FROM ore WHERE id = %s', val) INTO ore_term;
    e := create_encrypted_json('o')::jsonb || ore_term;
    RETURN e::eql_v2_encrypted;
  END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS create_encrypted_json();
CREATE FUNCTION create_encrypted_json()
  RETURNS eql_v2_encrypted
AS $$
 DECLARE
    id integer;
    j jsonb;
  BEGIN
    id := trunc(random() * 1000 + 1);
    j := create_encrypted_json(id);
    RETURN j::eql_v2_encrypted;
  END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS seed_encrypted(eql_v2_encrypted);
CREATE FUNCTION seed_encrypted(e eql_v2_encrypted)
  RETURNS void
AS $$
  BEGIN
    INSERT INTO encrypted (e) VALUES (e);
  END;
$$ LANGUAGE plpgsql;


--
-- Truncates and creates base test data
--
DROP FUNCTION IF EXISTS seed_encrypted_json();
CREATE FUNCTION seed_encrypted_json()
  RETURNS void
AS $$
  BEGIN
    PERFORM truncate_table_with_encrypted();
    PERFORM seed_encrypted(create_encrypted_json(1));
    PERFORM seed_encrypted(create_encrypted_json(2));
    PERFORM seed_encrypted(create_encrypted_json(3));
  END;
$$ LANGUAGE plpgsql;


--
-- Creates a table with an encrypted column for testing
--
DROP FUNCTION IF EXISTS drop_table_with_encrypted();
CREATE FUNCTION drop_table_with_encrypted()
  RETURNS void
AS $$
  BEGIN
    DROP TABLE IF EXISTS encrypted;
END;
$$ LANGUAGE plpgsql;


--
-- Convenience function to describe a test
--
DROP FUNCTION IF EXISTS describe(text);
CREATE FUNCTION describe(s text)
    RETURNS void
AS $$
  BEGIN
    RAISE NOTICE '%', s;
END;
$$ LANGUAGE plpgsql;


--
-- Assert the the provided SQL statement returns a non-null result
--
DROP FUNCTION IF EXISTS assert_result(describe text, sql text);

CREATE FUNCTION assert_result(describe text, sql text)
  RETURNS void
AS $$
  DECLARE
    result record;
	BEGIN
    RAISE NOTICE '%', describe;
    EXECUTE sql into result;

    if result IS NULL THEN
      RAISE NOTICE 'ASSERT RESULT FAILED';
      RAISE NOTICE '%', regexp_replace(sql, '^\s+|\s*$', '', 'g');
      ASSERT false;
    END IF;

	END;
$$ LANGUAGE plpgsql;


--
-- Assert the the provided SQL statement returns a non-null result
--
DROP FUNCTION IF EXISTS assert_result(describe text, sql text, result text);

CREATE FUNCTION assert_result(describe text, sql text, expected text)
  RETURNS void
AS $$
  DECLARE
    result text;
	BEGIN
    RAISE NOTICE '%', describe;
    EXECUTE sql into result;

    if result <> expected THEN
      RAISE NOTICE 'ASSERT EXPECTED RESULT FAILED';
      RAISE NOTICE 'Expected: %', expected;
      RAISE NOTICE 'Result: %', result;
      RAISE NOTICE '%', regexp_replace(sql, '^\s+|\s*$', '', 'g');
      ASSERT false;
    END IF;

	END;
$$ LANGUAGE plpgsql;

--
-- Assert the the provided SQL statement returns a non-null result
--
DROP FUNCTION IF EXISTS assert_id(describe text, sql text, id integer);

CREATE FUNCTION assert_id(describe text, sql text, id integer)
  RETURNS void
AS $$
  DECLARE
    result_id integer;
	BEGIN
    RAISE NOTICE '%', describe;
    EXECUTE sql into result_id;

    IF result_id <> id THEN
      RAISE NOTICE 'ASSERT ID FAILED';
      RAISE NOTICE 'Expected row with id % but returned %', id, result_id;
      RAISE NOTICE '%', regexp_replace(sql, '^\s+|\s*$', '', 'g');
      ASSERT false;
    END IF;

	END;
$$ LANGUAGE plpgsql;


--
-- Assert the the provided SQL statement returns a non-null result
--
DROP FUNCTION IF EXISTS assert_no_result(describe text, sql text);

CREATE FUNCTION assert_no_result(describe text, sql text)
  RETURNS void
AS $$
  DECLARE
    result record;
	BEGIN
    RAISE NOTICE '%', describe;
    EXECUTE sql into result;

    IF result IS NOT NULL THEN
      RAISE NOTICE 'ASSERT NO RESULT FAILED';
      RAISE NOTICE '%', regexp_replace(sql, '^\s+|\s*$', '', 'g');
      ASSERT false;
    END IF;

	END;
$$ LANGUAGE plpgsql;



--
-- Assert the the provided SQL statement returns a non-null result
--
DROP FUNCTION IF EXISTS assert_count(describe text, sql text, expected integer);

CREATE FUNCTION assert_count(describe text, sql text, expected integer)
  RETURNS void
AS $$
  DECLARE
    result integer;
	BEGIN
    RAISE NOTICE '%', describe;

    -- Remove any trailing ; so that the query can be wrapped with count(*) below
    sql := TRIM(TRAILING ';' FROM sql);

    EXECUTE format('SELECT COUNT(*) FROM (%s) as q', sql) INTO result;

    if result <> expected THEN
      RAISE NOTICE 'ASSERT COUNT FAILED';
      RAISE NOTICE 'Expected % rows and returned %', expected, result;
      RAISE NOTICE '%', regexp_replace(sql, '^\s+|\s*$', '', 'g');
      ASSERT false;
    END IF;

	END;
$$ LANGUAGE plpgsql;



--
-- Assert the the provided SQL statement raises an exception
--
DROP FUNCTION IF EXISTS assert_exception(describe text, sql text);

CREATE FUNCTION assert_exception(describe text, sql text)
  RETURNS void
AS $$
	BEGIN
    RAISE NOTICE '%', describe;

    BEGIN
      EXECUTE sql;
      RAISE NOTICE 'ASSERT EXCEPTION FAILED';
      RAISE NOTICE 'EXPECTED STATEMENT TO RAISE EXCEPTION';
      RAISE NOTICE '%', regexp_replace(sql, '^\s+|\s*$', '', 'g');
      ASSERT false;
    EXCEPTION
      WHEN OTHERS THEN
        ASSERT true;
    END;

	END;
$$ LANGUAGE plpgsql;
