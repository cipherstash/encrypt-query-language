package main

import (
	"fmt"
	"os"
	"testing"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
	"github.com/stretchr/testify/assert"
)

func createDatabase(t *testing.T) {
	db, err := sqlx.Connect("postgres", "host=localhost port=5432 user=postgres password=postgres dbname=postgres sslmode=disable")
	assert.NoError(t, err)

	check := "SELECT 1 FROM pg_database WHERE datname = 'sqlx_example';"
	var i int
	err = db.Get(&i, check)
	assert.NoError(t, err)
	if i == 1 {
		create := "DROP DATABASE sqlx_example;"
		_, err = db.Exec(create)
		assert.NoError(t, err)
	}

	create := "CREATE DATABASE sqlx_example;"
	_, err = db.Exec(create)
	assert.NoError(t, err)
}

func createTable(t *testing.T, db *sqlx.DB) {
	check := "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users';"
	var i int
	err := db.Get(&i, check)
	if err == nil {
		create := "DROP TABLE users;"
		_, err = db.Exec(create)
		assert.NoError(t, err)
	}

	create := `CREATE TABLE users (
					id SERIAL PRIMARY KEY,
					first_name VARCHAR(50) NOT NULL,
					last_name VARCHAR(50) NOT NULL,
					date_of_birth DATE NOT NULL,
					email VARCHAR(100) NOT NULL UNIQUE,
					admin BOOL NOT NULL
				);`
	_, err = db.Exec(create)
	assert.NoError(t, err)
}

func installEQL(t *testing.T, db *sqlx.DB) {
	path := "cipherstash-eql-install.sql"
	sql, err := os.ReadFile(path)
	assert.NoError(t, err, "try running `make fetch_eql`")

	result, err := db.Exec(string(sql))
	assert.NoError(t, err)
	t.Logf("result: %+v\n", result)

	// verify functions are available and working
	result, err = db.Exec("SELECT cs_refresh_encrypt_config();")
	t.Logf("result: %+v\n", result)
	assert.NoError(t, err)
}

func addEncryptionIndexes(t *testing.T, db *sqlx.DB) {
	sql := `
	  SELECT cs_add_index_v1('users', 'first_name', 'unique', 'text', '{"token_filters": [{"kind": "downcase"}]}');
      SELECT cs_add_index_v1('users', 'first_name', 'match', 'text');
      SELECT cs_add_index_v1('users', 'first_name', 'ore', 'text');

	  SELECT cs_add_index_v1('users', 'last_name', 'unique', 'text', '{"token_filters": [{"kind": "downcase"}]}');
      SELECT cs_add_index_v1('users', 'last_name', 'match', 'text');
      SELECT cs_add_index_v1('users', 'last_name', 'ore', 'text');

      SELECT cs_add_index_v1('users', 'email', 'match', 'text');
      SELECT cs_add_index_v1('users', 'email', 'ore', 'text');

      SELECT cs_add_index_v1('users', 'date_of_birth', 'ore', 'int');

      SELECT cs_add_index_v1('users', 'admin', 'ore', 'boolean');

      SELECT cs_encrypt_v1();
      SELECT cs_activate_v1();
	`

	result, err := db.Exec(sql)
	t.Logf("result: %+v\n", result)
	assert.NoError(t, err)
}

func TestWriteAndReadEncryptedValue(t *testing.T) {
	assert := assert.New(t)

	createDatabase(t)

	db, err := sqlx.Connect("postgres", "host=localhost port=5432 user=postgres password=postgres dbname=sqlx_example sslmode=disable")
	assert.NoError(err)

	createTable(t, db)
	installEQL(t, db)
	addEncryptionIndexes(t, db)

	v := 42
	q := fmt.Sprintf("SELECT %d", v)
	var i int
	err = db.Get(&i, q)
	assert.NoError(err)
	assert.Equal(v, i)
}
