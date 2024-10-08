package main

import (
	"log"

	"database/sql"
	_ "database/sql"
)

func InstallEql(engine *sql.DB) {
	log.Println("Start installing custom types and function")
	installCsCustomTypes(engine)
	log.Println("CipherStash custom types installed!")

	log.Println("Install dsl config functions")
	installDslConfigFunction(engine)

	installDslConfigSchema(engine)

	installDslCore(engine)

	installDslEncryptIndex(engine)

	installDslMatch(engine)

}

func installCsCustomTypes(engine *sql.DB) {
	sqlBlock := `
		CREATE EXTENSION IF NOT EXISTS pgcrypto;

		CREATE TYPE ore_64_8_v1_term AS (
		bytes bytea
		);

		CREATE TYPE ore_64_8_v1 AS (
		terms ore_64_8_v1_term[]
		);

		CREATE OR REPLACE FUNCTION compare_ore_64_8_v1_term(a ore_64_8_v1_term, b ore_64_8_v1_term) returns integer AS $$
		DECLARE
			eq boolean := true;
			unequal_block smallint := 0;
			hash_key bytea;
			target_block bytea;

			left_block_size CONSTANT smallint := 16;
			right_block_size CONSTANT smallint := 32;
			right_offset CONSTANT smallint := 136; -- 8 * 17

			indicator smallint := 0;
		BEGIN
			IF a IS NULL AND b IS NULL THEN
			RETURN 0;
			END IF;

			IF a IS NULL THEN
			RETURN -1;
			END IF;

			IF b IS NULL THEN
			RETURN 1;
			END IF;

			IF bit_length(a.bytes) != bit_length(b.bytes) THEN
			RAISE EXCEPTION 'Ciphertexts are different lengths';
			END IF;

			FOR block IN 0..7 LOOP
			-- Compare each PRP (byte from the first 8 bytes) and PRF block (8 byte
			-- chunks of the rest of the value).
			-- NOTE:
			-- * Substr is ordinally indexed (hence 1 and not 0, and 9 and not 8).
			-- * We are not worrying about timing attacks here; don't fret about
			--   the OR or !=.
			IF
				substr(a.bytes, 1 + block, 1) != substr(b.bytes, 1 + block, 1)
				OR substr(a.bytes, 9 + left_block_size * block, left_block_size) != substr(b.bytes, 9 + left_block_size * BLOCK, left_block_size)
			THEN
				-- set the first unequal block we find
				IF eq THEN
				unequal_block := block;
				END IF;
				eq = false;
			END IF;
			END LOOP;

			IF eq THEN
			RETURN 0::integer;
			END IF;

			-- Hash key is the IV from the right CT of b
			hash_key := substr(b.bytes, right_offset + 1, 16);

			-- first right block is at right offset + nonce_size (ordinally indexed)
			target_block := substr(b.bytes, right_offset + 17 + (unequal_block * right_block_size), right_block_size);

			indicator := (
			get_bit(
				encrypt(
				substr(a.bytes, 9 + (left_block_size * unequal_block), left_block_size),
				hash_key,
				'aes-ecb'
				),
				0
			) + get_bit(target_block, get_byte(a.bytes, unequal_block))) % 2;

			IF indicator = 1 THEN
			RETURN 1::integer;
			ELSE
			RETURN -1::integer;
			END IF;
		END;
		$$ LANGUAGE plpgsql;


		CREATE OR REPLACE FUNCTION ore_64_8_v1_term_eq(a ore_64_8_v1_term, b ore_64_8_v1_term) RETURNS boolean AS $$
		SELECT compare_ore_64_8_v1_term(a, b) = 0
		$$ LANGUAGE SQL;

		CREATE OR REPLACE FUNCTION ore_64_8_v1_term_neq(a ore_64_8_v1_term, b ore_64_8_v1_term) RETURNS boolean AS $$
		SELECT compare_ore_64_8_v1_term(a, b) <> 0
		$$ LANGUAGE SQL;

		CREATE OR REPLACE FUNCTION ore_64_8_v1_term_lt(a ore_64_8_v1_term, b ore_64_8_v1_term) RETURNS boolean AS $$
		SELECT compare_ore_64_8_v1_term(a, b) = -1
		$$ LANGUAGE SQL;

		CREATE OR REPLACE FUNCTION ore_64_8_v1_term_lte(a ore_64_8_v1_term, b ore_64_8_v1_term) RETURNS boolean AS $$
		SELECT compare_ore_64_8_v1_term(a, b) != 1
		$$ LANGUAGE SQL;

		CREATE OR REPLACE FUNCTION ore_64_8_v1_term_gt(a ore_64_8_v1_term, b ore_64_8_v1_term) RETURNS boolean AS $$
		SELECT compare_ore_64_8_v1_term(a, b) = 1
		$$ LANGUAGE SQL;

		CREATE OR REPLACE FUNCTION ore_64_8_v1_term_gte(a ore_64_8_v1_term, b ore_64_8_v1_term) RETURNS boolean AS $$
		SELECT compare_ore_64_8_v1_term(a, b) != -1
		$$ LANGUAGE SQL;

		CREATE OPERATOR = (
		PROCEDURE="ore_64_8_v1_term_eq",
		LEFTARG=ore_64_8_v1_term,
		RIGHTARG=ore_64_8_v1_term,
		NEGATOR = <>,
		RESTRICT = eqsel,
		JOIN = eqjoinsel,
		HASHES,
		MERGES
		);

		CREATE OPERATOR <> (
		PROCEDURE="ore_64_8_v1_term_neq",
		LEFTARG=ore_64_8_v1_term,
		RIGHTARG=ore_64_8_v1_term,
		NEGATOR = =,
		RESTRICT = eqsel,
		JOIN = eqjoinsel,
		HASHES,
		MERGES
		);

		CREATE OPERATOR > (
		PROCEDURE="ore_64_8_v1_term_gt",
		LEFTARG=ore_64_8_v1_term,
		RIGHTARG=ore_64_8_v1_term,
		COMMUTATOR = <,
		NEGATOR = <=,
		RESTRICT = scalargtsel,
		JOIN = scalargtjoinsel
		);

		CREATE OPERATOR < (
		PROCEDURE="ore_64_8_v1_term_lt",
		LEFTARG=ore_64_8_v1_term,
		RIGHTARG=ore_64_8_v1_term,
		COMMUTATOR = >,
		NEGATOR = >=,
		RESTRICT = scalarltsel,
		JOIN = scalarltjoinsel
		);

		CREATE OPERATOR <= (
		PROCEDURE="ore_64_8_v1_term_lte",
		LEFTARG=ore_64_8_v1_term,
		RIGHTARG=ore_64_8_v1_term,
		COMMUTATOR = >=,
		NEGATOR = >,
		RESTRICT = scalarlesel,
		JOIN = scalarlejoinsel
		);

		CREATE OPERATOR >= (
		PROCEDURE="ore_64_8_v1_term_gte",
		LEFTARG=ore_64_8_v1_term,
		RIGHTARG=ore_64_8_v1_term,
		COMMUTATOR = <=,
		NEGATOR = <,
		RESTRICT = scalarlesel,
		JOIN = scalarlejoinsel
		);

		CREATE OPERATOR FAMILY ore_64_8_v1_term_btree_ops USING btree;
		CREATE OPERATOR CLASS ore_64_8_v1_term_btree_ops DEFAULT FOR TYPE ore_64_8_v1_term USING btree FAMILY ore_64_8_v1_term_btree_ops  AS
				OPERATOR 1 <,
				OPERATOR 2 <=,
				OPERATOR 3 =,
				OPERATOR 4 >=,
				OPERATOR 5 >,
				FUNCTION 1 compare_ore_64_8_v1_term(a ore_64_8_v1_term, b ore_64_8_v1_term);

		-- Compare the "head" of each array and recurse if necessary
		-- This function assumes an empty string is "less than" everything else
		-- so if a is empty we return -1, if be is empty and a isn't, we return 1.
		-- If both are empty we return 0. This cases probably isn't necessary as equality
		-- doesn't always make sense but it's here for completeness.
		-- If both are non-empty, we compare the first element. If they are equal
		-- we need to consider the next block so we recurse, otherwise we return the comparison result.
		CREATE OR REPLACE FUNCTION compare_ore_array(a ore_64_8_v1_term[], b ore_64_8_v1_term[]) returns integer AS $$
		DECLARE
			cmp_result integer;
		BEGIN
			IF (array_length(a, 1) = 0 OR a IS NULL) AND (array_length(b, 1) = 0 OR b IS NULL) THEN
			RETURN 0;
			END IF;
			IF array_length(a, 1) = 0 OR a IS NULL THEN
			RETURN -1;
			END IF;
			IF array_length(b, 1) = 0 OR a IS NULL THEN
			RETURN 1;
			END IF;

			cmp_result := compare_ore_64_8_v1_term(a[1], b[1]);
			IF cmp_result = 0 THEN
			-- Removes the first element in the array, and calls this fn again to compare the next element/s in the array.
			RETURN compare_ore_array(a[2:array_length(a,1)], b[2:array_length(b,1)]);
			END IF;

			RETURN cmp_result;
		END
		$$ LANGUAGE plpgsql;

		-- This function uses lexicographic comparison
		CREATE OR REPLACE FUNCTION compare_ore_64_8_v1(a ore_64_8_v1, b ore_64_8_v1) returns integer AS $$
		DECLARE
			cmp_result integer;
		BEGIN
			-- Recursively compare blocks bailing as soon as we can make a decision
			RETURN compare_ore_array(a.terms, b.terms);
		END
		$$ LANGUAGE plpgsql;

		CREATE OR REPLACE FUNCTION ore_64_8_v1_eq(a ore_64_8_v1, b ore_64_8_v1) RETURNS boolean AS $$
		SELECT compare_ore_64_8_v1(a, b) = 0
		$$ LANGUAGE SQL;

		CREATE OR REPLACE FUNCTION ore_64_8_v1_neq(a ore_64_8_v1, b ore_64_8_v1) RETURNS boolean AS $$
		SELECT compare_ore_64_8_v1(a, b) <> 0
		$$ LANGUAGE SQL;

		CREATE OR REPLACE FUNCTION ore_64_8_v1_lt(a ore_64_8_v1, b ore_64_8_v1) RETURNS boolean AS $$
		SELECT compare_ore_64_8_v1(a, b) = -1
		$$ LANGUAGE SQL;

		CREATE OR REPLACE FUNCTION ore_64_8_v1_lte(a ore_64_8_v1, b ore_64_8_v1) RETURNS boolean AS $$
		SELECT compare_ore_64_8_v1(a, b) != 1
		$$ LANGUAGE SQL;

		CREATE OR REPLACE FUNCTION ore_64_8_v1_gt(a ore_64_8_v1, b ore_64_8_v1) RETURNS boolean AS $$
		SELECT compare_ore_64_8_v1(a, b) = 1
		$$ LANGUAGE SQL;

		CREATE OR REPLACE FUNCTION ore_64_8_v1_gte(a ore_64_8_v1, b ore_64_8_v1) RETURNS boolean AS $$
		SELECT compare_ore_64_8_v1(a, b) != -1
		$$ LANGUAGE SQL;

		CREATE OPERATOR = (
		PROCEDURE="ore_64_8_v1_eq",
		LEFTARG=ore_64_8_v1,
		RIGHTARG=ore_64_8_v1,
		NEGATOR = <>,
		RESTRICT = eqsel,
		JOIN = eqjoinsel,
		HASHES,
		MERGES
		);

		CREATE OPERATOR <> (
		PROCEDURE="ore_64_8_v1_neq",
		LEFTARG=ore_64_8_v1,
		RIGHTARG=ore_64_8_v1,
		NEGATOR = =,
		RESTRICT = eqsel,
		JOIN = eqjoinsel,
		HASHES,
		MERGES
		);

		CREATE OPERATOR > (
		PROCEDURE="ore_64_8_v1_gt",
		LEFTARG=ore_64_8_v1,
		RIGHTARG=ore_64_8_v1,
		COMMUTATOR = <,
		NEGATOR = <=,
		RESTRICT = scalargtsel,
		JOIN = scalargtjoinsel
		);

		CREATE OPERATOR < (
		PROCEDURE="ore_64_8_v1_lt",
		LEFTARG=ore_64_8_v1,
		RIGHTARG=ore_64_8_v1,
		COMMUTATOR = >,
		NEGATOR = >=,
		RESTRICT = scalarltsel,
		JOIN = scalarltjoinsel
		);

		CREATE OPERATOR <= (
		PROCEDURE="ore_64_8_v1_lte",
		LEFTARG=ore_64_8_v1,
		RIGHTARG=ore_64_8_v1,
		COMMUTATOR = >=,
		NEGATOR = >,
		RESTRICT = scalarlesel,
		JOIN = scalarlejoinsel
		);

		CREATE OPERATOR >= (
		PROCEDURE="ore_64_8_v1_gte",
		LEFTARG=ore_64_8_v1,
		RIGHTARG=ore_64_8_v1,
		COMMUTATOR = <=,
		NEGATOR = <,
		RESTRICT = scalarlesel,
		JOIN = scalarlejoinsel
		);

		CREATE OPERATOR FAMILY ore_64_8_v1_btree_ops USING btree;
		CREATE OPERATOR CLASS ore_64_8_v1_btree_ops DEFAULT FOR TYPE ore_64_8_v1 USING btree FAMILY ore_64_8_v1_btree_ops  AS
				OPERATOR 1 <,
				OPERATOR 2 <=,
				OPERATOR 3 =,
				OPERATOR 4 >=,
				OPERATOR 5 >,
				FUNCTION 1 compare_ore_64_8_v1(a ore_64_8_v1, b ore_64_8_v1);

	`
	_, err := engine.Exec(sqlBlock)
	if err != nil {
		log.Fatalf("Could not execute migration: %v", err)
	}

	log.Println("Custom types installed!")
}

