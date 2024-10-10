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

// To install types etc and run insert and query example:
// Run: go run main.go migrations.go

// Create types for encrypted column
type TableColumn struct {
	T string `json:"t"` // This maps T to t in the json
	C string `json:"c"`
}

type EncryptedColumn struct {
	K string      `json:"k"`
	P any         `json:"p"`
	I TableColumn `json:"i"`
	V int         `json:"v"`
}

type Example struct {
	Id            int64           `xorm:"pk autoincr"`
	Text          string          `xorm:"varchar(100)"`
	EncryptedText json.RawMessage `json:"encrypted_text" xorm:"jsonb 'encrypted_text'"`
	// DecryptedText  string          `xorm:"-"` // This ignores the field and only uses it in memory for the struct. It does not create a field in the table.
	EncryptedJsonb json.RawMessage `json:"encrypted_jsonb" xorm:"jsonb 'encrypted_jsonb'"`
}

func (Example) TableName() string {
	return "examples"
}

// func (e *Example) AfterSet(colName string, _ xorm.Cell) {
// 	if colName == "encrypted_text" && len(e.EncryptedText) > 0 {

// 		text, err := deserialize(e.EncryptedText)
// 		if err == nil {
// 			e.DecryptedText = text
// 		}
// 	}
// }

func serialize(value any, table string, column string) (json.RawMessage, error) {
	data := EncryptedColumn{"pt", value, TableColumn{table, column}, 1}

	jsonData, err := json.Marshal(data)
	if err != nil {
		return nil, fmt.Errorf("failed to serialize data: %v", err)
	}

	return json.RawMessage(jsonData), nil
}

// func deserialize(data []byte) (string, error) {
// 	var encryptedColumn EncryptedColumn
// 	err := json.Unmarshal(data, &encryptedColumn)

// 	if err != nil {
// 		return "", fmt.Errorf("failed to serialize data: %v", err)
// 	}

// 	return encryptedColumn.P, nil
// }

func main() {
	// Create database
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

	// Connect to proxy
	devConnStr := "user=postgres password=postgres port=6432 host=localhost dbname=gotest sslmode=disable"
	devEngine, err := xorm.NewEngine("pgx", devConnStr)

	if err != nil {
		log.Fatalf("Could not connect to the database: %v", err)
	}

	// need to map from struct to postgres snake case lowercase
	devEngine.SetMapper(names.SnakeMapper{})
	devEngine.ShowSQL(true)

	// Create table
	err = devEngine.Sync2(new(Example))
	if err != nil {
		log.Fatalf("Could not create examples table: %v", err)
	}

	// To install our custom types we need to use the database/sql package due to an issue
	// with how xorm interprets `?`.
	// https://gitea.com/xorm/xorm/issues/2483
	typesConn := "user=postgres password=postgres port=5432 host=localhost dbname=gotest sslmode=disable"
	typesEngine, err := sql.Open("pgx", typesConn)
	if err != nil {
		log.Fatalf("Could not connect to the database: %v", err)
	}

	InstallEql(typesEngine)
	AddIndexes(typesEngine)
	AddConstraint(typesEngine)

	devEngine.Exec("SELECT cs_refresh_encrypt_config();")

	// // Query on unencrypted column: where clause
	// WhereQuery(devEngine)

	// // Query on encrypted column.

	// // // MATCH
	// MatchQueryLongString(devEngine)

	// MatchQueryEmail(devEngine)

	// JSONB data query
	JsonbQuery(devEngine)
	// ORE

	// Unique
}
