package main

import (
	"encoding/json"
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
	serializedJsonb, serializeJsonbErr := serialize(generateJsonbData("birds and spiders", "fountain", "tree"), "examples", "encrypted_jsonb")

	if serializeJsonbErr != nil {
		log.Fatalf("Error serializing: %v", serializeJsonbErr)
	}
	newExample := Example{Text: "test@test.com", EncryptedText: serializedEmail, EncryptedJsonb: serializedJsonb}

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
		fmt.Println("Example retrieved text:", example)
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
	serializedJsonb, serializeJsonbErr := serialize(generateJsonbData("bird", "fountain", "tree"), "examples", "encrypted_jsonb")

	if serializeJsonbErr != nil {
		log.Fatalf("Error serializing: %v", serializeJsonbErr)
	}

	newExample := Example{Text: "this is a long string", EncryptedText: serializedString, EncryptedJsonb: serializedJsonb}

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
		fmt.Println("Example match query long string:", example)
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
	serializedJsonb, serializeJsonbErr := serialize(generateJsonbData("bird", "fountain", "tree"), "examples", "encrypted_jsonb")

	if serializeJsonbErr != nil {
		log.Fatalf("Error serializing: %v", serializeJsonbErr)
	}
	newExampleTwo := Example{Text: "testing@test.com", EncryptedText: serializedEmail, EncryptedJsonb: serializedJsonb}

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
		fmt.Println("Example match query email retrieved:", ExampleTwo)
		fmt.Println("")
		fmt.Println("")
	} else {
		fmt.Println("Example two not found")
	}
}

func JsonbQuery(engine *xorm.Engine) {
	// Insert
	var example Example

	// Insert 2 examples
	serializedString, serializeTextErr := serialize("a string!", "examples", "encrypted_text")
	serializedJsonb, serializeJsonbErr := serialize(generateJsonbData("first", "second", "third"), "examples", "encrypted_jsonb")
	if serializeTextErr != nil {
		log.Fatalf("Error serializing: %v", serializeTextErr)
	}
	if serializeJsonbErr != nil {
		log.Fatalf("Error serializing: %v", serializeJsonbErr)
	}
	secondSerializedString, secondSerializeTextErr := serialize("a completely different string!", "examples", "encrypted_text")
	secondSerializedJsonb, secondSerializeJsonbErr := serialize(generateJsonbData("blah", "boo", "bah"), "examples", "encrypted_jsonb")

	if secondSerializeJsonbErr != nil {
		log.Fatalf("Error serializing: %v", serializeJsonbErr)
	}
	if secondSerializeTextErr != nil {
		log.Fatalf("Error serializing: %v", secondSerializedString)
	}

	newExample := Example{Text: "a string!", EncryptedText: serializedString, EncryptedJsonb: serializedJsonb}
	newExampleTwo := Example{Text: "a completely different string!", EncryptedText: secondSerializedString, EncryptedJsonb: secondSerializedJsonb}

	_, errTwo := engine.Insert(&newExample)
	if errTwo != nil {
		log.Fatalf("Could not insert jsonb example: %v", errTwo)
	}
	fmt.Printf("Example jsonb inserted!: %+v\n", newExample)

	_, errThree := engine.Insert(&newExampleTwo)
	if errThree != nil {
		log.Fatalf("Could not insert jsonb example two: %v", errThree)
	}
	fmt.Printf("Example two jsonb inserted!: %+v\n", newExample)

	// create a query
	query := map[string]any{
		"top": map[string]any{
			"nested": []any{"first"},
		},
	}

	jsonQueryData, err := json.Marshal(query)

	if err != nil {
		log.Fatalf("Error serializing JSON: %v", err)
	}
	serializedJsonbQuery, serializeJsonbQueryErr := serialize(jsonQueryData, "examples", "encrypted_text")

	if serializeJsonbQueryErr != nil {
		log.Fatalf("Error serializing: %v", serializeJsonbQueryErr)
	}

	has, err := engine.Where("cs_ste_vec_v1(encrypted_jsonb) @> cs_ste_vec_v1(?)", serializedJsonbQuery).Get(&example)
	if err != nil {
		log.Fatalf("Could not retrieve jsonb example: %v", err)
	}
	if has {
		fmt.Println("Example jsonb query retrieved:", example)
		fmt.Println("")
		fmt.Println("")
	} else {
		fmt.Println("Example two not found")
	}

}

func generateJsonbData(value_one string, value_two string, value_three string) json.RawMessage {
	data := map[string]any{
		"top": map[string]any{
			"nested": []any{value_one, value_two},
		},
		"bottom": value_three,
	}

	jsonData, err := json.Marshal(data)

	if err != nil {
		log.Fatalf("Error serializing JSON: %v", err)
	}

	return json.RawMessage(jsonData)
}