func installDslConfigFunction(engine *sql.DB) {
	sql := `
	--
	-- Configuration functions
	--
	--


	-- DROP and CREATE functions
	-- Function types cannot be changed after creation so we DROP for flexibility

	DROP FUNCTION IF EXISTS cs_add_column_v1(text, text);
	DROP FUNCTION IF EXISTS cs_remove_column_v1(text, text);
	DROP FUNCTION IF EXISTS cs_add_index_v1(text, text, text, jsonb);
	DROP FUNCTION IF EXISTS cs_remove_index_v1(text, text, text);
	DROP FUNCTION IF EXISTS cs_modify_index_v1(text, text, text, jsonb);

	DROP FUNCTION IF EXISTS cs_encrypt_v1();
	DROP FUNCTION IF EXISTS cs_activate_v1();
	DROP FUNCTION IF EXISTS cs_discard_v1();

	DROP FUNCTION IF EXISTS cs_refresh_encrypt_config();

	DROP FUNCTION IF EXISTS _cs_config_default();
	DROP FUNCTION IF EXISTS _cs_config_match_1_default();

	DROP FUNCTION IF EXISTS _cs_config_add_table(text, json);
	DROP FUNCTION IF EXISTS _cs_config_add_column(text, text, json);
	DROP FUNCTION IF EXISTS _cs_config_add_cast(text, text, text, json);
	DROP FUNCTION IF EXISTS _cs_config_add_index(text, text, text, json, json);


	CREATE FUNCTION _cs_config_default(config jsonb)
	RETURNS jsonb
	IMMUTABLE PARALLEL SAFE
	AS $$
	BEGIN
		IF config IS NULL THEN
		SELECT jsonb_build_object('v', 1, 'tables', jsonb_build_object()) INTO config;
		END IF;
		RETURN config;
	END;
	$$ LANGUAGE plpgsql;


	CREATE FUNCTION _cs_config_add_table(table_name text, config jsonb)
	RETURNS jsonb
	-- IMMUTABLE PARALLEL SAFE
	AS $$
	DECLARE
		tbl jsonb;
	BEGIN
		IF NOT config #> array['tables'] ? table_name THEN
		SELECT jsonb_build_object(table_name, jsonb_build_object()) into tbl;
		SELECT jsonb_set(config, array['tables'], tbl) INTO config;
		END IF;
		RETURN config;
	END;
	$$ LANGUAGE plpgsql;


	-- Add the column if it doesn't exist
	CREATE FUNCTION _cs_config_add_column(table_name text, column_name text, config jsonb)
	RETURNS jsonb
	IMMUTABLE PARALLEL SAFE
	AS $$
	DECLARE
		col jsonb;
	BEGIN
		IF NOT config #> array['tables', table_name] ? column_name THEN
		SELECT jsonb_build_object('indexes', jsonb_build_object()) into col;
		SELECT jsonb_set(config, array['tables', table_name, column_name], col) INTO config;
		END IF;
		RETURN config;
	END;
	$$ LANGUAGE plpgsql;

	-- Set the cast
	CREATE FUNCTION _cs_config_add_cast(table_name text, column_name text, cast_as text, config jsonb)
	RETURNS jsonb
	IMMUTABLE PARALLEL SAFE
	AS $$
	BEGIN
		SELECT jsonb_set(config, array['tables', table_name, column_name, 'cast_as'], to_jsonb(cast_as)) INTO config;
		RETURN config;
	END;
	$$ LANGUAGE plpgsql;


	-- Add the column if it doesn't exist
	CREATE FUNCTION _cs_config_add_index(table_name text, column_name text, index_name text, opts jsonb, config jsonb)
	RETURNS jsonb
	IMMUTABLE PARALLEL SAFE
	AS $$
	BEGIN
		SELECT jsonb_insert(config, array['tables', table_name, column_name, 'indexes', index_name], opts) INTO config;
		RETURN config;
	END;
	$$ LANGUAGE plpgsql;


	--
	-- Default options for match_1 index
	--
	CREATE FUNCTION _cs_config_match_1_default()
	RETURNS jsonb
	LANGUAGE sql STRICT PARALLEL SAFE
	BEGIN ATOMIC
	SELECT jsonb_build_object(
				'k', 6,
				'm', 2048,
				'include_original', true,
				'tokenizer', json_build_object('kind', 'ngram', 'token_length', 3),
				'token_filters', json_build_array(json_build_object('kind', 'downcase')));
	END;

	--
	--
	--
	CREATE FUNCTION cs_add_index_v1(table_name text, column_name text, index_name text, cast_as text DEFAULT 'text', opts jsonb DEFAULT '{}')
	RETURNS jsonb
	AS $$
	DECLARE
		o jsonb;
		_config jsonb;
	BEGIN

		-- set the active config
		SELECT data INTO _config FROM cs_configuration_v1 WHERE state = 'active' OR state = 'pending' ORDER BY state DESC;

		-- if index exists
		IF _config #> array['tables', table_name, column_name, 'indexes'] ?  index_name THEN
		RAISE EXCEPTION '% index exists for column: % %', index_name, table_name, column_name;
		END IF;

		IF NOT cast_as = ANY('{text, int, small_int, big_int, real, double, boolean, date}') THEN
		RAISE EXCEPTION '% is not a valid cast type', cast_as;
		END IF;

		-- set default config
		SELECT _cs_config_default(_config) INTO _config;

		SELECT _cs_config_add_table(table_name, _config) INTO _config;

		SELECT _cs_config_add_column(table_name, column_name, _config) INTO _config;

		SELECT _cs_config_add_cast(table_name, column_name, cast_as, _config) INTO _config;

		-- set default options for index if opts empty
		IF index_name = 'match_1' AND opts = '{}' THEN
		SELECT _cs_config_match_1_default() INTO opts;
		END IF;

		SELECT _cs_config_add_index(table_name, column_name, index_name, opts, _config) INTO _config;

		--  create a new pending record if we don't have one
		INSERT INTO cs_configuration_v1 (state, data) VALUES ('pending', _config)
		ON CONFLICT (state)
		WHERE state = 'pending'
		DO UPDATE
		SET data = _config;

		-- exeunt
		RETURN _config;
	END;
	$$ LANGUAGE plpgsql;


	CREATE FUNCTION cs_remove_index_v1(table_name text, column_name text, index_name text)
	RETURNS jsonb
	AS $$
	DECLARE
		_config jsonb;
	BEGIN

		-- set the active config
		SELECT data INTO _config FROM cs_configuration_v1 WHERE state = 'active' OR state = 'pending' ORDER BY state DESC;

		-- if no config
		IF _config IS NULL THEN
		RAISE EXCEPTION 'No active or pending configuration exists';
		END IF;

		-- if the table doesn't exist
		IF NOT _config #> array['tables'] ? table_name THEN
		RAISE EXCEPTION 'No configuration exists for table: %', table_name;
		END IF;

		-- if the index does not exist
		-- IF NOT _config->key ? index_name THEN
		IF NOT _config #> array['tables', table_name] ?  column_name THEN
		RAISE EXCEPTION 'No % index exists for column: % %', index_name, table_name, column_name;
		END IF;

		--  create a new pending record if we don't have one
		INSERT INTO cs_configuration_v1 (state, data) VALUES ('pending', _config)
		ON CONFLICT (state)
		WHERE state = 'pending'
		DO NOTHING;

		-- remove the index
		SELECT _config #- array['tables', table_name, column_name, 'indexes', index_name] INTO _config;

		-- if column is now empty, remove the column
		IF _config #> array['tables', table_name, column_name, 'indexes'] = '{}' THEN
		SELECT _config #- array['tables', table_name, column_name] INTO _config;
		END IF;

		-- if table  is now empty, remove the table
		IF _config #> array['tables', table_name] = '{}' THEN
		SELECT _config #- array['tables', table_name] INTO _config;
		END IF;

		-- if config empty delete
		-- or update the config
		IF _config #> array['tables'] = '{}' THEN
		DELETE FROM cs_configuration_v1 WHERE state = 'pending';
		ELSE
		UPDATE cs_configuration_v1 SET data = _config WHERE state = 'pending';
		END IF;

		-- exeunt
		RETURN _config;
	END;
	$$ LANGUAGE plpgsql;


	CREATE FUNCTION cs_modify_index_v1(table_name text, column_name text, index_name text, cast_as text DEFAULT 'text', opts jsonb DEFAULT '{}')
	RETURNS jsonb
	AS $$
	BEGIN
		PERFORM cs_remove_index_v1(table_name, column_name, index_name);
		RETURN cs_add_index_v1(table_name, column_name, index_name, cast_as, opts);
	END;
	$$ LANGUAGE plpgsql;


	CREATE FUNCTION cs_encrypt_v1()
	RETURNS boolean
	AS $$
		BEGIN
		-- IF NOT cs_ready_for_encryption_v1() THEN
		--   RAISE EXCEPTION 'Some pending columns do not have an encrypted target';
		-- END IF;

			IF NOT EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'pending') THEN
				RAISE EXCEPTION 'No pending configuration exists to encrypt';
			END IF;

		UPDATE cs_configuration_v1 SET state = 'encrypting' WHERE state = 'pending';
			RETURN true;
	END;
	$$ LANGUAGE plpgsql;


	CREATE OR REPLACE FUNCTION cs_activate_v1()
	RETURNS boolean
	AS $$
		BEGIN

		IF EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'encrypting') THEN
			UPDATE cs_configuration_v1 SET state = 'inactive' WHERE state = 'active';
				UPDATE cs_configuration_v1 SET state = 'active' WHERE state = 'encrypting';
				RETURN true;
			ELSE
				RAISE EXCEPTION 'No encrypting configuration exists to activate';
			END IF;
	END;
	$$ LANGUAGE plpgsql;


	CREATE OR REPLACE FUNCTION cs_discard_v1()
	RETURNS boolean
	AS $$
	BEGIN
		IF EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'pending') THEN
			DELETE FROM cs_configuration_v1 WHERE state = 'pending';
		RETURN true;
		ELSE
		RAISE EXCEPTION 'No pending configuration exists to discard';
		END IF;
	END;
	$$ LANGUAGE plpgsql;


	CREATE FUNCTION cs_add_column_v1(table_name text, column_name text)
	RETURNS jsonb
	AS $$
	DECLARE
		key text;
		_config jsonb;
	BEGIN
		-- set the active config
		SELECT data INTO _config FROM cs_configuration_v1 WHERE state = 'active' OR state = 'pending' ORDER BY state DESC;

		-- set default config
		SELECT _cs_config_default(_config) INTO _config;

		-- if index exists
		IF _config #> array['tables', table_name] ?  column_name THEN
		RAISE EXCEPTION 'Config exists for column: % %', table_name, column_name;
		END IF;

		SELECT _cs_config_add_table(table_name, _config) INTO _config;

		SELECT _cs_config_add_column(table_name, column_name, _config) INTO _config;

		--  create a new pending record if we don't have one
		INSERT INTO cs_configuration_v1 (state, data) VALUES ('pending', _config)
		ON CONFLICT (state)
		WHERE state = 'pending'
		DO UPDATE
		SET data = _config;

		-- exeunt
		RETURN _config;
	END;
	$$ LANGUAGE plpgsql;


	CREATE FUNCTION cs_remove_column_v1(table_name text, column_name text)
	RETURNS jsonb
	AS $$
	DECLARE
		key text;
		_config jsonb;
	BEGIN
		-- set the active config
		SELECT data INTO _config FROM cs_configuration_v1 WHERE state = 'active' OR state = 'pending' ORDER BY state DESC;

		-- if no config
		IF _config IS NULL THEN
		RAISE EXCEPTION 'No active or pending configuration exists';
		END IF;

		-- if the table doesn't exist
		IF NOT _config #> array['tables'] ? table_name THEN
		RAISE EXCEPTION 'No configuration exists for table: %', table_name;
		END IF;

		-- if the column does not exist
		IF NOT _config #> array['tables', table_name] ?  column_name THEN
		RAISE EXCEPTION 'No configuration exists for column: % %', table_name, column_name;
		END IF;

		--  create a new pending record if we don't have one
		INSERT INTO cs_configuration_v1 (state, data) VALUES ('pending', _config)
		ON CONFLICT (state)
		WHERE state = 'pending'
		DO NOTHING;

		-- remove the column
		SELECT _config #- array['tables', table_name, column_name] INTO _config;

		-- if table  is now empty, remove the table
		IF _config #> array['tables', table_name] = '{}' THEN
		SELECT _config #- array['tables', table_name] INTO _config;
		END IF;

		-- if config empty delete
		-- or update the config
		IF _config #> array['tables'] = '{}' THEN
		DELETE FROM cs_configuration_v1 WHERE state = 'pending';
		ELSE
		UPDATE cs_configuration_v1 SET data = _config WHERE state = 'pending';
		END IF;

		-- exeunt
		RETURN _config;

	END;
	$$ LANGUAGE plpgsql;

	CREATE FUNCTION cs_refresh_encrypt_config()
	RETURNS void
	LANGUAGE sql STRICT PARALLEL SAFE
	BEGIN ATOMIC
	RETURN NULL;
	END;

	`
	_, err := engine.Exec(sql)
	if err != nil {
		log.Fatalf("Error dsl config functions: %v", err)
	}

	log.Println("dsl config installed!")
}

