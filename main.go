package main

import (
	"fmt"
	"log"

	_ "github.com/lib/pq" // PostgreSQL driver
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
	connStr := "user=postgres password=postgres port=5432 host=localhost dbname=postgres sslmode=disable"
	engine, err := xorm.NewEngine("postgres", connStr)

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
	dev_engine, err := xorm.NewEngine("postgres", devConnStr)

	if err != nil {
		log.Fatalf("Could not connect to the database: %v", err)
	}

	// need to map from struct to postgres snake case lowercase
	dev_engine.SetMapper(names.SnakeMapper{})

	err = dev_engine.Sync2(new(User))

	if err != nil {
		log.Fatalf("Could not create users table: %v", err)
	}

	InstallEql(dev_engine)

	// Insert
	newUser := User{Email: "test@test.com"}
	_, err = dev_engine.Insert(&newUser)
	if err != nil {
		log.Fatalf("Could not insert new user: %v", err)
	}
	fmt.Println("New user inserted:", newUser)

	// Query
	var user User
	email := "test@test.com"

	has, err := dev_engine.Where("email = ?", email).Get(&user)
	if err != nil {
		log.Fatalf("Could not retrieve user: %v", err)
	}
	if has {
		fmt.Println("User retrieved:", user)
	} else {
		fmt.Println("User not found")
	}
}
