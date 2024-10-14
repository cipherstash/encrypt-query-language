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

	newExample := Example{NonEncryptedField: "sydney", EncryptedInt: 23, EncryptedText: "test@test.com", EncryptedJsonb: generateJsonbData("birds and spiders", "fountain", "tree")}

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

	newExampleTwo := Example{NonEncryptedField: "sydney", EncryptedText: "somename@gmail.com", EncryptedJsonb: generateJsonbData("bird", "fountain", "tree")}

	_, errTwo := engine.Insert(&newExampleTwo)
	if errTwo != nil {
		log.Fatalf("Could not insert new example: %v", errTwo)
	}
	fmt.Printf("Example two inserted!: %+v\n", newExampleTwo)

	serializedEmailQuery := serialize("some", "examples", "encrypted_text")
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

func OreStringRangeQuery(engine *xorm.Engine) {
	fmt.Println("Ore String query")
	fmt.Println("")

	example1 := Example{NonEncryptedField: "expected result", EncryptedText: "whale", EncryptedJsonb: generateJsonbData("test_one", "test_two", "test_three")}
	example2 := Example{NonEncryptedField: "", EncryptedText: "apple", EncryptedJsonb: generateJsonbData("blah", "boo", "bah")}

	_, errExample1 := engine.Insert(&example1)
	if errExample1 != nil {
		log.Fatalf("Could not insert example: %v", errExample1)
	}
	_, errExample2 := engine.Insert(&example2)
	if errExample2 != nil {
		log.Fatalf("Could not insert example: %v", errExample2)
	}
	fmt.Println("Examples inserted!")

	// Query
	serializedOreStringQuery := serialize("tree", "examples", "encrypted_text")
	jsonQueryData, _ := json.Marshal(serializedOreStringQuery)

	var example Example

	has, queryErr := engine.Where("cs_ore_64_8_v1(encrypted_text) > cs_ore_64_8_v1(?)", jsonQueryData).Get(&example)
	if queryErr != nil {
		log.Fatalf("Could not retrieve ore example: %v", queryErr)
	}
	if has {
		fmt.Println("Example ore range query retrieved:", example)
		fmt.Println("")
		fmt.Println("")
	} else {
		fmt.Println("Example not found")
	}
}

func OreIntRangeQuery(engine *xorm.Engine) {
	fmt.Println("Ore Int query")
	fmt.Println("")

	example1 := Example{NonEncryptedField: "expected ore in range query", EncryptedInt: 42, EncryptedText: "some string", EncryptedJsonb: generateJsonbData("test_one", "test_two", "test_three")}
	example2 := Example{NonEncryptedField: "", EncryptedInt: 23, EncryptedText: "another string", EncryptedJsonb: generateJsonbData("blah", "boo", "bah")}

	_, errExample1 := engine.Insert(&example1)
	if errExample1 != nil {
		log.Fatalf("Could not insert example: %v", errExample1)
	}
	_, errExample2 := engine.Insert(&example2)
	if errExample2 != nil {
		log.Fatalf("Could not insert example: %v", errExample2)
	}
	fmt.Println("Examples inserted!", example1)
	fmt.Println("Examples inserted!", example2)

	serializedOreIntQuery := serialize(32, "examples", "encrypted_int")
	query, _ := json.Marshal(serializedOreIntQuery)

	// Query

	// var example Example
	var allExamples []Example
	queryErr := engine.Where("cs_ore_64_8_v1(encrypted_int) > cs_ore_64_8_v1(?)", query).Find(&allExamples)
	// has, queryErr := engine.Where("cs_ore_64_8_v1(encrypted_int) > cs_ore_64_8_v1(?)", query).Find(&allExamples)
	if queryErr != nil {
		log.Fatalf("Could not retrieve ore example: %v", queryErr)
	}

	fmt.Println("Example ore range query retrieved:", allExamples)
	fmt.Println("")
	fmt.Println("")
}

func OreBoolQuery(engine *xorm.Engine) {
	fmt.Println("Ore bool query")
	fmt.Println("")

	example1 := Example{EncryptedBool: false, NonEncryptedField: "", EncryptedInt: 23, EncryptedText: "test_one", EncryptedJsonb: generateJsonbData("blah", "boo", "bah")}
	example2 := Example{EncryptedBool: true, NonEncryptedField: "expected result ore bool query", EncryptedInt: 23, EncryptedText: "test_two", EncryptedJsonb: generateJsonbData("blah", "boo", "bah")}
	example3 := Example{EncryptedBool: false, NonEncryptedField: "", EncryptedInt: 23, EncryptedText: "test_three", EncryptedJsonb: generateJsonbData("blah", "boo", "bah")}

	_, errExample1 := engine.Insert(&example1)
	if errExample1 != nil {
		log.Fatalf("Could not insert example: %v", errExample1)
	}
	_, errExample2 := engine.Insert(&example2)
	if errExample2 != nil {
		log.Fatalf("Could not insert example: %v", errExample2)
	}
	_, errExample3 := engine.Insert(&example3)
	if errExample3 != nil {
		log.Fatalf("Could not insert example: %v", errExample3)
	}
	fmt.Println("Example1 inserted!", example1)
	fmt.Println("Example2 inserted!", example2)
	fmt.Println("Example3 inserted!", example3)

	serializedOreBoolQuery := serialize(false, "examples", "encrypted_bool")
	query, _ := json.Marshal(serializedOreBoolQuery)

	// Query

	// var example Example
	var allExamples []Example
	queryErr := engine.Where("cs_ore_64_8_v1(encrypted_bool) > cs_ore_64_8_v1(?)", query).Find(&allExamples)
	if queryErr != nil {
		log.Fatalf("Could not retrieve ore example: %v", queryErr)
	}

	fmt.Println("Example ore range query retrieved:", allExamples)
	fmt.Println("")
	fmt.Println("")
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
