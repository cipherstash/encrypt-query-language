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
// Run: go run main.go migrations.go example_queries.go

// Create types for encrypted column
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

// database data to encrypted column
func (ec *EncryptedColumn) FromDB(data []byte) error {
	return json.Unmarshal(data, ec)
}

// encrypted column to database data
func (ec *EncryptedColumn) ToDB() ([]byte, error) {
	return json.Marshal(ec)
}

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

	// Query on unencrypted column: where clause
	WhereQuery(devEngine)

	// Query on encrypted column.

	// // MATCH
	MatchQueryLongString(devEngine)

	MatchQueryEmail(devEngine)

	// JSONB data query
	JsonbQuery(devEngine)
	// ORE

	// Unique
}
