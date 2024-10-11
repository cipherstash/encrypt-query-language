package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"

	_ "github.com/jackc/pgx/stdlib" // PostgreSQL driver
	"xorm.io/xorm"
	"xorm.io/xorm/names"
)

// To setup postgres:
// Run: docker compose up
// To run examples
// Run: go run .

// Create types for encrypted column
//
// EQL expects a json format that looks like this:
// '{"k":"pt","p":"a string representation of the plaintext that is being encrypted","i":{"t":"table","c":"column"},"v":1}'
//
// Creating a go struct to represent this shape in an app.
// Stored as jsonb in the db
type TableColumn struct {
	T string `json:"t"` // This maps T to t in the json
	C string `json:"c"`
}

type EncryptedColumn struct {
	K string      `json:"k"`
	P string      `json:"p"`
	I TableColumn `json:"i"`
	V int         `json:"v"`
}

type Example struct {
	Id             int64           `xorm:"pk autoincr"`
	Text           string          `xorm:"varchar(100)"`
	EncryptedText  EncryptedColumn `json:"encrypted_text" xorm:"jsonb 'encrypted_text'"`
	EncryptedJsonb EncryptedColumn `json:"encrypted_jsonb" xorm:"jsonb 'encrypted_jsonb'"`
}

func (Example) TableName() string {
	return "examples"
}

// Using the conversion interface so EncryptedColumn structs are converted to json when being inserted
// and converting back to EncryptedColumn when retrieved.

func (ec *EncryptedColumn) FromDB(data []byte) error {
	return json.Unmarshal(data, ec)
}

func (ec *EncryptedColumn) ToDB() ([]byte, error) {
	return json.Marshal(ec)
}

// Converts a plaintext value to a string and returns the EncryptedColumn struct to use to insert into the db.
func serialize(value any, table string, column string) EncryptedColumn {
	str, err := convertToString(value)
	if err != nil {
		fmt.Println("Error:", err)
	}

	data := EncryptedColumn{"pt", str, TableColumn{table, column}, 1}

	return data
}

func convertToString(value any) (string, error) {
	switch v := value.(type) {
	case string:
		return v, nil
	case int:
		return fmt.Sprintf("%d", v), nil
	case float64:
		return fmt.Sprintf("%f", v), nil
	case map[string]interface{}:
		jsonData, err := json.Marshal(v)
		if err != nil {
			return "", fmt.Errorf("error marshaling JSON: %v", err)
		}
		return string(jsonData), nil
	default:
		return "", fmt.Errorf("unsupported type: %T", v)
	}
}

func setupDb() {
	connStr := "user=postgres password=postgres port=5432 host=localhost dbname=postgres sslmode=disable"
	engine, err := xorm.NewEngine("pgx", connStr)

	if err != nil {
		log.Fatalf("Could not connect to the database: %v", err)
	}

	var exists bool
	_, err = engine.SQL("SELECT EXISTS (SELECT datname FROM pg_catalog.pg_database WHERE datname = 'gotest')").Get(&exists)
	if err != nil {
		log.Fatalf("Error: %v", err)
	}

	if exists {
		_, err = engine.Exec("DROP DATABASE gotest WITH (FORCE);")
		if err != nil {
			log.Fatalf("Could not drop database: %v", err)
		}
		fmt.Println("Database 'gotest' dropped successfully!")

		_, err = engine.Exec("CREATE DATABASE gotest;")
		if err != nil {
			log.Fatalf("Could not create database: %v", err)
		}
		fmt.Println("Database 'gotest' recreated!")
	} else {
		fmt.Println("Database 'gotest' doesn't exist. Creating...")
		_, err = engine.Exec("CREATE DATABASE gotest;")
		if err != nil {
			log.Fatalf("Could not create database: %v", err)
		}
		fmt.Println("Database 'gotest' created successfully!")
	}

	engine.Close()
}

func createTable() {
	connStr := "user=postgres password=postgres port=5432 host=localhost dbname=gotest sslmode=disable"
	engine, err := xorm.NewEngine("pgx", connStr)

	if err != nil {
		log.Fatalf("Could not connect to gotest database: %v", err)
	}

	// need to map from struct to postgres snake case lowercase
	engine.SetMapper(names.SnakeMapper{})
	engine.ShowSQL(true)

	err = engine.Sync(new(Example))
	if err != nil {
		log.Fatalf("Could not create examples table: %v", err)
	}

	fmt.Println("Examples table synced successfully!")
	engine.Close()
}

func installEql() {
	connStr := "user=postgres password=postgres port=5432 host=localhost dbname=gotest sslmode=disable"
	// Install Eql, custom types, indexes and constraints
	// To install our custom types we need to use the database/sql package due to an issue
	// with how xorm interprets `?`.
	// https://gitea.com/xorm/xorm/issues/2483
	engine, err := sql.Open("pgx", connStr)
	if err != nil {
		log.Fatalf("Could not connect to the database: %v", err)
	}
	InstallEql(engine)
	AddIndexes(engine)
	AddConstraint(engine)

	// Refresh config with
	engine.Exec("SELECT cs_refresh_encrypt_config();")
	engine.Close()

}

func main() {
	// Recreate gotest db on each run
	setupDb()

	// Connect to go test directly and create table
	createTable()

	// Install EQL and add config
	installEql()

	// Connect to proxy
	proxyConnStr := "user=postgres password=postgres port=6432 host=localhost dbname=gotest sslmode=disable"
	proxyEngine, err := xorm.NewEngine("pgx", proxyConnStr)

	if err != nil {
		log.Fatalf("Could not connect to the database: %v", err)
	}
	// Query on unencrypted column: where clause
	WhereQuery(proxyEngine)

	// Query on encrypted columns.
	// // MATCH
	MatchQueryLongString(proxyEngine)
	MatchQueryEmail(proxyEngine)

	// JSONB data query
	JsonbQuerySimple(proxyEngine)
	JsonbQueryDeepNested(proxyEngine)
	// ORE
	// Unique
}
