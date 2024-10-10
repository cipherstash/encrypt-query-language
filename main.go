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

// To install types etc and run insert and query user:
// Run: go run main.go migrations.go


type TableColumn struct {
	T string `json:"t"`
	C string `json:"c"`
}

type EncryptedColumn struct {
	K string      `json:"k"`
	P string      `json:"p"`
	I TableColumn `json:"i"`
	V int         `json:"v"`
}

type User struct {
	Id             int64           `xorm:"pk autoincr"`
	Email          string          `xorm:"varchar(100)"`
	EncryptedEmail json.RawMessage `json:"encrypted_email" xorm:"jsonb 'encrypted_email'"`
}

func (User) TableName() string {
	return "users"
}

func serialize(value string) (json.RawMessage, error) {

	data := EncryptedColumn{"pt", value, TableColumn{"users", "encrypted_email"}, 1}

	jsonData, err := json.Marshal(data)
	if err != nil {
		return nil, fmt.Errorf("failed to serialize data: %v", err)
	}

	return json.RawMessage(jsonData), nil
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

	// Connect to proxy
	devConnStr := "user=postgres password=postgres port=6432 host=localhost dbname=gotest sslmode=disable"
	devEngine, err := xorm.NewEngine("pgx", devConnStr)

	if err != nil {
		log.Fatalf("Could not connect to the database: %v", err)
	}

	// need to map from struct to postgres snake case lowercase
	devEngine.SetMapper(names.SnakeMapper{})
	devEngine.ShowSQL(true)

	err = devEngine.Sync2(new(User))

	// Alter table users to add constraint for jsonb column
	sql := `
	ALTER TABLE users ADD CONSTRAINT encrypted_email_encrypted_check
	CHECK ( cs_check_encrypted_v1(encrypted_email) );
	`
	_, errConstraint := devEngine.Exec(sql)
	if errConstraint != nil {
		log.Fatalf("Error dsl core: %v", errConstraint)
	}

	log.Println("dsl core installed!")

	if err != nil {
		log.Fatalf("Could not create users table: %v", err)
	}

	devEngine.SetMapper(names.SnakeMapper{})
	devEngine.ShowSQL(true)
	devEngine.Exec("SELECT cs_refresh_encrypt_config();")

	// Insert
	serializedEmail, serializeErr := serialize("fionamccawley@test.com")
	if serializeErr != nil {
		log.Fatalf("Error serializing: %v", serializeErr)
	}
	newUser := User{Email: "fionamccawley@test.com", EncryptedEmail: serializedEmail}
	_, err = devEngine.Insert(&newUser)
	if err != nil {
		log.Fatalf("Could not insert new user: %v", err)
	}
	fmt.Printf("User inserted: %+v\n", newUser)
	// fmt.Println("Decrypted email:", newUser.EncryptedEmail["p"])

	// Query on unencrypted column: where clause
	WhereQuery(devEngine)

	// Query on encrypted column.

	// // MATCH
	MatchQuery(devEngine)
	// ORE
	// Unique
}
