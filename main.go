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
	connStr := "user=postgres password=postgres port=5432 host=localhost dbname=gotest sslmode=disable"
	engine, err := xorm.NewEngine("postgres", connStr)
	if err != nil {
		log.Fatalf("Could not connect to the database: %v", err)
	}

	// need to map from struct to postgres snake case lowercase
	engine.SetMapper(names.SnakeMapper{})

	var exists bool
	_, err = engine.SQL("SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'gotest')").Get(&exists)
	if err != nil {
		log.Fatalf("Could not check if database exists: %v", err)
	}

	// create db
	if !exists {
		_, err = engine.Exec("CREATE DATABASE gotest")
		if err != nil {
			log.Fatalf("Could not create database: %v", err)
		}
		fmt.Println("Database 'gotest' created successfully!")
	} else {
		fmt.Println("Database 'gotest' already exists.")
	}

	err = engine.Sync2(new(User))

	if err != nil {
		log.Fatalf("Could not synchronize the database schema: %v", err)
	}

	// Insert
	newUser := User{Email: "test@test.com"}
	_, err = engine.Insert(&newUser)
	if err != nil {
		log.Fatalf("Could not insert new user: %v", err)
	}
	fmt.Println("New user inserted:", newUser)

	// Query
	var user User
	email := "test@test.com"

	has, err := engine.Where("email = ?", email).Get(&user)
	if err != nil {
		log.Fatalf("Could not retrieve user: %v", err)
	}
	if has {
		fmt.Println("User retrieved:", user)
	} else {
		fmt.Println("User not found")
	}
}