func installDslConfigSchema(engine *sql.DB) {
	sql := `
		--
		-- Configuration Schema
		--
		--  Defines core config state and storage types
		--  Creates the cs_configuration_v1 table with constraint and unique indexes
		--
		--


		--
		-- cs_configuration_data_v1 is a jsonb column that stores the actuak configuration
		--
		-- For some reason CREATE DFOMAIN and CREATE TYPE do not support IF NOT EXISTS
		-- Types cannot be dropped if used by a table, and we never drop the configuration table
		-- DOMAIN constraints are added separately and not tied to DOMAIN creation
		--
		DO $$
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'cs_configuration_data_v1') THEN
			CREATE DOMAIN cs_configuration_data_v1 AS JSONB;
			END IF;
		END
		$$;

		--
		-- cs_configuration_state_v1 is an ENUM that defines the valid configuration states
		--
		DO $$
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'cs_configuration_state_v1') THEN
			CREATE TYPE cs_configuration_state_v1 AS ENUM ('active', 'inactive', 'encrypting', 'pending');
			END IF;
		END
		$$;

		--
		-- _cs_check_config_indexes returns true if the table configuration only includes valid index types
		--
		-- Used by the cs_configuration_data_v1_check constraint
		--
		-- Function types cannot be changed after creation so we always DROP & CREATE for flexibility
		--
		DROP FUNCTION IF EXISTS _cs_config_check_indexes(text, text);

		CREATE FUNCTION _cs_config_check_indexes(val jsonb)
		RETURNS BOOLEAN
		LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
		BEGIN ATOMIC
			SELECT jsonb_object_keys(jsonb_path_query(val, '$.tables.*.*.indexes')) = ANY('{match, ore, unique}');
		END;


		CREATE FUNCTION _cs_config_check_cast(val jsonb)
		RETURNS BOOLEAN
		LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
		BEGIN ATOMIC
		SELECT jsonb_array_elements_text(jsonb_path_query_array(val, '$.tables.*.*.cast_as')) = ANY('{text, int, small_int, big_int, real, double, boolean, date}');
		END;


		--
		-- Drop and reset the check constraint
		--
		ALTER DOMAIN cs_configuration_data_v1 DROP CONSTRAINT IF EXISTS cs_configuration_data_v1_check;

		ALTER DOMAIN cs_configuration_data_v1
		ADD CONSTRAINT cs_configuration_data_v1_check CHECK (
			VALUE ?& array['v', 'tables'] AND
			VALUE->'tables' <> '{}'::jsonb AND
			_cs_config_check_cast(VALUE) AND
			_cs_config_check_indexes(VALUE)
		);


		--
		-- CREATE the cs_configuration_v1 TABLE
		--
		CREATE TABLE IF NOT EXISTS cs_configuration_v1
		(
			id bigint GENERATED ALWAYS AS IDENTITY,
			state cs_configuration_state_v1 NOT NULL DEFAULT 'pending',
			data cs_configuration_data_v1,
			created_at timestamptz not null default current_timestamp,
			PRIMARY KEY(id)
		);

		--
		-- Define partial indexes to ensure that there is only one active, pending and encrypting config at a time
		--
		CREATE UNIQUE INDEX IF NOT EXISTS cs_configuration_v1_index_active ON cs_configuration_v1 (state) WHERE state = 'active';
		CREATE UNIQUE INDEX IF NOT EXISTS cs_configuration_v1_index_pending ON cs_configuration_v1 (state) WHERE state = 'pending';
		CREATE UNIQUE INDEX IF NOT EXISTS cs_configuration_v1_index_encrypting ON cs_configuration_v1 (state) WHERE state = 'encrypting';

	`
	_, err := engine.Exec(sql)
	if err != nil {
		log.Fatalf("Error dsl config schema: %v", err)
	}

	log.Println("dsl config schema installed!")
}

