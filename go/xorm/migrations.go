package main

import (
	"database/sql"
	"log"
	"os"
)

func InstallEql(engine *sql.DB) {
	log.Println("Start installing custom types and function")
	installCsCustomTypes(engine)

	installDsl(engine)

}

// These are our base custom types and functions for ore search.
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

// Installing EQL
func installDsl(engine *sql.DB) {
	path := "./cipherstash-encrypt-dsl.sql"
	sql, err := os.ReadFile(path)
	if err != nil {
		log.Fatalf("Failed to read SQL file: %v", err)
	}

	_, err = engine.Exec(string(sql))
	if err != nil {
		log.Fatalf("Failed to execute SQL query: %v", err)
	}
}

// We need to add constraints on any column that is encrypted.
// This checks that all the required json fields are present, and that the data has been encrypted
// by the proxy before inserting.
// If this is not the case, then we will receive a postgres constraint violation.
func AddConstraint(engine *sql.DB) {
	sql := `
	ALTER TABLE examples ADD CONSTRAINT encrypted_text_encrypted_check
	CHECK ( cs_check_encrypted_v1(encrypted_text) );

	ALTER TABLE examples ADD CONSTRAINT encrypted_jsonb_encrypted_check
	CHECK ( cs_check_encrypted_v1(encrypted_jsonb) );
	`

	_, err := engine.Exec(sql)
	if err != nil {
		log.Fatalf("Failed to execute SQL query to add constraint: %v", err)
	}

	log.Println("constraints added")
}

// This adds the indexes for each column.
// This configuration is needed to determine how the data is encrypted and how you can query
func AddIndexes(engine *sql.DB) {
	sql := `
	  SELECT cs_add_index_v1('examples', 'encrypted_text', 'unique', 'text', '{"token_filters": [{"kind": "downcase"}]}');
      SELECT cs_add_index_v1('examples', 'encrypted_text', 'match', 'text', '{"token_filters": [{"kind": "downcase"}], "tokenizer": { "kind": "ngram", "token_length": 3 }}');
      SELECT cs_add_index_v1('examples', 'encrypted_text', 'ore', 'text');
	  SELECT cs_add_index_v1('examples', 'encrypted_jsonb', 'ste_vec', 'jsonb', '{"prefix": "some-prefix"}');

	  CREATE UNIQUE INDEX ON examples(cs_unique_v1(encrypted_text));
      CREATE INDEX ON examples USING GIN (cs_match_v1(encrypted_text));
      CREATE INDEX ON examples (cs_ore_64_8_v1(encrypted_text));
      CREATE INDEX ON examples USING GIN (cs_ste_vec_v1(encrypted_jsonb));

      SELECT cs_encrypt_v1();
      SELECT cs_activate_v1();
	`

	_, err := engine.Exec(sql)
	if err != nil {
		log.Fatalf("Error adding indexes: %v", err)
	}

	log.Println("config updated")
}
