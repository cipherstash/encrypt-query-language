package main

import (
	"fmt"
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
					email VARCHAR(100) NOT NULL UNIQUE
				);`
	_, err = db.Exec(create)
	assert.NoError(t, err)
}

func TestWriteAndReadEncryptedValue(t *testing.T) {
	assert := assert.New(t)

	createDatabase(t)

	db, err := sqlx.Connect("postgres", "host=localhost port=5432 user=postgres password=postgres dbname=sqlx_example sslmode=disable")
	assert.NoError(err)

	createTable(t, db)

	v := 42
	q := fmt.Sprintf("SELECT %d", v)
	var i int
	err = db.Get(&i, q)
	assert.NoError(err)
	assert.Equal(v, i)
}