func installDslCore(engine *sql.DB) {
	sql := `
	DROP CAST IF EXISTS (text AS ore_64_8_v1_term);

	DROP FUNCTION IF EXISTS cs_match_v1;
	DROP FUNCTION IF EXISTS cs_match_v1_v0;
	DROP FUNCTION IF EXISTS cs_match_v1_v0_0;

	DROP FUNCTION IF EXISTS cs_unique_v1;
	DROP FUNCTION IF EXISTS cs_unique_v1_v0;
	DROP FUNCTION IF EXISTS cs_unique_v1_v0_0;

	DROP FUNCTION IF EXISTS cs_ore_64_8_v1;
	DROP FUNCTION IF EXISTS cs_ore_64_8_v1_v0;
	DROP FUNCTION IF EXISTS cs_ore_64_8_v1_v0_0;

	DROP FUNCTION IF EXISTS _cs_text_to_ore_64_8_v1_term_v1_0;

	DROP DOMAIN IF EXISTS cs_match_index_v1;
	DROP DOMAIN IF EXISTS cs_unique_index_v1;

	CREATE DOMAIN cs_match_index_v1 AS smallint[];
	CREATE DOMAIN cs_unique_index_v1 AS text;

	-- cs_encrypted_v1 is a column type and cannot be dropped if in use
	DO $$
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'cs_encrypted_v1') THEN
		CREATE DOMAIN cs_encrypted_v1 AS JSONB;
		END IF;
	END
	$$;

	DROP FUNCTION IF EXISTS _cs_encrypted_check_kind(jsonb);
	CREATE FUNCTION _cs_encrypted_check_kind(val jsonb)
	RETURNS BOOLEAN
	LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
	BEGIN ATOMIC
	RETURN (val->>'k' = 'ct' AND val ? 'c') AND NOT val ? 'p';
	END;


	-- drop and reset the check constraint
	ALTER DOMAIN cs_encrypted_v1 DROP CONSTRAINT IF EXISTS cs_encrypted_v1_check;

	ALTER DOMAIN cs_encrypted_v1
	ADD CONSTRAINT cs_encrypted_v1_check CHECK (
		-- version and source are required
		VALUE ?& array['v'] AND

		-- table and column
		VALUE->'i' ?& array['t', 'c'] AND

		-- plaintext or ciphertext for kind
		_cs_encrypted_check_kind(VALUE)

	);

	CREATE OR REPLACE FUNCTION cs_ciphertext_v1_v0_0(col jsonb)
		RETURNS text
	LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
	BEGIN ATOMIC
		RETURN col->>'c';
	END;

	CREATE OR REPLACE FUNCTION cs_ciphertext_v1_v0(col jsonb)
		RETURNS text
	LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
	BEGIN ATOMIC
		RETURN cs_ciphertext_v1_v0_0(col);
	END;

	CREATE OR REPLACE FUNCTION cs_ciphertext_v1(col jsonb)
		RETURNS text
	LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
	BEGIN ATOMIC
		RETURN cs_ciphertext_v1_v0_0(col);
	END;

	-- extracts match index from an emcrypted column
	CREATE OR REPLACE FUNCTION cs_match_v1_v0_0(col jsonb)
	RETURNS cs_match_index_v1
	LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
	BEGIN ATOMIC
		SELECT ARRAY(SELECT jsonb_array_elements(col->'m'))::cs_match_index_v1;
	END;

	CREATE OR REPLACE FUNCTION cs_match_v1_v0(col jsonb)
	RETURNS cs_match_index_v1
	LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
	BEGIN ATOMIC
		RETURN cs_match_v1_v0_0(col);
	END;

	CREATE OR REPLACE FUNCTION cs_match_v1(col jsonb)
	RETURNS cs_match_index_v1
	LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
	BEGIN ATOMIC
		RETURN cs_match_v1_v0_0(col);
	END;

	-- extracts unique index from an encrypted column
	CREATE OR REPLACE FUNCTION cs_unique_v1_v0_0(col jsonb)
	RETURNS cs_unique_index_v1
	LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
	BEGIN ATOMIC
		RETURN col->>'u';
	END;

	CREATE OR REPLACE FUNCTION cs_unique_v1_v0(col jsonb)
	RETURNS cs_unique_index_v1
	LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
	BEGIN ATOMIC
		RETURN cs_unique_v1_v0_0(col);
	END;

	CREATE OR REPLACE FUNCTION cs_unique_v1(col jsonb)
	RETURNS cs_unique_index_v1
	LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
	BEGIN ATOMIC
		RETURN cs_unique_v1_v0_0(col);
	END;

	-- casts text to ore_64_8_v1_term (bytea)
	CREATE FUNCTION _cs_text_to_ore_64_8_v1_term_v1_0(t text)
	RETURNS ore_64_8_v1_term
	LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
	BEGIN ATOMIC
		RETURN t::bytea;
	END;

	-- cast to cleanup ore_64_8_v1 extraction
	CREATE CAST (text AS ore_64_8_v1_term)
		WITH FUNCTION _cs_text_to_ore_64_8_v1_term_v1_0(text) AS IMPLICIT;

	-- extracts ore index from an encrypted column
	CREATE FUNCTION cs_ore_64_8_v1_v0_0(val jsonb)
	RETURNS ore_64_8_v1
	LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
	BEGIN ATOMIC
	SELECT (val->>'o')::ore_64_8_v1;
	END;

	CREATE FUNCTION cs_ore_64_8_v1_v0(col jsonb)
	RETURNS ore_64_8_v1
	LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
	BEGIN ATOMIC
		RETURN cs_ore_64_8_v1_v0_0(col);
	END;

	CREATE FUNCTION cs_ore_64_8_v1(col jsonb)
	RETURNS ore_64_8_v1
	LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
	BEGIN ATOMIC
		RETURN cs_ore_64_8_v1_v0_0(col);
	END;

	`
	_, err := engine.Exec(sql)
	if err != nil {
		log.Fatalf("Error dsl core: %v", err)
	}

	log.Println("dsl core installed!")
}

