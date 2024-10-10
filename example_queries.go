package main

import (
	"fmt"
	"log"

	"xorm.io/xorm"
)

// Query on where clause on unecrypted column
func WhereQuery(engine *xorm.Engine) {
	// Insert
	fmt.Println("Query with where clause on unencrypted field")

	serializedEmail, serializeErr := serialize("test@test.com", "examples", "encrypted_text")
	if serializeErr != nil {
		log.Fatalf("Error serializing: %v", serializeErr)
	}
	newExample := Example{Text: "test@test.com", EncryptedText: serializedEmail}

	_, err := engine.Insert(&newExample)
	if err != nil {
		log.Fatalf("Could not insert new example: %v", err)
	}
	fmt.Println("Example inserted:", newExample)
	fmt.Println("")
	fmt.Println("")

	// Query
	var example Example
	text := "test@test.com"

	has, err := engine.Where("text = ?", text).Get(&example)
	if err != nil {
		log.Fatalf("Could not retrieve example: %v", err)
	}
	if has {
		fmt.Println("Example retrieved:", example)
		fmt.Println("Example retrieved text:", example.DecryptedText)
		fmt.Println("")
		fmt.Println("")

	} else {
		fmt.Println("Example not found")
	}
}

// Match query on encrypted column long string
func MatchQueryLongString(engine *xorm.Engine) {
	var example Example

	serializedString, serializeErr := serialize("this is a long string", "examples", "encrypted_text")
	if serializeErr != nil {
		log.Fatalf("Error serializing: %v", serializeErr)
	}
	newExample := Example{Text: "this is a long string", EncryptedText: serializedString}

	_, err := engine.Insert(&newExample)
	if err != nil {
		log.Fatalf("Could not insert new example: %v", err)
	}
	fmt.Printf("Example one inserted: %+v\n", newExample)

	serializedStringQuery, serializeErr := serialize("this", "examples", "encrypted_text")
	if serializeErr != nil {
		log.Fatalf("Error serializing: %v", serializeErr)
	}

	has, err := engine.Where("cs_match_v1(encrypted_text) @> cs_match_v1(?)", serializedStringQuery).Get(&example)
	if err != nil {
		log.Fatalf("Could not retrieve example: %v", err)
	}
	if has {
		fmt.Println("Example match query retrieved:", example)
		fmt.Println("Example match query long string:", example.DecryptedText)
		fmt.Println("")
		fmt.Println("")
	} else {
		fmt.Println("Example not found")
	}
}

// Match equery on text
func MatchQueryEmail(engine *xorm.Engine) {
	var ExampleTwo Example

	serializedEmail, serializeErr := serialize("testing@testcom", "examples", "encrypted_text")
	if serializeErr != nil {
		log.Fatalf("Error serializing: %v", serializeErr)
	}
	newExampleTwo := Example{Text: "testing@test.com", EncryptedText: serializedEmail}

	_, errTwo := engine.Insert(&newExampleTwo)
	if errTwo != nil {
		log.Fatalf("Could not insert new example: %v", errTwo)
	}
	fmt.Printf("Example two inserted!: %+v\n", newExampleTwo)

	serializedEmailQuery, serializeErr := serialize("test", "examples", "encrypted_text")
	if serializeErr != nil {
		log.Fatalf("Error serializing: %v", serializeErr)
	}

	has, err := engine.Where("cs_match_v1(encrypted_text) @> cs_match_v1(?)", serializedEmailQuery).Get(&ExampleTwo)
	if err != nil {
		log.Fatalf("Could not retrieve exampleTwo: %v", err)
	}
	if has {
		fmt.Println("Example match query retrieved:", ExampleTwo)
		fmt.Println("Example match query email retrieved:", ExampleTwo.DecryptedText)
		fmt.Println("")
		fmt.Println("")
	} else {
		fmt.Println("Example two not found")
	}
}

func JsonbData(engine *xorm.Engine) {
	// Insert

}
