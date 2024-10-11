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
	fmt.Println("")
	fmt.Println("")
	fmt.Println("Query with where clause on unencrypted field")
	fmt.Println("")
	fmt.Println("")

	serializedEmail := serialize("test@test.com", "examples", "encrypted_text")

	serializedJsonb := serialize(generateJsonbData("birds and spiders", "fountain", "tree"), "examples", "encrypted_jsonb")

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
		fmt.Println("")
		fmt.Println("")

	} else {
		fmt.Println("Example not found")
	}
}

// Match query on encrypted column long string
func MatchQueryLongString(engine *xorm.Engine) {
	fmt.Println("Match query on sentence")
	fmt.Println("")
	var example Example

	serializedString := serialize("this is a long string", "examples", "encrypted_text")

	serializedJsonb := serialize(generateJsonbData("bird", "fountain", "tree"), "examples", "encrypted_jsonb")

	newExample := Example{Text: "this is a long string", EncryptedText: serializedString, EncryptedJsonb: serializedJsonb}

	_, err := engine.Insert(&newExample)
	if err != nil {
		log.Fatalf("Could not insert new example: %v", err)
	}
	fmt.Printf("Example one inserted: %+v\n", newExample)

	serializedStringQuery := serialize("this", "examples", "encrypted_text")
	query, err := json.Marshal(serializedStringQuery)

	if err != nil {
		log.Fatalf("Error marshaling encrypted_text: %v", err)
	}

	has, err := engine.Where("cs_match_v1(encrypted_text) @> cs_match_v1(?)", query).Get(&example)
	if err != nil {
		log.Fatalf("Could not retrieve example: %v", err)
	}
	if has {
		fmt.Println("Example match query retrieved:", example)
		fmt.Println("")
		fmt.Println("")
	} else {
		fmt.Println("Example not found")
	}
}

// Match equery on text
func MatchQueryEmail(engine *xorm.Engine) {
	fmt.Println("Match query on email")
	fmt.Println("")
	var ExampleTwo Example

	serializedEmail := serialize("testing@testcom", "examples", "encrypted_text")

	serializedJsonb := serialize(generateJsonbData("bird", "fountain", "tree"), "examples", "encrypted_jsonb")

	newExampleTwo := Example{Text: "testing@test.com", EncryptedText: serializedEmail, EncryptedJsonb: serializedJsonb}

	_, errTwo := engine.Insert(&newExampleTwo)
	if errTwo != nil {
		log.Fatalf("Could not insert new example: %v", errTwo)
	}
	fmt.Printf("Example two inserted!: %+v\n", newExampleTwo)

	serializedEmailQuery := serialize("test", "examples", "encrypted_text")
	query, err := json.Marshal(serializedEmailQuery)

	if err != nil {
		log.Fatalf("Error marshaling encrypted_text: %v", err)
	}

	has, err := engine.Where("cs_match_v1(encrypted_text) @> cs_match_v1(?)", query).Get(&ExampleTwo)
	if err != nil {
		log.Fatalf("Could not retrieve exampleTwo: %v", err)
	}
	if has {
		fmt.Println("Example match query retrieved:", ExampleTwo)
		fmt.Println("")
		fmt.Println("")
	} else {
		fmt.Println("Example two not found")
	}
}

func JsonbQuerySimple(engine *xorm.Engine) {
	fmt.Println("Query on jsonb field")
	fmt.Println("")
	// Insert
	var example Example

	// Insert 2 examples
	serializedString := serialize("a string!", "examples", "encrypted_text")
	serializedJsonb := serialize(generateJsonbData("first", "second", "third"), "examples", "encrypted_jsonb")

	secondSerializedString := serialize("a completely different string!", "examples", "encrypted_text")
	secondSerializedJsonb := serialize(generateJsonbData("blah", "boo", "bah"), "examples", "encrypted_jsonb")

	newExample := Example{Text: "this entry should be returned", EncryptedText: serializedString, EncryptedJsonb: serializedJsonb}
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
	serializedJsonbQuery := serialize(query, "examples", "encrypted_jsonb")

	jsonQueryData, err := json.Marshal(serializedJsonbQuery)
	if err != nil {
		log.Fatalf("Could not insert jsonb example two: %v", err)
	}

	has, err := engine.Where("cs_ste_vec_v1(encrypted_jsonb) @> cs_ste_vec_v1(?)", jsonQueryData).Get(&example)
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

func JsonbQueryDeepNested(engine *xorm.Engine) {
	fmt.Println("Query on deep nested jsonb field")
	fmt.Println("")
	// Insert
	var example Example

	// Insert 2 examples
	serializedString := serialize("this entry should be returned for deep nested query", "examples", "encrypted_text")
	secondSerializedString := serialize("the quick brown fox etc", "examples", "encrypted_text")

	// Json with some nesting
	nestedJson := map[string]any{
		"key_one": map[string]any{
			"nested_one": []any{"hello"},
			"nested_two": map[string]any{
				"nested_three": "world",
			},
		},
	}
	serializedJsonb := serialize(nestedJson, "examples", "encrypted_jsonb")

	secondSerializedJsonb := serialize(generateJsonbData("blah", "boo", "bah"), "examples", "encrypted_jsonb")

	newExample := Example{Text: "this entry should be returned for deep nested query", EncryptedText: serializedString, EncryptedJsonb: serializedJsonb}
	newExampleTwo := Example{Text: "the quick brown fox etc", EncryptedText: secondSerializedString, EncryptedJsonb: secondSerializedJsonb}

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

	query := map[string]any{
		"key_one": map[string]any{
			"nested_two": map[string]any{
				"nested_three": "world",
			},
		},
	}

	serializedJsonbQuery := serialize(query, "examples", "encrypted_jsonb")

	jsonQueryData, err := json.Marshal(serializedJsonbQuery)
	if err != nil {
		log.Fatalf("Could not insert jsonb example two: %v", err)
	}

	has, err := engine.Where("cs_ste_vec_v1(encrypted_jsonb) @> cs_ste_vec_v1(?)", jsonQueryData).Get(&example)
	if err != nil {
		log.Fatalf("Could not retrieve jsonb example: %v", err)
	}
	if has {
		fmt.Println("Example jsonb query retrieved:", example)
		fmt.Println("")
		fmt.Println("")
	} else {
		fmt.Println("Example not found")
	}

}

// For testing
func generateJsonbData(value_one string, value_two string, value_three string) map[string]any {
	data := map[string]any{
		"top": map[string]any{
			"nested": []any{value_one, value_two},
		},
		"bottom": value_three,
	}

	return data
}