func installDslEncryptIndex(engine *sql.DB) {
	sql := `
	-- DROP and CREATE functions
	-- Function types cannot be changed after creation so we DROP for flexibility
	DROP FUNCTION IF EXISTS cs_select_pending_columns_v1;
	DROP FUNCTION IF EXISTS cs_select_target_columns_v1;
	DROP FUNCTION IF EXISTS cs_count_encrypted_with_active_config_v1;
	DROP FUNCTION IF EXISTS cs_create_encrypted_columns_v1();
	DROP FUNCTION IF EXISTS cs_rename_encrypted_columns_v1();

	DROP FUNCTION IF EXISTS _cs_diff_config_v1;
	DROP FUNCTION IF EXISTS _cs_table_from_config_key;
	DROP FUNCTION IF EXISTS _cs_column_from_config_key;


	-- Return the diff of two configurations
	-- Returns the set of keys in a that have different values to b
	-- The json comparison is on object values held by the key
	CREATE OR REPLACE FUNCTION _cs_diff_config_v1(a JSONB, b JSONB)
		RETURNS TABLE(table_name TEXT, column_name TEXT)
	IMMUTABLE STRICT PARALLEL SAFE
	AS $$
	BEGIN
		RETURN QUERY
		WITH table_keys AS (
		SELECT jsonb_object_keys(a->'tables') AS key
		UNION
		SELECT jsonb_object_keys(b->'tables') AS key
		),
		column_keys AS (
		SELECT tk.key AS table_key, jsonb_object_keys(a->'tables'->tk.key) AS column_key
		FROM table_keys tk
		UNION
		SELECT tk.key AS table_key, jsonb_object_keys(b->'tables'->tk.key) AS column_key
		FROM table_keys tk
		)
		SELECT
		ck.table_key AS table_name,
		ck.column_key AS column_name
		FROM
		column_keys ck
		WHERE
		(a->'tables'->ck.table_key->ck.column_key IS DISTINCT FROM b->'tables'->ck.table_key->ck.column_key);
	END;
	$$ LANGUAGE plpgsql;


	-- Returns the set of columns with pending configuration changes
	-- Compares the columns in pending configuration that do not match the active config
	CREATE FUNCTION cs_select_pending_columns_v1()
		RETURNS TABLE(table_name TEXT, column_name TEXT)
	AS $$
		DECLARE
			active JSONB;
			pending JSONB;
			config_id BIGINT;
		BEGIN
			SELECT data INTO active FROM cs_configuration_v1 WHERE state = 'active';

			-- set default config
		IF active IS NULL THEN
		active := '{}';
		END IF;

			SELECT id, data INTO config_id, pending FROM cs_configuration_v1 WHERE state = 'pending';

			-- set default config
			IF config_id IS NULL THEN
				RAISE EXCEPTION 'No pending configuration exists to encrypt';
			END IF;

			RETURN QUERY
			SELECT d.table_name, d.column_name FROM _cs_diff_config_v1(active, pending) as d;
		END;
	$$ LANGUAGE plpgsql;


	CREATE FUNCTION cs_select_target_columns_v1()
		RETURNS TABLE(table_name TEXT, column_name TEXT, target_column TEXT)
		STABLE STRICT PARALLEL SAFE
	AS $$
	SELECT
		c.table_name,
		c.column_name,
		s.column_name as target_column
	FROM
		cs_select_pending_columns_v1() c
	LEFT JOIN information_schema.columns s ON
		s.table_name = c.table_name AND
		(s.column_name = c.table_name OR s.column_name = c.column_name || '_encrypted') AND
		s.domain_name = 'cs_encrypted_v1';
	$$ LANGUAGE sql;


	--
	-- Returns true if all pending columns have a target (encrypted) column
	CREATE FUNCTION cs_ready_for_encryption_v1()
		RETURNS BOOLEAN
		STABLE STRICT PARALLEL SAFE
	AS $$
		SELECT EXISTS (
		SELECT *
		FROM cs_select_target_columns_v1() AS c
		WHERE c.target_column IS NOT NULL);
	$$ LANGUAGE sql;


	CREATE FUNCTION cs_create_encrypted_columns_v1()
		RETURNS TABLE(table_name TEXT, column_name TEXT)
	AS $$
		BEGIN
		FOR table_name, column_name IN
		SELECT c.table_name, (c.column_name || '_encrypted') FROM cs_select_target_columns_v1() AS c WHERE c.target_column IS NULL
		LOOP
			EXECUTE format('ALTER TABLE %I ADD column %I cs_encrypted_v1', table_name, column_name);
		RETURN NEXT;
		END LOOP;
		END;
	$$ LANGUAGE plpgsql;


	CREATE FUNCTION cs_rename_encrypted_columns_v1()
		RETURNS TABLE(table_name TEXT, column_name TEXT, target_column TEXT)
	AS $$
		BEGIN
		FOR table_name, column_name, target_column IN
		SELECT * FROM cs_select_target_columns_v1() as c WHERE c.target_column = c.column_name || '_encrypted'
		LOOP
			EXECUTE format('ALTER TABLE %I RENAME %I TO %I;', table_name, column_name, column_name || '_plaintext');
			EXECUTE format('ALTER TABLE %I RENAME %I TO %I;', table_name, target_column, column_name);
		RETURN NEXT;
		END LOOP;
		END;
	$$ LANGUAGE plpgsql;


	CREATE FUNCTION cs_count_encrypted_with_active_config_v1(table_name TEXT, column_name TEXT)
	RETURNS BIGINT
	AS $$
	DECLARE
	result BIGINT;
	BEGIN
		EXECUTE format(
			'SELECT COUNT(%I) FROM %s t WHERE %I->>%L = (SELECT id::TEXT FROM cs_configuration_v1 WHERE state = %L)',
			column_name, table_name, column_name, 'v', 'active'
		)
		INTO result;
		RETURN result;
	END;
	$$ LANGUAGE plpgsql;

	`

	_, err := engine.Exec(sql)
	if err != nil {
		log.Fatalf("Error dsl encrypt index: %v", err)
	}

	log.Println("dsl encrypt index installed!")
}

