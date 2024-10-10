package main

import (
	"fmt"
	"log"

	"xorm.io/xorm"
)

// Query on where clause on unecrypted column
func WhereQuery(engine *xorm.Engine) {
	// Insert
	serializedEmail, serializeErr := serialize("test@test.com")
	if serializeErr != nil {
		log.Fatalf("Error serializing: %v", serializeErr)
	}
	newExample := Example{Text: "test@test.com", EncryptedText: serializedEmail}
	_, err := engine.Insert(&newExample)
	if err != nil {
		log.Fatalf("Could not insert new example: %v", err)
	}
	fmt.Printf("Example inserted: %+v\n", newExample)
	var example Example
	text := "test@test.com"

	has, err := engine.Where("text = ?", text).Get(&example)
	if err != nil {
		log.Fatalf("Could not retrieve example: %v", err)
	}
	if has {
		fmt.Println("Example retrieved:", example)
	} else {
		fmt.Println("Example not found")
	}
}

// Match query on encrypted column long string
func MatchQueryLongString(engine *xorm.Engine) {
	var example Example

	serializedString, serializeErr := serialize("this is a long string")
	if serializeErr != nil {
		log.Fatalf("Error serializing: %v", serializeErr)
	}
	newExample := Example{Text: "this is a long string", EncryptedText: serializedString}

	_, err := engine.Insert(&newExample)
	if err != nil {
		log.Fatalf("Could not insert new example: %v", err)
	}
	fmt.Printf("Example one inserted: %+v\n", newExample)

	serializedStringQuery, serializeErr := serialize("this")
	if serializeErr != nil {
		log.Fatalf("Error serializing: %v", serializeErr)
	}

	has, err := engine.Where("cs_match_v1(encrypted_text) @> cs_match_v1(?)", serializedStringQuery).Get(&example)
	if err != nil {
		log.Fatalf("Could not retrieve example: %v", err)
	}
	if has {
		fmt.Println("Example one retrieved:", example)
	} else {
		fmt.Println("Example not found")
	}
}

// Match equery on text
func MatchQueryEmail(engine *xorm.Engine) {
	var ExampleTwo Example

	serializedEmail, serializeErr := serialize("testing@testcom")
	if serializeErr != nil {
		log.Fatalf("Error serializing: %v", serializeErr)
	}
	newExampleTwo := Example{Text: "testing@test.com", EncryptedText: serializedEmail}

	_, errTwo := engine.Insert(&newExampleTwo)
	if errTwo != nil {
		log.Fatalf("Could not insert new example: %v", errTwo)
	}
	fmt.Printf("Example two inserted!: %+v\n", newExampleTwo)

	serializedEmailQuery, serializeErr := serialize("test")
	if serializeErr != nil {
		log.Fatalf("Error serializing: %v", serializeErr)
	}

	has, err := engine.Where("cs_match_v1(encrypted_text) @> cs_match_v1(?)", serializedEmailQuery).Get(&ExampleTwo)
	if err != nil {
		log.Fatalf("Could not retrieve exampleTwo: %v", err)
	}
	if has {
		fmt.Println("Example two retrieved:", ExampleTwo)
	} else {
		fmt.Println("Example two not found")
	}
}

func UniqueQuery(engine *xorm.Engine) {

}
