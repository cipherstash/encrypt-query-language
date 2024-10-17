package main

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/encrypt-query-language/languages/go/goeql"
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

	newExample := Example{NonEncryptedField: "sydney", EncryptedIntField: 23, EncryptedTextField: "test@test.com", EncryptedJsonbField: generateJsonbData("birds and spiders", "fountain", "tree")}

	_, err := engine.Insert(&newExample)
	if err != nil {
		log.Fatalf("Could not insert new example: %v", err)
	}
	fmt.Println("Example inserted:", newExample)
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

// // Match query on encrypted column long string
func MatchQueryLongString(engine *xorm.Engine) {
	fmt.Println("Match query on sentence")
	fmt.Println("")
	var example Example

	newExample := Example{NonEncryptedField: "sydney", EncryptedTextField: "this is a long string", EncryptedJsonbField: generateJsonbData("bird", "fountain", "tree")}

	_, err := engine.Insert(&newExample)
	if err != nil {
		log.Fatalf("Could not insert new example: %v", err)
	}
	fmt.Printf("Example one inserted: %+v\n", newExample)
	fmt.Println("")

	query, err := goeql.SerializeQuery("this", "examples", "encrypted_text_field")
	if err != nil {
		log.Fatalf("Error marshaling encrypted_text_field: %v", err)
	}

	has, err := engine.Where("cs_match_v1(encrypted_text_field) @> cs_match_v1(?)", query).Get(&example)
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

// // Match equery on text
func MatchQueryEmail(engine *xorm.Engine) {
	fmt.Println("Match query on email")
	fmt.Println("")
	var ExampleTwo Example

	newExampleTwo := Example{NonEncryptedField: "sydney", EncryptedTextField: "somename@gmail.com", EncryptedJsonbField: generateJsonbData("bird", "fountain", "tree")}

	_, err := engine.Insert(&newExampleTwo)
	if err != nil {
		log.Fatalf("Could not insert new example: %v", err)
	}
	fmt.Printf("Example two inserted!: %+v\n", newExampleTwo)
	fmt.Println("")

	query, errTwo := goeql.SerializeQuery("some", "examples", "encrypted_text_field")
	if errTwo != nil {
		log.Fatalf("Error marshaling encrypted_text_field: %v", errTwo)
	}

	has, errThree := engine.Where("cs_match_v1(encrypted_text_field) @> cs_match_v1(?)", query).Get(&ExampleTwo)
	if errThree != nil {
		log.Fatalf("Could not retrieve exampleTwo: %v", errThree)
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
	newExample := Example{NonEncryptedField: "sydney", EncryptedTextField: "this entry should be returned", EncryptedJsonbField: generateJsonbData("first", "second", "third")}
	newExampleTwo := Example{NonEncryptedField: "melbourne", EncryptedTextField: "a completely different string!", EncryptedJsonbField: generateJsonbData("foo", "boo", "bah")}

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
	fmt.Println("")

	// create a query
	jsonbQuery := map[string]any{
		"top": map[string]any{
			"nested": []any{"first"},
		},
	}

	query, errTwo := goeql.SerializeQuery(jsonbQuery, "examples", "encrypted_jsonb_field")
	if errTwo != nil {
		log.Fatalf("Error marshaling encrypted_jsonb_field: %v", errTwo)
	}

	has, err := engine.Where("cs_ste_vec_v1(encrypted_jsonb_field) @> cs_ste_vec_v1(?)", query).Get(&example)
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

	newExample := Example{NonEncryptedField: "sydney", EncryptedTextField: "this entry should be returned for deep nested query", EncryptedJsonbField: nestedJson}
	newExampleTwo := Example{NonEncryptedField: "melbourne", EncryptedTextField: "the quick brown fox etc", EncryptedJsonbField: generateJsonbData("foo", "boo", "bah")}

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
	fmt.Println("")

	query := map[string]any{
		"key_one": map[string]any{
			"nested_two": map[string]any{
				"nested_three": "world",
			},
		},
	}

	jsonbQuery, errQuery := goeql.SerializeQuery(query, "examples", "encrypted_jsonb_field")
	if errQuery != nil {
		log.Fatalf("err: %v", errQuery)
	}

	has, err := engine.Where("cs_ste_vec_v1(encrypted_jsonb_field) @> cs_ste_vec_v1(?)", jsonbQuery).Get(&example)
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

	example1 := Example{NonEncryptedField: "expected result", EncryptedTextField: "whale", EncryptedJsonbField: generateJsonbData("test_one", "test_two", "test_three")}
	example2 := Example{NonEncryptedField: "", EncryptedTextField: "apple", EncryptedJsonbField: generateJsonbData("foo", "boo", "bah")}

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
	query, errQuery := goeql.SerializeQuery("tree", "examples", "encrypted_text_field")
	if errQuery != nil {
		log.Fatalf("err: %v", errQuery)
	}

	var example Example

	has, queryErr := engine.Where("cs_ore_64_8_v1(encrypted_text_field) > cs_ore_64_8_v1(?)", query).Get(&example)
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

	example1 := Example{NonEncryptedField: "expected ore in range query", EncryptedIntField: 42, EncryptedTextField: "some string", EncryptedJsonbField: generateJsonbData("test_one", "test_two", "test_three")}
	example2 := Example{NonEncryptedField: "", EncryptedIntField: 23, EncryptedTextField: "another string", EncryptedJsonbField: generateJsonbData("foo", "boo", "bah")}

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

	serializedOreIntQuery, errQuery := goeql.SerializeQuery(32, "examples", "encrypted_int_field")
	if errQuery != nil {
		log.Fatalf("err: %v", errQuery)
	}
	query, _ := json.Marshal(serializedOreIntQuery)

	// Query

	// var example Example
	var allExamples []Example
	queryErr := engine.Where("cs_ore_64_8_v1(encrypted_int_field) > cs_ore_64_8_v1(?)", query).Find(&allExamples)
	// has, queryErr := engine.Where("cs_ore_64_8_v1(encrypted_int_field) > cs_ore_64_8_v1(?)", query).Find(&allExamples)
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

	example1 := Example{EncryptedBoolField: false, NonEncryptedField: "", EncryptedIntField: 23, EncryptedTextField: "test_one", EncryptedJsonbField: generateJsonbData("foo", "boo", "bah")}
	example2 := Example{EncryptedBoolField: true, NonEncryptedField: "expected result ore bool query", EncryptedIntField: 23, EncryptedTextField: "test_two", EncryptedJsonbField: generateJsonbData("foo", "boo", "bah")}
	example3 := Example{EncryptedBoolField: false, NonEncryptedField: "", EncryptedIntField: 23, EncryptedTextField: "test_three", EncryptedJsonbField: generateJsonbData("foo", "boo", "bah")}

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

	// Query
	query, errQuery := goeql.SerializeQuery(false, "examples", "encrypted_bool_field")
	if errQuery != nil {
		log.Fatalf("err: %v", errQuery)
	}

	// var example Example
	var allExamples []Example
	queryErr := engine.Where("cs_ore_64_8_v1(encrypted_bool_field) > cs_ore_64_8_v1(?)", query).Find(&allExamples)
	if queryErr != nil {
		log.Fatalf("Could not retrieve ore example: %v", queryErr)
	}

	fmt.Println("Example ore range query retrieved:", allExamples)
	fmt.Println("")
	fmt.Println("")
}

func UniqueStringQuery(engine *xorm.Engine) {
	fmt.Println("Unique string query")
	fmt.Println("")

	example1 := Example{EncryptedBoolField: false, NonEncryptedField: "", EncryptedIntField: 23, EncryptedTextField: "test one", EncryptedJsonbField: generateJsonbData("foo", "boo", "bah")}
	example2 := Example{EncryptedBoolField: true, NonEncryptedField: "expected result unique string query", EncryptedIntField: 23, EncryptedTextField: "test two", EncryptedJsonbField: generateJsonbData("foo", "boo", "bah")}
	example3 := Example{EncryptedBoolField: false, NonEncryptedField: "", EncryptedIntField: 23, EncryptedTextField: "test three", EncryptedJsonbField: generateJsonbData("foo", "boo", "bah")}

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

	var allExamples []Example
	query, errQuery := goeql.SerializeQuery("test two", "examples", "encrypted_text_field")
	if errQuery != nil {
		log.Fatalf("err: %v", errQuery)
	}
	queryErr := engine.Where("cs_unique_v1(encrypted_text_field) = cs_unique_v1($1)", query).Find(&allExamples)
	if queryErr != nil {
		log.Fatalf("Could not retrieve unique example: %v", queryErr)
	}

	fmt.Println("Example unique query retrieved:", allExamples)
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