func installDslMatch(engine *sql.DB) {
	sql := `
		-- find id of the encrypting configuration
		CREATE OR REPLACE FUNCTION _cs_encrypting_config_v1()
		RETURNS BIGINT
		LANGUAGE sql STABLE STRICT PARALLEL SAFE
		BEGIN ATOMIC
			SELECT id FROM cs_configuration_v1 WHERE state = 'encrypting';
		END;



		--
		-- find id of the encrypting configuration
		-- compares to the version of this column
		-- if column has been upgraded
		CREATE OR REPLACE FUNCTION _cs_match_v1_from_json(col jsonb)
		RETURNS JSONB
		LANGUAGE sql STABLE STRICT PARALLEL SAFE
		BEGIN ATOMIC
			SELECT m.idx FROM (
				SELECT v,
					CASE WHEN v = (col->>'v')::BIGINT THEN
						col->'m'->-2
					ELSE
						col->'m'->-1
				END as idx
				FROM _cs_encrypting_config_v1() as v
			) as m;
		END;


		CREATE OR REPLACE FUNCTION cs_match_v1(col jsonb)
		RETURNS cs_match_index_v1
		LANGUAGE sql STABLE STRICT PARALLEL SAFE
		BEGIN ATOMIC
			SELECT ARRAY(SELECT jsonb_array_elements(_cs_match_v1_from_json(col)))::cs_match_index_v1;
		END;


		SELECT cs_match_v1('{
			"v": 10,
			"m": [
				[1], [2]
			]

		}'::jsonb);

	`

	_, err := engine.Exec(sql)
	if err != nil {
		log.Fatalf("Error dsl match: %v", err)
	}

	log.Println("dsl match installed!")
}
