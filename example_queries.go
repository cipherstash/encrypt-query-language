package main

import (
	"fmt"
	"log"

	"xorm.io/xorm"
)

// Query on where clause on unecrypted column
func WhereQuery(engine *xorm.Engine) {
	var user User
	email := "test@test.com"

	has, err := engine.Where("email = ?", email).Get(&user)
	if err != nil {
		log.Fatalf("Could not retrieve user: %v", err)
	}
	if has {
		// fmt.Printf("User retrieved: %+v\n", user)
		fmt.Println("User retrieved:", user)
	} else {
		fmt.Println("User not found")
	}
}

// Match query on encrypted column
func MatchQuery(engine *xorm.Engine) {
	var user User
	serializedEmail, serializeErr := serialize("test")
	if serializeErr != nil {
		log.Fatalf("Error serializing: %v", serializeErr)
	}

	// _, err := engine.Exec(`
	// SELECT * FROM users WHERE (cs_match_v1(encrypted_email) @> cs_match_v1('{"i":{"c":"encrypted_email","t":"users"},"k":"pt","p":"test@test.com","v":1}'::jsonb));
	// `)

	// if err != nil {
	// 	log.Fatalf("Error retrieving user: %v", err)
	// }

	has, err := engine.Where("cs_match_v1(encrypted_email) @> cs_match_v1(?)", serializedEmail).Get(&user)
	if err != nil {
		log.Fatalf("Could not retrieve user: %v", err)
	}
	if has {
		fmt.Println("User retrieved:", user)
	} else {
		fmt.Println("User not found")
	}
}

func UniqueQuery(engine *xorm.Engine) {

}
