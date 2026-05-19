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
              "oc": "af96e1d96a9e8f99169c111add9c8aaaab2af0a738867349",
              "s": "a7cea93975ed8c01f861ccb6bd082784"
          },
          {
              "c": "mBbLGB9xHAGzLvUj-`@Wmf=Ih6yr9Oe`5a2_Z$Yr5@uqJZFdv!-^3skJN7fmlO)c^iBv;-X0+3XyK5d`&&I-oeIEOcwPf<3zy",
              "oc": "b0c13d4a4a9ffcb2ef853958ffda424567e1a647f6454352363d7119477ba27fb905460bf5a358d7de9a46d356f0f39178132f5cec1d032d0eba2fbbc2378e1e",
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
                "oc": "af96e1dabbec581f36d71e3b3dbab85d38ccc3c097f98c45",
                "s": "a7cea93975ed8c01f861ccb6bd082784"
            },
            {
                "c": "mBbJ`WPCW@ifNK3@++t4I%$E#6q#Z1z0`1$sX#Ud75~MsN61uu`otjd{TP}lqWol}K{;1%c;CDw21Y#EyOWiy884b7XQ@e`zy",
                "oc": "b0c13d4a4a9ffcb2ef853959fad91ee86a25329303d62e384c5007a2840ccb81e09bac960add3469d291a9e2eeb1df3245b62ae7eb28507d32095d2844630352",
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
            "oc": "b0c0a7385cb2f7dfe32a2649a9d8294794b8fc05585a240c1315f1e45ee7d9012616db3f01b43fa94351618670a29c24fc75df1392d52764c757b34495888b1c",
            "s": "f510853730e1c3dbd31b86963f029dd5",
            "a": 1
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6O>W7y15TC<^_oBO-6ni$TotY#2~YM<M@sqoxB-?M`DeE^NN6m0Df6N?oWH#Om&d50PLW^",
            "oc": "b0c13d4a4a9ffcb2ef853868eb0b5bfb4f9321f4e94ea52a407246305f5982a4eb935f48b5c94030e8faa84bc0505075aa40c2dbf8c916183c371b5f110d796e",
            "s": "f510853730e1c3dbd31b86963f029dd5",
            "a": 1
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6I1D+phqU}j#iX1<;Jw*5%P5k#2~YM<M@sqoxB-?M`DeE^NN6m0Df6N?oWH#Om&d50PLW^",
            "oc": "b0c13d4a4a9ffcb2ef853868ec9146175332740eb29cb6e7676743c9002d0800bcc8a86def024cc965e1a1113f85840f7c048c85d18deebafb1badbd553f49a8",
            "s": "f510853730e1c3dbd31b86963f029dd5",
            "a": 1
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6W-p1W+#!C?F+J)OTGl*bE5q@#2~YM<M@sqoxB-?M`DeE^NN6m0Df6N?oWH#Om&d50PLW^",
            "oc": "b0c13d4a4a9ffcb2ef85386996861f7f0232e345b1136090999fe886e1e507fc76c7521af695c91e0b4c30b220ea6c0d5c7651f29bd2ec6811f10fc01d454064",
            "s": "f510853730e1c3dbd31b86963f029dd5",
            "a": 1
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6SMb-%jgZ0hcbtWu1s`Ve@lL;#2~YM<M@sqoxB-?M`DeE^NN6m0Df6N?oWH#Om&d50PLW^",
            "oc": "b0c13d4a4a9ffcb2ef853869968725a730f60abc8fe2140c7355410494567a87a486240dece45e3bb42852945074e36e55dab5fd5cf5cdb325d675d64f0b2719",
            "s": "f510853730e1c3dbd31b86963f029dd5",
            "a": 1
        },

        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6Z{(4c^$CD^7q>z{xl^%5S4=m#2~YM<M@sqoxB-?M`DeE^NN6m0Df6N?oWH#Om&d50PLW^",
            "oc": "b0c0a7385cb2f7dfe32a2649a9d8294794b8fc05585a240c1315f1e45ee7d9012616db3f01b43fa94351618670a29c24fc75df1392d52764c757b34495888b1c",
            "s": "33743aed3ae636f6bf05cff11ac4b519"
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6O>W7y15TC<^_oBO-6ni$TotY#2~YM<M@sqoxB-?M`DeE^NN6m0Df6N?oWH#Om&d50PLW^",
            "oc": "b0c13d4a4a9ffcb2ef853868eb0b5bfb4f9321f4e94ea52a407246305f5982a4eb935f48b5c94030e8faa84bc0505075aa40c2dbf8c916183c371b5f110d796e",
            "s": "33743aed3ae636f6bf05cff11ac4b519"
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6I1D+phqU}j#iX1<;Jw*5%P5k#2~YM<M@sqoxB-?M`DeE^NN6m0Df6N?oWH#Om&d50PLW^",
            "oc": "b0c13d4a4a9ffcb2ef853868ec9146175332740eb29cb6e7676743c9002d0800bcc8a86def024cc965e1a1113f85840f7c048c85d18deebafb1badbd553f49a8",
            "s": "33743aed3ae636f6bf05cff11ac4b519"
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6W-p1W+#!C?F+J)OTGl*bE5q@#2~YM<M@sqoxB-?M`DeE^NN6m0Df6N?oWH#Om&d50PLW^",
            "oc": "b0c13d4a4a9ffcb2ef85386996861f7f0232e345b1136090999fe886e1e507fc76c7521af695c91e0b4c30b220ea6c0d5c7651f29bd2ec6811f10fc01d454064",
            "s": "33743aed3ae636f6bf05cff11ac4b519"
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6SMb-%jgZ0hcbtWu1s`Ve@lL;#2~YM<M@sqoxB-?M`DeE^NN6m0Df6N?oWH#Om&d50PLW^",
            "oc": "b0c13d4a4a9ffcb2ef853869968725a730f60abc8fe2140c7355410494567a87a486240dece45e3bb42852945074e36e55dab5fd5cf5cdb325d675d64f0b2719",
            "s": "33743aed3ae636f6bf05cff11ac4b519"
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR7}D3d-^`fltk2Cg%EF6{!Q^!Dq>oG#B*Y-IedG9!9-X`ygGXYGf%A%hh5&w9KkiR^+DvtjvH<L$zy",
            "oc": "af96e1d969ccd0a03ffe6dfbc7712038903cdc88635994c765b6b7e9a00c0799",
            "s": "a7cea93975ed8c01f861ccb6bd082784"
        },
        {
            "c": "mBbL9j9(QoRD)R+z?=Fvn#=FR6lO>G(8jjwtt=6Wr{!%WJ?vt(v&0~?edG9!9-X`ygGXYGf%A%hh5&w9KkiR^+DvtjvH<L$zy",
            "oc": "b0c13d4a4a9ffcb2ef853959fad91ee86a25329303d62e384c5007a2840ccb81e09bac960add3469d291a9e2eeb1df3245b62ae7eb28507d32095d2844630352",
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
              "oc": "af96e1dabbec581f36d71e3a48ffb427f54832851b4fefa6989887ccaf7e038f66f8cb40e6959458",
              "s": "a7cea93975ed8c01f861ccb6bd082784"
          },
          {
              "c": "mBbM0#UZON2jQ3@LiWcvns2Yf6y3L;hykEh`}*fX#aF;n*=>+*o5Uarod39C7TF-SiCD-NgkG)l%Vw=l!tX>H*P<PfE$+0Szy",
              "oc": "b0c13d4a4a9ffcb2ef853959fb2d26236337244ed86d66470d08963ed703356a1cee600a9a75a70aaefc1b4ca03b7918a7df25b7cd4ca774fd5b8616e6b9adb8",
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
              "oc": "af96e1dabbec5913707844664eb160923982fdec75bda4bcd063e26b4254a9f334ce7ebc2612713c",
              "s": "a7cea93975ed8c01f861ccb6bd082784"
          },
          {
              "c": "mBbK0Cob5dQ5Jki69vRd75f9k6yc;BV`COqamPOX6P`g5TMr)AeZ(N=Pk%%2`Uq=={*w3hh3IBNp3y0Ztr0g;ir=DoZ9TNhezy",
              "oc": "b0c13d4a4a9ffcb2ef8629d60d5e32db453fad8792b2450d02f37ec5fe207b42da30093fd14c4975c9b192ecbf939b2d5a56a7ae2db1254e6532aa7569971462",
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
    result jsonb;
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
          "hm": "hmac.%s",
          "bf": %s,
          "v": 2
        }',
        random_key,
        random_val,
        id, m);

    result := s::jsonb || sv || ore_term;

    -- Post-2.3 ste_vec shape: each sv element carries `hm` (HMAC-256) as its
    -- selector-scoped equality term. Synthesise `hm` deterministically from
    -- the existing fixture terms so same-plaintext sv elements share the
    -- same hm (preserving equality semantics under the new scheme).
    IF result -> 'sv' IS NOT NULL THEN
      result := jsonb_set(result, '{sv}', (
        SELECT jsonb_agg(
          elem || jsonb_build_object(
            'hm',
            coalesce(
              elem ->> 'hm',
              elem ->> 'oc',
              elem ->> 'b3',
              md5(coalesce(elem ->> 's', '') || coalesce(elem ->> 'c', ''))
            )
          )
        )
        FROM jsonb_array_elements(result -> 'sv') elem
      ));
    END IF;

    RETURN result::eql_v2_encrypted;
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
    e := create_encrypted_json('ob')::jsonb || ore_term;
    RETURN e::eql_v2_encrypted;
  END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS create_encrypted_ste_vec_json(val integer);
