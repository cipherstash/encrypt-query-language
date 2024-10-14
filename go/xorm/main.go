package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"strconv"

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
// Creating a go struct to represent this shape to use for serialization.
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

// Creating custom types for encrypted fields
// This way we can use the conversion interface to convert from the type used in the app, to
// the underlying jsonb shape that EQL expects
// '{"k":"pt","p":"a string representation of the plaintext that is being encrypted","i":{"t":"table","c":"column"},"v":1}'
// And then be able to convert back from the EQL jsonb shape back to the expected type to be used in the Go app.
type EncryptedText string
type EncryptedJsonb map[string]interface{}
type EncryptedInt int
type EncryptedBool bool

// type EncryptedDate time.Time

type Example struct {
	Id                int64          `xorm:"pk autoincr"`
	NonEncryptedField string         `xorm:"varchar(100)"`
	EncryptedText     EncryptedText  `json:"encrypted_text" xorm:"jsonb 'encrypted_text'"`
	EncryptedJsonb    EncryptedJsonb `json:"encrypted_jsonb" xorm:"jsonb 'encrypted_jsonb'"`
	EncryptedInt      EncryptedInt   `json:"encrypted_int" xorm:"jsonb 'encrypted_int'"`
	EncryptedBool     EncryptedBool  `json:"encrypted_bool" xorm:"jsonb 'encrypted_bool'"`
	// EncryptedDate     EncryptedDate  `json:"encrypted_date" xorm:"jsonb 'encrypted_date'"`
}

func (Example) TableName() string {
	return "examples"
}

// Using the conversion interface so Encrypted* structs are converted to json when being inserted
// and converting back to the original type when retrieved.
// TODO: move these out to a separate module

// encrypted text conversion
func (et *EncryptedText) FromDB(data []byte) error {
	var jsonData map[string]interface{}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		return err
	}
	fmt.Println("json data", jsonData)
	if pValue, ok := jsonData["p"].(string); ok {
		*et = EncryptedText(pValue)
		return nil
	}

	return fmt.Errorf("invalid format: missing 'p' field in JSONB")
}

func (et EncryptedText) ToDB() ([]byte, error) {
	val := serialize(string(et), "examples", "encrypted_text")
	return json.Marshal(val)
}

// Encrypted jsonb conversion
func (ej *EncryptedJsonb) FromDB(data []byte) error {
	var jsonData map[string]interface{}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		return err
	}

	if pValue, ok := jsonData["p"].(string); ok {
		var pData map[string]interface{}
		if err := json.Unmarshal([]byte(pValue), &pData); err != nil {
			return fmt.Errorf("error unmarshaling 'p' JSON string: %v", err)
		}

		*ej = EncryptedJsonb(pData)
		return nil
	}

	return fmt.Errorf("invalid format: missing 'p' field in JSONB")
}

func (ej EncryptedJsonb) ToDB() ([]byte, error) {
	val := serialize(map[string]any(ej), "examples", "encrypted_jsonb")
	return json.Marshal(val)
}

// encrypted int conversion
func (ei *EncryptedInt) FromDB(data []byte) error {
	var jsonData map[string]interface{}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		return err
	}

	if pValue, ok := jsonData["p"].(string); ok {
		parsedValue, err := strconv.Atoi(pValue) // Convert string to int
		if err != nil {
			return fmt.Errorf("invalid number format in 'p' field: %v", err)
		}
		*ei = EncryptedInt(parsedValue)
		return nil
	}

	return fmt.Errorf("invalid format: missing 'p' field")
}

func (ei EncryptedInt) ToDB() ([]byte, error) {
	val := serialize(int(ei), "examples", "encrypted_int")
	return json.Marshal(val)
}

// Encrypted bool converesion
func (eb *EncryptedBool) FromDB(data []byte) error {
	var jsonData map[string]interface{}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		return err
	}

	if pValue, ok := jsonData["p"].(string); ok {
		parsedValue, err := strconv.ParseBool(pValue)
		if err != nil {
			return fmt.Errorf("invalid boolean format in 'p' field: %v", err)
		}
		*eb = EncryptedBool(parsedValue)
		return nil
	}

	return fmt.Errorf("invalid format: missing 'p' field or unsupported type")
}

func (eb EncryptedBool) ToDB() ([]byte, error) {
	val := serialize(bool(eb), "examples", "encrypted_bool")

	return json.Marshal(val)
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
	case map[string]any:
		jsonData, err := json.Marshal(v)
		if err != nil {
			return "", fmt.Errorf("error marshaling JSON: %v", err)
		}
		return string(jsonData), nil
	case bool:
		return strconv.FormatBool(v), nil
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
	// MATCH
	MatchQueryLongString(proxyEngine)
	MatchQueryEmail(proxyEngine)

	// JSONB data query
	JsonbQuerySimple(proxyEngine)
	JsonbQueryDeepNested(proxyEngine)

	// ORE
	// String
	OreStringRangeQuery(proxyEngine)
	// Int
	OreIntRangeQuery(proxyEngine)
	// Bool
	OreBoolQuery(proxyEngine)
	// Date - todo

	// UNIQUE
	// String
	UniqueStringQuery(proxyEngine)
	// Int
	// Bool

}
