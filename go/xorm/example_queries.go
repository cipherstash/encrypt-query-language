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

	// serializedEmail := serialize("test@test.com", "examples", "encrypted_text")

	// serializedJsonb := serialize(generateJsonbData("birds and spiders", "fountain", "tree"), "examples", "encrypted_jsonb")

	newExample := Example{NonEncryptedField: "sydney", EncryptedText: "test@test.com", EncryptedJsonb: generateJsonbData("birds and spiders", "fountain", "tree")}

	_, err := engine.Insert(&newExample)
	if err != nil {
		log.Fatalf("Could not insert new example: %v", err)
	}
	fmt.Println("Example inserted:", newExample)
	fmt.Println("")
	fmt.Println("")

	// Query
	var example Example
	text := "sydney"

	has, err := engine.Where("non_encrypted_field = ?", text).Get(&example)
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

	newExample := Example{NonEncryptedField: "sydney", EncryptedText: "this is a long string", EncryptedJsonb: generateJsonbData("bird", "fountain", "tree")}

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

	newExampleTwo := Example{NonEncryptedField: "sydney", EncryptedText: "testing@testcom", EncryptedJsonb: generateJsonbData("bird", "fountain", "tree")}

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

	var example Example

	// Insert 2 examples
	newExample := Example{NonEncryptedField: "sydney", EncryptedText: "this entry should be returned", EncryptedJsonb: generateJsonbData("first", "second", "third")}
	newExampleTwo := Example{NonEncryptedField: "melbourne", EncryptedText: "a completely different string!", EncryptedJsonb: generateJsonbData("blah", "boo", "bah")}

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
	var example Example

	// Insert 2 examples

	// Json with some nesting
	nestedJson := map[string]any{
		"key_one": map[string]any{
			"nested_one": []any{"hello"},
			"nested_two": map[string]any{
				"nested_three": "world",
			},
		},
	}

	newExample := Example{NonEncryptedField: "sydney", EncryptedText: "this entry should be returned for deep nested query", EncryptedJsonb: nestedJson}
	newExampleTwo := Example{NonEncryptedField: "melbourne", EncryptedText: "the quick brown fox etc", EncryptedJsonb: generateJsonbData("blah", "boo", "bah")}

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