CREATE FUNCTION create_encrypted_ste_vec_json(val integer)
  RETURNS eql_v2_encrypted
AS $$
 DECLARE
    e eql_v2_encrypted;
  BEGIN
    EXECUTE format('SELECT ste_vec.e FROM ste_vec WHERE id = %s', val) INTO e;
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
--
-- Synthetic ste_vec test data (replaces the pre-2.3 fixture in tests/ste_vec.sql)
--
-- Returns an eql_v2_encrypted carrying a v2.3-compliant SteVecPayload:
--   {i, v, sv: [<sv entries>]}    — no root `c` per the v2.3 schema
--
-- The sv entries reuse real CLLW `oc` ciphertexts captured from a pre-2.3
-- cipherstash-suite encryption (so the byte structure satisfies the CLLW
-- per-byte comparison rule that `eql_v2.compare_ore_cllw_term` expects).
-- `hm` for `oc`-bearing entries is synthesised deterministically as
-- `md5(s || record_id)` — opaque to callers; what matters is per-record
-- equality semantics for ste_vec_contains.
--
-- Plaintext shape (for reference):
--   { "hello": "world {N}", "number": N,
--     "nested": { "number": <random>, "hello": "world {N}" } }
--
-- Selectors:
--   $                  -> 9493d6010fe7845d52149b697729c745
--   $.hello            -> d90b97b5207d30fe867ca816ed0fe4a7
--   $.nested           -> 3a9a5d5601369d00a92e851b5490d2d1
--   $.nested.hello     -> f3b937817818610f955b6bbbc337aa2b
--   $.number           -> fa6f99753674e2e0db242dd805eacac8
--   $.nested.number    -> 3dba004f4d7823446e7cb71f6681b344
DROP FUNCTION IF EXISTS build_synthetic_ste_vec(integer);
CREATE FUNCTION build_synthetic_ste_vec(id integer)
  RETURNS eql_v2_encrypted
