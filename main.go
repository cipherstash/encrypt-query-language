package main

import (
	"database/sql"
	_ "database/sql"
	"fmt"
	"log"

	_ "github.com/jackc/pgx/stdlib" // PostgreSQL driver
	"xorm.io/xorm"
	"xorm.io/xorm/names"
)

var engine *xorm.Engine

type User struct {
	Id    int64  `xorm:"pk autoincr"` // Primary key with auto-increment
	Email string `xorm:"varchar(100)"`
}

func (User) TableName() string {
	return "users"
}

func main() {
	// connStr := "postgres://postgres:postgres@localhost:5432/postgres"
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
		_, err = engine.Exec("DROP DATABASE gotest;")
		if err != nil {
			log.Fatalf("Could not drop database: %v", err)
		}
		fmt.Println("Database 'gotest' dropped successfully!")

		_, err = engine.Exec("CREATE DATABASE gotest;")
		if err != nil {
			log.Fatalf("Could not create database: %v", err)
		}
		fmt.Println("Database 'gotest' created successfully!")
	} else {
		fmt.Println("Database 'gotest' doesn't exist. Creating...")
		_, err = engine.Exec("CREATE DATABASE gotest;")
		if err != nil {
			log.Fatalf("Could not create database: %v", err)
		}
		fmt.Println("Database 'gotest' created successfully!")
	}

	devConnStr := "user=postgres password=postgres port=5432 host=localhost dbname=gotest sslmode=disable"
	devEngine, err := xorm.NewEngine("pgx", devConnStr)

	if err != nil {
		log.Fatalf("Could not connect to the database: %v", err)
	}
	defer devEngine.Close()

	// need to map from struct to postgres snake case lowercase
	devEngine.SetMapper(names.SnakeMapper{})
	devEngine.ShowSQL(true)

	err = devEngine.Sync2(new(User))

	if err != nil {
		log.Fatalf("Could not create users table: %v", err)
	}

	typesConn := "user=postgres password=postgres port=5432 host=localhost dbname=gotest sslmode=disable"
	types_engine, err := sql.Open("pgx", typesConn)
	if err != nil {
		log.Fatalf("Could not connect to the database: %v", err)
	}

	InstallEql(types_engine)

	// Insert
	newUser := User{Email: "test@test.com"}
	_, err = devEngine.Insert(&newUser)
	if err != nil {
		log.Fatalf("Could not insert new user: %v", err)
	}
	fmt.Println("New user inserted:", newUser)

	// Query
	var user User
	email := "test@test.com"

	has, err := devEngine.Where("email = ?", email).Get(&user)
	if err != nil {
		log.Fatalf("Could not retrieve user: %v", err)
	}
	if has {
		fmt.Println("User retrieved:", user)
	} else {
		fmt.Println("User not found")
	}
}
