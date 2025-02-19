package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"

	"github.com/cipherstash/goeql"
	_ "github.com/jackc/pgx/v5/stdlib" // PostgreSQL driver
	"xorm.io/xorm"
	"xorm.io/xorm/names"
)

// Create a separate custom type for each field that is being encrypted, using the relevant go type.
// This custom type can then be used to access the conversion interface to use toDB and fromDb.
type EncryptedTextField string
type EncryptedJsonbField map[string]interface{}
type EncryptedIntField int
type EncryptedBoolField bool

// 2. Add to struct
type Example struct {
	Id                  int64               `xorm:"pk autoincr"`
	NonEncryptedField   string              `xorm:"varchar(100)"`
	EncryptedTextField  EncryptedTextField  `json:"encrypted_text_field" xorm:"jsonb 'encrypted_text_field'"`
	EncryptedJsonbField EncryptedJsonbField `json:"encrypted_jsonb_field" xorm:"jsonb 'encrypted_jsonb_field'"`
	EncryptedIntField   EncryptedIntField   `json:"encrypted_int_field" xorm:"jsonb 'encrypted_int_field'"`
	EncryptedBoolField  EncryptedBoolField  `json:"encrypted_bool_field" xorm:"jsonb 'encrypted_bool_field'"`
}

func (Example) TableName() string {
	return "goexamples"
}

// Use the conversion interface for a custom type.
// Use goeql serialization/deserialization to convert data to json expected by CipherStash proxy, and convert
// back to the original field type.
//
// When serializing, the table and column for that field needs to be passed.
// So the json configuration has the correct table and column when passed to the proxy.
//
// This setup means that for each field that needs to be encrypted:
// - a separate custom type needs to be created
// eg `type EncryptedTextFieldOne string`
//    `type EncryptedTextFieldTwo string`
//
// - ToDB and FromDB needs to be implemented for each custom type.

// encrypted text field conversion
func (et EncryptedTextField) ToDB() ([]byte, error) {
	etCs := goeql.EncryptedText(et)
	return (&etCs).Serialize("goexamples", "encrypted_text_field")
}

func (et *EncryptedTextField) FromDB(data []byte) error {
	etCs := goeql.EncryptedText(*et)

	val, err := (&etCs).Deserialize(data)
	if err != nil {
		return err
	}

	*et = EncryptedTextField(val)

	return nil
}

// Encrypted jsonb field conversion
func (ej EncryptedJsonbField) ToDB() ([]byte, error) {
	ejCs := goeql.EncryptedJsonb(ej)
	return (&ejCs).Serialize("goexamples", "encrypted_jsonb_field")
}

func (ej *EncryptedJsonbField) FromDB(data []byte) error {
	etCs := goeql.EncryptedJsonb(*ej)

	val, err := (&etCs).Deserialize(data)
	if err != nil {
		return err
	}

	*ej = EncryptedJsonbField(val)

	return nil
}

// encrypted int field conversion
func (ei EncryptedIntField) ToDB() ([]byte, error) {
	eiCs := goeql.EncryptedInt(ei)
	return (&eiCs).Serialize("goexamples", "encrypted_int_field")
}

func (ei *EncryptedIntField) FromDB(data []byte) error {
	eiCs := goeql.EncryptedInt(*ei)

	val, err := (&eiCs).Deserialize(data)
	if err != nil {
		return err
	}

	*ei = EncryptedIntField(val)

	return nil
}

// Encrypted bool converesion
func (eb EncryptedBoolField) ToDB() ([]byte, error) {
	ebCs := goeql.EncryptedBool(eb)
	return (&ebCs).Serialize("goexamples", "encrypted_bool_field")
}

func (eb *EncryptedBoolField) FromDB(data []byte) error {
	ebCs := goeql.EncryptedBool(*eb)

	val, err := (&ebCs).Deserialize(data)
	if err != nil {
		return err
	}

	*eb = EncryptedBoolField(val)

	return nil
}

func createTable() {
	connStr := "user=postgres password=postgres port=5432 host=localhost dbname=postgres sslmode=disable"
	engine, err := xorm.NewEngine("pgx", connStr)

	if err != nil {
		log.Fatalf("Could not connect to postgres database: %v", err)
	}

	// need to map from struct to postgres snake case lowercase
	engine.SetMapper(names.SnakeMapper{})
	engine.ShowSQL(true)

	err = engine.Sync(new(Example))
	if err != nil {
		log.Fatalf("Could not create goexamples table: %v", err)
	}

	fmt.Println("Examples table synced successfully!")
	engine.Close()
}

func addIndexesConstraints() {
	connStr := "user=postgres password=postgres port=5432 host=localhost dbname=postgres sslmode=disable"
	// Install Eql, custom types, indexes and constraints
	// To install our custom types we need to use the database/sql package due to an issue
	// with how xorm interprets `?`.
	// https://gitea.com/xorm/xorm/issues/2483
	engine, err := sql.Open("pgx", connStr)
	if err != nil {
		log.Fatalf("Could not connect to the database: %v", err)
	}

	AddIndexes(engine)
	AddConstraint(engine)

	// Refresh config with
	engine.Exec("SELECT cs_refresh_encrypt_config();")
	engine.Close()

}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Please provide a function name to run.")
		return
	}

	fn := os.Args[1]

	switch fn {
	case "setupDev":
		setupDev()
	default:
		fmt.Println("Unknown function:", fn)
	}
}

func setupDev() {
	// Connect to go test directly and create table
	createTable()

	// Add config
	addIndexesConstraints()
}