AS $$
  DECLARE
    payload jsonb;
  BEGIN
    CASE id
      WHEN 1 THEN payload := '{"i": {"c": "encrypted_jsonb", "t": "encrypted"}, "v": 2, "sv": [{"s": "9493d6010fe7845d52149b697729c745", "c": "mBbL@V^%dN?0W$;g)1-JP*cmqX%JhW0ZKZ^G?lNn$CfXJH|W!V*=irNa@z{OfN`t<awl|7h5cAnUBX4+`+IO>JKpjgX(7ToG`HWORpeL^$zO*^J`x7KRuY0gW#{2OV?F-Z2rNIo9CWCgDOt!Fg2d-I_cW7ljFiM641$Ej6!A<1h!E%%1I5$YIE}thw=uucU|IEwG+k8(puh", "hm": "8067db44a848ab32c3056a3dbe4edf16", "a": false}, {"s": "d90b97b5207d30fe867ca816ed0fe4a7", "c": "mBbL@V^%dN?0W$;g)1-JP*cmq8w1tsgI>{D^0s{k=Kwcv$GK=wXj973J#%Qi#2^fUgv1o_OazD!=oJIS)7m(VzEQU^ztUh?^@=oIRR^HJ", "hm": "38daa8fd19f650398102591325e5b095", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cad9eda1b", "a": false}, {"s": "3a9a5d5601369d00a92e851b5490d2d1", "c": "mBbL@V^%dN?0W$;g)1-JP*cmqK@;r|K5qT&!~f=;IrFg2#bT?wQ2^uT?MQ1vb$M{qdKJ&)IM{5qYVEjR-wUOWau*19aKGAhNSrAja?iC`)BMCB41$Ej6!A<1h!E%%1I5$YIE}thw=uucU|IEwG+k8(puh", "hm": "6ab75dbd78d2b77f8675161ad8fddbe7", "a": false}, {"s": "f3b937817818610f955b6bbbc337aa2b", "c": "mBbL@V^%dN?0W$;g)1-JP*cmq8w1tsgI>{D^0s{k=Kwcv$GK=wXj973J#%Qi#2^fUgv1o_OazD!=oJIS)7m(VzEQU^ztUh?^@=oIRR^HJ", "hm": "147bf218dbfeef38b7b0f5fcd5e42b4a", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cad9eda1b", "a": false}, {"s": "fa6f99753674e2e0db242dd805eacac8", "c": "mBbL@V^%dN?0W$;g)1-JP*cmqBor4+`y>b|qoX{uNXP2XSf9UacD`690sM|6wY5xR^!82|E5slSf`r5r@k|7W5a<;H#nak2jlNO0F~8DaS@nuET~!C5zy", "hm": "1290f199af58c240b75e0da6468a0385", "oc": "fc6a9c6533b34219a300d82916e71a4955a48b208969eaf4dec0b88477b753fce8e31613f296a3ebc3dc428912fffa10ad58ef698631b5a3a8ec0a53593fbae5", "a": false}, {"s": "3dba004f4d7823446e7cb71f6681b344", "c": "mBbL@V^%dN?0W$;g)1-JP*cmq6X0HB3o?jM)H&5-v7zt<!`#HU#2^fUgv1o_OazD!=oJIS)7m(VzEQU^ztUh?^@=oIRR^HJ", "hm": "2f3043cf2790f49b5fcd1b76db5ce114", "oc": "fc6969750c2061f82e10c8344c0bc5054e0bb98e75b55a10b8b92992e4141275d376c2437d06819526f92126059909bd0c4eed2be9038d81955012a8d7af0e07", "a": false}]}'::jsonb;
      WHEN 2 THEN payload := '{"i": {"c": "encrypted_jsonb", "t": "encrypted"}, "v": 2, "sv": [{"s": "9493d6010fe7845d52149b697729c745", "c": "mBbKA;2~_|&h787#WXU&=nqH4YPl!<%e}R}?ZZ86dK=XLlHmD4+@YpqE*k$Nnhnq|L3yhQ@WgNE0P94mCuT5Y>=j&nB7f>vGiA$|Xx3CMyn3~nC&!m2n|FsTD7A$Vznv5KN&ZD;2AYnEe)S~DtWX{85Bby<_1V+JAQ#4iCfmE5R8de-4qZ}xLQgnq2A0{V^??Z>lfCrxAE3Y", "hm": "8067db44a848ab32c3056a3dbe4edf16", "a": false}, {"s": "d90b97b5207d30fe867ca816ed0fe4a7", "c": "mBbKA;2~_|&h787#WXU&=nqH48zV_I^FE9E$Tx^Bh>*L$Z3UaiidiIG8f6-J#2^>OgC^U%oK#UzQ4U>FeL_z-Y6h0ssP%yfAd|iH^dF$W", "hm": "9abd0b95e7e35bcb1aec2a9631454ad6", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cad9edbca", "a": false}, {"s": "3a9a5d5601369d00a92e851b5490d2d1", "c": "mBbKA;2~_|&h787#WXU&=nqH4LKI%yI#+SZ>%7r@cMkI#>B`Y@g%m&?_;qLaZhOY{yIKN|aPs2dC}n9ugdf8Jtw6L@OO2~2$4fWO5Ld;)=aR3)AQ#4iCfmE5R8de-4qZ}xLQgnq2A0{V^??Z>lfCrxAE3Y", "hm": "6ab75dbd78d2b77f8675161ad8fddbe7", "a": false}, {"s": "f3b937817818610f955b6bbbc337aa2b", "c": "mBbKA;2~_|&h787#WXU&=nqH48zV_I^FE9E$Tx^Bh>*L$Z3UaiidiIG8f6-J#2^>OgC^U%oK#UzQ4U>FeL_z-Y6h0ssP%yfAd|iH^dF$W", "hm": "5e6c158ae76b6ee9feca2e42f9679ab7", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cad9edbca", "a": false}, {"s": "fa6f99753674e2e0db242dd805eacac8", "c": "mBbKA;2~_|&h787#WXU&=nqH4C6`I)f|7H0_iUN!sI%p|PD^%)I3u@>Lo)l>D^FTEHMX_T`5(j}7si7o+q;}pQBYA1T~d8QPdI7@mf5KFfe9d!z4Y`Spuh", "hm": "a9281cdcd87336826ba7081aab0e875a", "oc": "fc6a9c6533b34219a3018e1c9ce9330c0e754864cd7341d488ae3fc464cdd85f73b1e9aabab2d18c8de2de82052d5ec9e8c906ef5d082a34b5a4e63234a2f831", "a": false}, {"s": "3dba004f4d7823446e7cb71f6681b344", "c": "mBbKA;2~_|&h787#WXU&=nqH46KPW9$J3a=|Jqzg_kinIG(B$L#2^>OgC^U%oK#UzQ4U>FeL_z-Y6h0ssP%yfAd|iH^dF$W", "hm": "7129bb95e151bf8659acd9a135f0475b", "oc": "fc6a9c6533b341a3bbe1d7eefbfe3457e74c9c4dcde2c1d40fafa6fe7bfe1cf225871f30f428f65a348062433db703d77583587a42443a1808d112f0514f0262", "a": false}]}'::jsonb;
      WHEN 3 THEN payload := '{"i": {"c": "encrypted_jsonb", "t": "encrypted"}, "v": 2, "sv": [{"s": "9493d6010fe7845d52149b697729c745", "c": "mBbJ&V+<+WNnWTGaHg#Y!CMH#YUj70Cz_B24U3#W#b#KGw1<@cS7(S0Ce|x{!!At-Epo5#C-8ZJATrn?7A$@`(u>=$?2X*e<w<!iUV#cPE`;!0{ZJ_Q@3MnCF+cn%y}Axv1hP<*1CKM$^(%+xU1miXGic$IXV<&LAX}Tz|H9gB(Ma8~H!SgKJ3-sUN*`Ics~!stkH^qucc8!", "hm": "8067db44a848ab32c3056a3dbe4edf16", "a": false}, {"s": "d90b97b5207d30fe867ca816ed0fe4a7", "c": "mBbJ&V+<+WNnWTGaHg#Y!CMH#8-dM231ayoGQIzTv|n<6^Uo7QSi`z>1UcJ`#2{On(Eq~PZP7^Gu{SL7X*)sN#Y!JpxT_uu4UfmrWp|*!", "hm": "09b4e2b894eb169804af9fe0936c4ea1", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cad9edbcb", "a": false}, {"s": "3a9a5d5601369d00a92e851b5490d2d1", "c": "mBbJ&V+<+WNnWTGaHg#Y!CMH#Li)6dAJoLZZs|CbiZstYT&vn}P=yVCm1M9YnMJisIv8CoL6Tzth(-874C)8j_qYuX4Fv>J<<09@x_=DyfRUxdAX}Tz|H9gB(Ma8~H!SgKJ3-sUN*`Ics~!stkH^qucc8!", "hm": "6ab75dbd78d2b77f8675161ad8fddbe7", "a": false}, {"s": "f3b937817818610f955b6bbbc337aa2b", "c": "mBbJ&V+<+WNnWTGaHg#Y!CMH#8-dM231ayoGQIzTv|n<6^Uo7QSi`z>1UcJ`#2{On(Eq~PZP7^Gu{SL7X*)sN#Y!JpxT_uu4UfmrWp|*!", "hm": "116db93790731743ce7216deeb4c4ca4", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cad9edbcb", "a": false}, {"s": "fa6f99753674e2e0db242dd805eacac8", "c": "mBbJ&V+<+WNnWTGaHg#Y!CMH#B}MUqDEGI9$OIF8zdRu#08c>I+EsdWf96+dkZ<vqbC2ZwC_BU;Tbt1T!rE=oNZqkFEb(bOLEFVjA6dAo9t#bR$IxYWpuh", "hm": "ed06acc77a62340b9f502bf5da89bc99", "oc": "fc6a9c6533b34219a300d82a727397fef6dca251f6fcf9ac4cf6a7c7635cfda4330ec1f97fd4b231eaa28e45cb803b6adfe28abf3c2dc3ce68229e2ee8007868", "a": false}, {"s": "3dba004f4d7823446e7cb71f6681b344", "c": "mBbJ&V+<+WNnWTGaHg#Y!CMH#6TnlsYvyB3r-Zxcln{T2hv3OI#2{On(Eq~PZP7^Gu{SL7X*)sN#Y!JpxT_uu4UfmrWp|*!", "hm": "0f751a32038ba03bd87b19a345333e5e", "oc": "fc6a9c6533b341a3bbe1d7eefcccd2a2368c51e9565516483cb5c44196f175a36ad4abbe26de5fcd8d23bec22d3006f6a1fa7014550e71a08deb3efac3d8b145", "a": false}]}'::jsonb;
      WHEN 4 THEN payload := '{"i": {"c": "encrypted_jsonb", "t": "encrypted"}, "v": 2, "sv": [{"s": "9493d6010fe7845d52149b697729c745", "c": "mBbM9-awLU6a<?+zn?~|a;Cw=YJKtITe!+6ld$+9*w5*ce1H3+od2uKI4g3M2=KTDW<JUs`7EJi&ZB%cZvOtc%?;Zsu&vGP?sH_DKED(v)GU?2zd3=NqWJ)e3`PBGa30>C%<3u9$EKb~W)de42&14s2=>FoXlMb%ApcgZX1WmCNxJ>3Blt#*(|HBa<j9v%5N($VTMP&-eW1V", "hm": "8067db44a848ab32c3056a3dbe4edf16", "a": false}, {"s": "d90b97b5207d30fe867ca816ed0fe4a7", "c": "mBbM9-awLU6a<?+zn?~|a;Cw=8<4;V5mTYoT7@C*zCw>yw2*id#80AgNqT0K#327xtY*3p+DW?ot0VYEjnjDr(d5XNQ4npH3R?^aEq$QC", "hm": "0848cc60a82b024ba702aab78b757a27", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cad9f41f8", "a": false}, {"s": "3a9a5d5601369d00a92e851b5490d2d1", "c": "mBbM9-awLU6a<?+zn?~|a;Cw=Lf=-#GT1*3>wLQJTS5Buj8R|QNY+p4aeSYRGzixBKRP(>$YGm-@6u=+OF_wtB8QA|boP=&$^#B;c1>9aoy)SsApcgZX1WmCNxJ>3Blt#*(|HBa<j9v%5N($VTMP&-eW1V", "hm": "6ab75dbd78d2b77f8675161ad8fddbe7", "a": false}, {"s": "f3b937817818610f955b6bbbc337aa2b", "c": "mBbM9-awLU6a<?+zn?~|a;Cw=8<4;V5mTYoT7@C*zCw>yw2*id#80AgNqT0K#327xtY*3p+DW?ot0VYEjnjDr(d5XNQ4npH3R?^aEq$QC", "hm": "48135ebc84e4e86a44f6d78ecda6bd24", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cad9f41f8", "a": false}, {"s": "fa6f99753674e2e0db242dd805eacac8", "c": "mBbM9-awLU6a<?+zn?~|a;Cw=B_nhSii0k6IR*^aFr;+8pNuz%%1*sKvM#Q&Tx*b}L!drIlxM^s|5mJKx)9n)y8Wvo_(qM>c?Hqr$d^$NZI=pL3<xcKpuh", "hm": "2d9b587f618f330e01390f237080049a", "oc": "fc6a9c6533b34219a3018e1c9dc9ba2f98cafd635c4ff2d18bec0c2880dad16da8c5069b24d56dc7b81dcf9a91d0f3418efdf18ec0f272316c7c6ca71a674e4c", "a": false}, {"s": "3dba004f4d7823446e7cb71f6681b344", "c": "mBbM9-awLU6a<?+zn?~|a;Cw=6B!bc7#aXak!<G<8{f63x(`jc#327xtY*3p+DW?ot0VYEjnjDr(d5XNQ4npH3R?^aEq$QC", "hm": "c518cfc754d61c464083bc9f2b6d482f", "oc": "fc6a9c6533b341a3bbe1d7ef077b44e5caac09cf70fc2a2d5a53c2cbdf200e81946fd6568bda7fc0a375a6786280c444df7c9d2e39497be6f3e69e94b5cc6fd4", "a": false}]}'::jsonb;
      WHEN 5 THEN payload := '{"i": {"c": "encrypted_jsonb", "t": "encrypted"}, "v": 2, "sv": [{"s": "9493d6010fe7845d52149b697729c745", "c": "mBbJZA|9c2`{Osnrra?Hj)cv`YFJ>Kt4RJ*8LO2XQqL+Pqd_9s0vN<&V}uKTbz)(?Kb4+xpBxMa;Y2+`wxSdOU}4O~cKwn`(-AcBj{+j{1przTWjt<01cd^h(Fa;pBD=0k9``h@8OPcTs5t(bz$Ve*;3X1KV6FnhAWrE)*M{J-nozAcDun97I9)DC61}WC4g$Z=r!U$ho1nk", "hm": "8067db44a848ab32c3056a3dbe4edf16", "a": false}, {"s": "d90b97b5207d30fe867ca816ed0fe4a7", "c": "mBbJZA|9c2`{Osnrra?Hj)cv`8vu0{XK}SSyw%$>)p?C8#My;w6W3&4h>M!|#2`-TLDz=hvYJq>I4Xqd!Z=+nND{rQIt~KA&!;ciB%7eX", "hm": "0715a8422f762ed55120163cced6d754", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cad9f41f9", "a": false}, {"s": "3a9a5d5601369d00a92e851b5490d2d1", "c": "mBbJZA|9c2`{Osnrra?Hj)cv`LjQ)X$p_~llv&x~<)hiIe5|*>Hc1Zkglk(`D>cnLbBrE07YBC9SR?ZTg}77_!tjaq#%1r4K6AOUpGDKT5L`OMAWrE)*M{J-nozAcDun97I9)DC61}WC4g$Z=r!U$ho1nk", "hm": "6ab75dbd78d2b77f8675161ad8fddbe7", "a": false}, {"s": "f3b937817818610f955b6bbbc337aa2b", "c": "mBbJZA|9c2`{Osnrra?Hj)cv`8vu0{XK}SSyw%$>)p?C8#My;w6W3&4h>M!|#2`-TLDz=hvYJq>I4Xqd!Z=+nND{rQIt~KA&!;ciB%7eX", "hm": "23efef690ba5f19d3ae224ce07939b88", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cad9f41f9", "a": false}, {"s": "fa6f99753674e2e0db242dd805eacac8", "c": "mBbJZA|9c2`{Osnrra?Hj)cv`C06PttDegli<tG$gyCvMg0C@`h#$|0>I%ijveChO?CCfOY;nXOPU%6{hTyWAP^~yBgzCaLT`ouxy{tM80>96vFWMxVpuh", "hm": "d4bd24711b0a06ca0f51f237faec3dad", "oc": "fc6a9c6533b34219a3018e1d533343a282b879ce470722cfe6ae36688b2de8d685a395d6c555b720db3eed0042fdaa8ee6403fc3ba8c3f7d423f8821a1228fd7", "a": false}, {"s": "3dba004f4d7823446e7cb71f6681b344", "c": "mBbJZA|9c2`{Osnrra?Hj)cv`6LBDt#>7UH2q|VZbg%~lyV4vB#2`-TLDz=hvYJq>I4Xqd!Z=+nND{rQIt~KA&!;ciB%7eX", "hm": "bcc45d65eb52a7d19ceebb7a47b8fcb1", "oc": "fc6a9c6533b341a3bbe1d7ef077cf858f5582688ede7a88e44522be9ea2a62f87707519a1c76b54b5da3193f77db9531dc887dcedafebc8135ccf8028cf38614", "a": false}]}'::jsonb;
      WHEN 6 THEN payload := '{"i": {"c": "encrypted_jsonb", "t": "encrypted"}, "v": 2, "sv": [{"s": "9493d6010fe7845d52149b697729c745", "c": "mBbKU&X2H2TUi~T2<d8c9!nC$YU)bLn3=6jQU;Now82E?<ord~X~H<HOT7vYlptNUK{PMeB1P`?6&?_F4F=IOKB}ehnlPW$#p)N|5&_uQjc8Bwxo}Bh(c;B5G9PQ^X7YebGi)VN*~Wl`f|lA3LzuAAEZuR3&>sQBASNTOjoiQuI`BLc){G*FR<F5D2lMKWHbII<qxJ7ww4lH", "hm": "8067db44a848ab32c3056a3dbe4edf16", "a": false}, {"s": "d90b97b5207d30fe867ca816ed0fe4a7", "c": "mBbKU&X2H2TUi~T2<d8c9!nC$8-g*K>;1W;<^)-g>TjwP+P;@y+w6)=8kCzp#2_Xku8rKl4La~V6xNI)iB_+<O$YPpk2XPyN2B%cTeP6S", "hm": "82428edd447b1784a414ebbe0c97c395", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cad9f42ba", "a": false}, {"s": "3a9a5d5601369d00a92e851b5490d2d1", "c": "mBbKU&X2H2TUi~T2<d8c9!nC$LS#Ol9A88%tVR*?!8akXdk*TWopl^t?gJ@p{J-+j?lYu#V`(KR3+MRS2G9=H>`Tn8b$&_I`G&=n39<c-|JotMASNTOjoiQuI`BLc){G*FR<F5D2lMKWHbII<qxJ7ww4lH", "hm": "6ab75dbd78d2b77f8675161ad8fddbe7", "a": false}, {"s": "f3b937817818610f955b6bbbc337aa2b", "c": "mBbKU&X2H2TUi~T2<d8c9!nC$8-g*K>;1W;<^)-g>TjwP+P;@y+w6)=8kCzp#2_Xku8rKl4La~V6xNI)iB_+<O$YPpk2XPyN2B%cTeP6S", "hm": "276af3a6e9039664d418a0910c6e847a", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cad9f42ba", "a": false}, {"s": "fa6f99753674e2e0db242dd805eacac8", "c": "mBbKU&X2H2TUi~T2<d8c9!nC$B?hW7O0sDNK7Dgwgx=Qp(YP@zH*!jK9CDzQ2%AD+Zfcf{G8V)jCL^wm+`tVw@H`aOj3S9vuenVJ^XiW_L5fGC_3vA>puh", "hm": "78dfa2973c16ca5551df6f550f6a95be", "oc": "fc6a9c6533b34219a3018e1c9ce932bd1929ff8bed603031286d87dd98008307deac134ba0759bedd4b72bdb6c469b0c9bba850f0b9d6de69f941801d901593b", "a": false}, {"s": "3dba004f4d7823446e7cb71f6681b344", "c": "mBbKU&X2H2TUi~T2<d8c9!nC$6IRbUbBy-AgMR;&;^Bjo7`%nN#2_Xku8rKl4La~V6xNI)iB_+<O$YPpk2XPyN2B%cTeP6S", "hm": "07f70d61aad8143718440b0ad85d2836", "oc": "fc6a9c6533b341a3bbe1d7ef08cb5ae7124351c5732a524a861d70063a0de4ae5b8c61c3838dd5143ae93afc15da0d153d5b8fbde4253fffe3f0447c445aebd1", "a": false}]}'::jsonb;
      WHEN 7 THEN payload := '{"i": {"c": "encrypted_jsonb", "t": "encrypted"}, "v": 2, "sv": [{"s": "9493d6010fe7845d52149b697729c745", "c": "mBbLWIPx0`a~GhoFvD#SK|+DVYWwCvQRgCtCmpM_Je~#b*?be!Od7*jT0qMGN)z(Xa`9*-nQ)h#h>?knzEr&IQ4C}9_BKS`w@y=Z<kvXyx`^``-+G@YMoZ>xMI61!?)?c%KqJ9^_Qhgfj$2Nd3!8skzc`58ed?&hAZ_oqHcY^@#&Q*hTu^_7Of|hoElmzGI;5NP!2kG~rl7z", "hm": "8067db44a848ab32c3056a3dbe4edf16", "a": false}, {"s": "d90b97b5207d30fe867ca816ed0fe4a7", "c": "mBbLWIPx0`a~GhoFvD#SK|+DV8)c(L(X9VOZ->csIkThDI`VV6a}NV%eDmLo#2{_&wl++_w8nB3hg?v9g-kWQNG(kcGCHK2^T7Z3nx>$@", "hm": "1bffc404510843284719cc70fea26893", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cad9f42bb", "a": false}, {"s": "3a9a5d5601369d00a92e851b5490d2d1", "c": "mBbLWIPx0`a~GhoFvD#SK|+DVLVlEEd!}1mw5-+>Q)|48N1ODPT`={zO||cAxQ=}b+yt(ANAX*$QWW-pHFGi-2HP^n=gIYsiH{C*(7KhBGYnV6AZ_oqHcY^@#&Q*hTu^_7Of|hoElmzGI;5NP!2kG~rl7z", "hm": "6ab75dbd78d2b77f8675161ad8fddbe7", "a": false}, {"s": "f3b937817818610f955b6bbbc337aa2b", "c": "mBbLWIPx0`a~GhoFvD#SK|+DV8)c(L(X9VOZ->csIkThDI`VV6a}NV%eDmLo#2{_&wl++_w8nB3hg?v9g-kWQNG(kcGCHK2^T7Z3nx>$@", "hm": "39a0877536cb701bcd86d966d6f01220", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cad9f42bb", "a": false}, {"s": "fa6f99753674e2e0db242dd805eacac8", "c": "mBbLWIPx0`a~GhoFvD#SK|+DVCCe8R*C3LA0=X>OcfeqR8^WMRfsewr$X@D%aU(5LdkQQ9)o{chZSS@=Ou)3pautVMP=AF?HN8kJO%5_Tq?_}=|M;4wpuh", "hm": "401019d57f61a508657a4bed113856e0", "oc": "fc6a9c6533b34219a3018e1d524d118ab347ae240e626857d0111d7f917bb3cd5339df72bafa18d30abbb947a81ad55fd0bd2482e24cb814470c42c13e06c5e8", "a": false}, {"s": "3dba004f4d7823446e7cb71f6681b344", "c": "mBbLWIPx0`a~GhoFvD#SK|+DV6UNb%E^11oJovsVsxVKcuBCqS#2{_&wl++_w8nB3hg?v9g-kWQNG(kcGCHK2^T7Z3nx>$@", "hm": "80f3d58e5fa6f744f23844591ec626d8", "oc": "fc6a9c6533b341a3bbe1d7ef08cc248ae8d903e2c5b3872108e910e5e1abfd12b864110cf8c3f96068c2e22a91bd4a31fd576d914ab6f592b510a5d09303a113", "a": false}]}'::jsonb;
      WHEN 8 THEN payload := '{"i": {"c": "encrypted_jsonb", "t": "encrypted"}, "v": 2, "sv": [{"s": "9493d6010fe7845d52149b697729c745", "c": "mBbLU1c41)W9q|644h(&;v|K{Y9^G7d5DAJM-UtmtvJFD-rpm|!bIFbJ_38g6>L4JxCAzZqg;J~zXCHw&~>@%Qg;jo1i6*=>!NvDVAeB%BPNh0)fUgx(>_IJTLdje%|Tm3t350kkPVz)R1@HjcJH#rF5b0<0458>AfMQ%t`tCz*iE%8Q=~zakT$5-;E$Vz8_*^me1YEm>!82", "hm": "8067db44a848ab32c3056a3dbe4edf16", "a": false}, {"s": "d90b97b5207d30fe867ca816ed0fe4a7", "c": "mBbLU1c41)W9q|644h(&;v|K{8(5Xe9m`5OZ4)XL??yheX-WGqH8&DwuvUEG#2}y8sIC-1kJwGMEK{UGm5?^5*Wizvh8xf(9(;k`{p+B>", "hm": "133106b1635c7813ce08c49eed5f3758", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cae77a9e6", "a": false}, {"s": "3a9a5d5601369d00a92e851b5490d2d1", "c": "mBbLU1c41)W9q|644h(&;v|K{LTk1A!h2L`pi*@*IAxKZWEp&PvSNIeN<nRB;L>9`O-dc<1;`<{tm3Q%w*bvChnGw`dMo9fQ$%6M)m|ANzcy^dAfMQ%t`tCz*iE%8Q=~zakT$5-;E$Vz8_*^me1YEm>!82", "hm": "6ab75dbd78d2b77f8675161ad8fddbe7", "a": false}, {"s": "f3b937817818610f955b6bbbc337aa2b", "c": "mBbLU1c41)W9q|644h(&;v|K{8(5Xe9m`5OZ4)XL??yheX-WGqH8&DwuvUEG#2}y8sIC-1kJwGMEK{UGm5?^5*Wizvh8xf(9(;k`{p+B>", "hm": "38a6f2f9ca0cb8f95a21b7c9cf353770", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cae77a9e6", "a": false}, {"s": "fa6f99753674e2e0db242dd805eacac8", "c": "mBbLU1c41)W9q|644h(&;v|K{B`tAY7D@4_eh%C5;rHRnV+K)h-PvUiIy1vhxx%(@YHIJ|V0^?NpV+9b6hM#IO|>jjq(POCHmKL&kDG=Y&?X*yf!_V=puh", "hm": "7edf6dd76af31c5468e8699e02aa8257", "oc": "fc6a9c6533b34219a3018e1c9dcaac4823035131d63437a90de98995d0a5f44efc2ec0a4768c718c7c76ffbc7cc5c79e3efe6333415f581fc6a9e9467c8bb509", "a": false}, {"s": "3dba004f4d7823446e7cb71f6681b344", "c": "mBbLU1c41)W9q|644h(&;v|K{6BUWiJXM;%<Xp3vR3|wfRRrQP#2}y8sIC-1kJwGMEK{UGm5?^5*Wizvh8xf(9(;k`{p+B>", "hm": "dd7ffdeb5ffa6df698619368f567480d", "oc": "fc6a9c6533b341a3bbe1d83c495c498ccdb757c8461e519fb5ad2db6ab3d3a7bd2c87b41fd9dcc07fb922e3f1defe81d04c975f73ca873531646f9693340d169", "a": false}]}'::jsonb;
      WHEN 9 THEN payload := '{"i": {"c": "encrypted_jsonb", "t": "encrypted"}, "v": 2, "sv": [{"s": "9493d6010fe7845d52149b697729c745", "c": "mBbK%Ks*MeKDAAsr>I~keTZAcYM9b4|8fb~$D>=F@t{DFHgI0-uESoh1vX`JD2W}wLQ{zT)bJN2)s~oVF-)ubVZ$cQL3PHK6aW_Imq>t*L5uP2iiJQ>>yrXQ9$79k+Csetm7#?HK9lde?+IWkkO%6dKy3qG&U^U8AUq1dArOMF>P%C%>Rmq|o~0(Ggse6t_Yr4zuoAT&_@KZ", "hm": "8067db44a848ab32c3056a3dbe4edf16", "a": false}, {"s": "d90b97b5207d30fe867ca816ed0fe4a7", "c": "mBbK%Ks*MeKDAAsr>I~keTZAc8$p9%O%q$urm@mN+n39d89A;-u7l&A-BbZG#2`Ehz#$NVu<A@xw(4C!AfBZrrG%_DCHE0$cd!z*ANZia", "hm": "8806d68103a6101aba90c7e6fa5c6918", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cae77a9e7", "a": false}, {"s": "3a9a5d5601369d00a92e851b5490d2d1", "c": "mBbK%Ks*MeKDAAsr>I~keTZAcLZs-pqE$l0=C-c5Dk)f~Ku%D4tHX*hf84+p-cokD(@z`M>on8TdKv!5a%!P+7A<ld_F)I<9~6fVUj;!FukWkGAUq1dArOMF>P%C%>Rmq|o~0(Ggse6t_Yr4zuoAT&_@KZ", "hm": "6ab75dbd78d2b77f8675161ad8fddbe7", "a": false}, {"s": "f3b937817818610f955b6bbbc337aa2b", "c": "mBbK%Ks*MeKDAAsr>I~keTZAc8$p9%O%q$urm@mN+n39d89A;-u7l&A-BbZG#2`Ehz#$NVu<A@xw(4C!AfBZrrG%_DCHE0$cd!z*ANZia", "hm": "bf3906212d7e9b29060246b0a6798e07", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cae77a9e7", "a": false}, {"s": "fa6f99753674e2e0db242dd805eacac8", "c": "mBbK%Ks*MeKDAAsr>I~keTZAcCGfIP%Q;QOtEFX-SyMqY)3lx;8sAp`hPTa2z0mDr@O?=HAWOs`JPN=e5Q4DkOjEY%T|Xe6r6#3>tTrY05odR>615-rpuh", "hm": "d3b2e29d9439267eb3ef5aae5b76d4e4", "oc": "fc6a9c6533b34219a300d82a7272762b196c2cd4b0f0e1ef45ddea7f90879fd920fc926b97be039fdee7d2b633ae2744617d375f677e3d62bfebbec1501e8f55", "a": false}, {"s": "3dba004f4d7823446e7cb71f6681b344", "c": "mBbK%Ks*MeKDAAsr>I~keTZAc6Gz~_22KC1k~e`Y-54&aG;cYK#2`Ehz#$NVu<A@xw(4C!AfBZrrG%_DCHE0$cd!z*ANZia", "hm": "42c7edf18bcae5d5e690f093a0f140af", "oc": "fc6a9c6533b341a3bbe1d83c495c4a60bf92ea30f735739475dd2cd9303583a2563ff3a7ad20101dca14da4be5cbf9fc650fc9b4e022ec08077e1b18b557acf5", "a": false}]}'::jsonb;
      WHEN 10 THEN payload := '{"i": {"c": "encrypted_jsonb", "t": "encrypted"}, "v": 2, "sv": [{"s": "9493d6010fe7845d52149b697729c745", "c": "mBbK(pyr$AQACXmOIVmOi}IhuY%De&eY~aps=IX%RsOT!ondLDle#e%BR$Gv&)<Do#vuVPS7W@PmZ7?!TeVhqHX7rCe>f@e%>;NishD;H2XykHX^>azaF#h<uXKw<J_<uMCCRJX{4@y@Zk=h|NF<jksD7eD6miMeb;KZ9YM1<<v^$Z+O(zr7YhC`o{G{(;RF=bBK!+;7>KvJ%zy", "hm": "8067db44a848ab32c3056a3dbe4edf16", "a": false}, {"s": "d90b97b5207d30fe867ca816ed0fe4a7", "c": "mBbK(pyr$AQACXmOIVmOi}Ihu96ceUg9XV?28@M-tz#Br;^6<3WFOjd2ER8q=fogcYM1<<v^$Z+O(zr7YhC`o{G{(;RF=bBK!+;7>KvJ%zy", "hm": "d90767e262f4bbf55bd49665e65ae9f9", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cad9eda1be531d84f87aabfa9", "a": false}, {"s": "3a9a5d5601369d00a92e851b5490d2d1", "c": "mBbK(pyr$AQACXmOIVmOi}IhuLJr=wKvitTn15T2HK9Gf9WP-@uChztE?QZTtZ``BA3^P-GzWm8T=`6b9{?DB2co}A!JgDzI*_|{%^1GO{WxpHAX#dc{GYTtk;F|W6Vz*6{=fXB?_pGy!(2dzD!=L+nV`S", "hm": "6ab75dbd78d2b77f8675161ad8fddbe7", "a": false}, {"s": "f3b937817818610f955b6bbbc337aa2b", "c": "mBbK(pyr$AQACXmOIVmOi}Ihu96ceUg9XV?28@M-tz#Br;^6<3WFOjd2ER8q=fogcYM1<<v^$Z+O(zr7YhC`o{G{(;RF=bBK!+;7>KvJ%zy", "hm": "7e2157805498e1524f0af8576f52b530", "oc": "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793159989698eadf64ab9b3ab45c5366d027b2a5476a635ce6cad9eda1be531d84f87aabfa9", "a": false}, {"s": "fa6f99753674e2e0db242dd805eacac8", "c": "mBbK(pyr$AQACXmOIVmOi}IhuBte;>Ow0vKyBL-0I##N^GXA#daWCrO$8*Bk)0K=lmV1F2cf=rBYM1<<v^$Z+O(zr7YhC`o{G{(;RF=bBK!+;7>KvJ%zy", "hm": "d3df087207cd9e7cb2cb3536b3faa25b", "oc": "fc6a9c6533b34219a300d7db65baa7226274d27d53fb941bb5b8884a18e181a5773acc25bb4dce3e38bfc174f4a91c87b5b22f7e0f9f422b3ad17d6b401590db", "a": false}, {"s": "3dba004f4d7823446e7cb71f6681b344", "c": "mBbK(pyr$AQACXmOIVmOi}Ihu6n`j}Ff83O>k4Ho>^0_=jmcM`uf!l(YM1<<v^$Z+O(zr7YhC`o{G{(;RF=bBK!+;7>KvJ%zy", "hm": "b1f5ecef290038fb398590508320853a", "oc": "fc6a9c6533b341a3bbe1d83c495dd234910130aae562de01247783fd038b94cd6af81089bcdc20b296b09b4475b9dad037051408640ec5d07b716141a05044f3", "a": false}]}'::jsonb;
      ELSE
        RAISE EXCEPTION 'build_synthetic_ste_vec: id must be in 1..10, got %', id;
    END CASE;

    RETURN payload::eql_v2_encrypted;
  END;
$$ LANGUAGE plpgsql;
