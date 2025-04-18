package main

import (
	"database/sql"
	"log"
)

// We need to add constraints on any column that is encrypted.
// This checks that all the required json fields are present, and that the data has been encrypted
// by the proxy before inserting.
// If this is not the case, then we will receive a postgres constraint violation.
func AddConstraint(engine *sql.DB) {
	sql := `
	ALTER TABLE goexamples ADD CONSTRAINT encrypted_text_field_encrypted_check
	CHECK ( cs_check_encrypted_v1(encrypted_text_field) );

	ALTER TABLE goexamples ADD CONSTRAINT encrypted_jsonb_encrypted_check
	CHECK ( cs_check_encrypted_v1(encrypted_jsonb_field) );

	ALTER TABLE goexamples ADD CONSTRAINT encrypted_int_encrypted_check
	CHECK ( cs_check_encrypted_v1(encrypted_int_field) );

	ALTER TABLE goexamples ADD CONSTRAINT encrypted_bool_encrypted_check
	CHECK ( cs_check_encrypted_v1(encrypted_bool_field) );
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
	  SELECT cs_add_index_v1('goexamples', 'encrypted_text_field', 'unique', 'text', '{"token_filters": [{"kind": "downcase"}]}');
      SELECT cs_add_index_v1('goexamples', 'encrypted_text_field', 'match', 'text');
      SELECT cs_add_index_v1('goexamples', 'encrypted_text_field', 'ore', 'text');
      SELECT cs_add_index_v1('goexamples', 'encrypted_int_field', 'ore', 'int');
	  SELECT cs_add_index_v1('goexamples', 'encrypted_jsonb_field', 'ste_vec', 'jsonb', '{"prefix": "goexamples/encrypted_jsonb_field"}');
      SELECT cs_add_index_v1('goexamples', 'encrypted_bool_field', 'ore', 'boolean');

	  CREATE UNIQUE INDEX ON goexamples(cs_unique_v1(encrypted_text_field));
      CREATE INDEX ON goexamples USING GIN (cs_match_v1(encrypted_text_field));
      CREATE INDEX ON goexamples (cs_ore_64_8_v1(encrypted_text_field));
      -- CREATE INDEX ON goexamples USING GIN (cs_ste_vec_v1(encrypted_jsonb_field));
	  CREATE INDEX ON goexamples (cs_ore_64_8_v1(encrypted_int_field));
	  CREATE INDEX ON goexamples (cs_ore_64_8_v1(encrypted_bool_field));

      SELECT cs_encrypt_v1();
      SELECT cs_activate_v1();
	`

	_, err := engine.Exec(sql)
	if err != nil {
		log.Fatalf("Error adding indexes: %v", err)
	}

	log.Println("indexes updated")
}
