package main

import (
	"fmt"
	"log"
	"testing"

	"github.com/encrypt-query-language/languages/go/goeql"
	"github.com/stretchr/testify/assert"
	"xorm.io/xorm"
)

func proxyEngine() *xorm.Engine {

	proxyConnStr := "user=postgres password=postgres port=6432 host=localhost dbname=gotest sslmode=disable"
	proxyEngine, err := xorm.NewEngine("pgx", proxyConnStr)

	if err != nil {
		log.Fatalf("Could not connect to the database: %v", err)
	}

	return proxyEngine
}

func truncateDb(engine *xorm.Engine) error {
	query := "TRUNCATE TABLE examples"
	_, err := engine.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to truncate table: %v", err)
	}

	return nil
}

func TestWhereQueryOnUnencryptedColumn(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)

	jsonData := map[string]any{
		"top": map[string]any{
			"integer": float64(101),
			"float":   1.234,
		},
		"bottom": "value_three",
	}

	newExample := Example{NonEncryptedField: "sydney", EncryptedIntField: 23, EncryptedTextField: "test@test.com", EncryptedJsonbField: jsonData}

	_, err := engine.Insert(&newExample)
	if err != nil {
		t.Fatalf("Could not insert new example: %v", err)
	}

	var example Example
	text := "sydney"

	has, err := engine.Where("non_encrypted_field = ?", text).Get(&example)
	if err != nil {
		t.Fatalf("Could not retrieve example: %v", err)
	}

	if !has {
		t.Errorf("Expected has to equal true, got: %v", has)
	}

	assert.Equal(t, newExample.NonEncryptedField, example.NonEncryptedField, "NonEncryptedField does not match")
	assert.Equal(t, newExample.EncryptedIntField, example.EncryptedIntField, "EncryptedIntField does not match")
	assert.Equal(t, newExample.EncryptedTextField, example.EncryptedTextField, "EncryptedTextField does not match")
	assert.Equal(t, newExample.EncryptedJsonbField, example.EncryptedJsonbField, "EncryptedJsonbField does not match")
}

func TestMatchQueryLongString(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)

	jsonData := map[string]any{
		"top": map[string]any{
			"integer": float64(101),
			"float":   1.234,
		},
		"bottom": "value_three",
	}

	examples := []Example{
		{
			NonEncryptedField:   "sydney",
			EncryptedIntField:   23,
			EncryptedTextField:  "this is a long string",
			EncryptedJsonbField: jsonData,
		},
		{
			NonEncryptedField:   "melbourne",
			EncryptedIntField:   42,
			EncryptedTextField:  "quick brown fox jumped",
			EncryptedJsonbField: jsonData,
		},
	}

	inserted, err := engine.Insert(&examples)

	if err != nil {
		t.Errorf("Error inserting examples: %v", err)
	}

	assert.Equal(t, int64(2), inserted, "Expected to insert 2 rows")

	query, err := goeql.SerializeMatchQuery("this", "examples", "encrypted_text_field")
	if err != nil {
		log.Fatalf("Error marshaling encrypted_text_field query: %v", err)
	}

	var returnedExample Example
	has, err := engine.Where("cs_match_v1(encrypted_text_field) @> cs_match_v1(?)", query).Get(&returnedExample)
	if err != nil {
		t.Fatalf("Could not retrieve example: %v", err)
	}

	if !has {
		t.Errorf("Expected has to equal true, got: %v", has)
	}

	assert.Equal(t, returnedExample.EncryptedTextField, EncryptedTextField("this is a long string"), "EncryptedTextField should match")
}

func TestMatchQueryEmail(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)

	jsonData := map[string]any{
		"top": map[string]any{
			"integer": float64(101),
			"float":   1.234,
		},
		"bottom": "value_three",
	}

	examples := []Example{
		{
			NonEncryptedField:   "sydney",
			EncryptedIntField:   23,
			EncryptedTextField:  "testemail@test.com",
			EncryptedJsonbField: jsonData,
		},
		{
			NonEncryptedField:   "melbourne",
			EncryptedIntField:   42,
			EncryptedTextField:  "someone@gmail.com",
			EncryptedJsonbField: jsonData,
		},
	}

	inserted, err := engine.Insert(&examples)

	if err != nil {
		t.Errorf("Error inserting examples: %v", err)
	}

	assert.Equal(t, int64(2), inserted, "Expected to insert 2 rows")

	query, err := goeql.SerializeMatchQuery("test", "examples", "encrypted_text_field")
	if err != nil {
		log.Fatalf("Error marshaling encrypted_text_field query: %v", err)
	}

	var returnedExample Example
	has, err := engine.Where("cs_match_v1(encrypted_text_field) @> cs_match_v1(?)", query).Get(&returnedExample)
	if err != nil {
		t.Fatalf("Could not retrieve example: %v", err)
	}

	if !has {
		t.Errorf("Expected has to equal true, got: %v", has)
	}

	assert.Equal(t, returnedExample.EncryptedTextField, EncryptedTextField("testemail@test.com"), "EncryptedTextField should match")
}

func TestJsonbQuerySimple(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)

	expectedJson := map[string]any{
		"top": map[string]any{
			"integer": float64(101),
			"float":   1.234,
			"string":  "some string",
		},
		"bottom": "value_three",
	}

	examples := []Example{
		{
			NonEncryptedField:   "sydney",
			EncryptedTextField:  "testing",
			EncryptedIntField:   42,
			EncryptedJsonbField: expectedJson,
		},
		{
			NonEncryptedField:   "melbourne",
			EncryptedIntField:   42,
			EncryptedTextField:  "someone@gmail.com",
			EncryptedJsonbField: generateJsonbData("first", "second", "third"),
		},
	}

	inserted, err := engine.Insert(&examples)

	if err != nil {
		t.Errorf("Error inserting examples: %v", err)
	}

	assert.Equal(t, int64(2), inserted, "Expected to insert 2 rows")

	// create a query
	jsonbQuery := map[string]any{
		"top": map[string]any{
			"integer": float64(101),
		},
	}

	query, errTwo := goeql.SerializeJsonbQuery(jsonbQuery, "examples", "encrypted_jsonb_field")
	if errTwo != nil {
		log.Fatalf("Error marshaling encrypted_jsonb_field: %v", errTwo)
	}

	var returnedExample Example
	has, err := engine.Where("cs_ste_vec_v1(encrypted_jsonb_field) @> cs_ste_vec_v1(?)", query).Get(&returnedExample)
	if err != nil {
		t.Fatalf("Could not retrieve example: %v", err)
	}

	if !has {
		t.Errorf("Expected has to equal true, got: %v", has)
	}

	assert.Equal(t, returnedExample.EncryptedJsonbField, EncryptedJsonbField(expectedJson), "EncryptedJsonb field should match")
}

func TestJsonbQueryNested(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)

	expectedJson := map[string]any{
		"top": map[string]any{
			"integer": float64(101),
			"float":   1.234,
			"string":  "some string",
			"nested_one": map[string]any{
				"nested_two": "hello world",
			},
		},
		"bottom": "value_three",
	}

	examples := []Example{
		{
			NonEncryptedField:   "sydney",
			EncryptedTextField:  "testing",
			EncryptedIntField:   42,
			EncryptedJsonbField: expectedJson,
		},
		{
			NonEncryptedField:   "melbourne",
			EncryptedIntField:   42,
			EncryptedTextField:  "someone@gmail.com",
			EncryptedJsonbField: generateJsonbData("first", "second", "third"),
		},
	}

	inserted, err := engine.Insert(&examples)

	if err != nil {
		t.Errorf("Error inserting examples: %v", err)
	}

	assert.Equal(t, int64(2), inserted, "Expected to insert 2 rows")

	// create a query
	jsonbQuery := map[string]any{
		"top": map[string]any{
			"nested_one": map[string]any{
				"nested_two": "hello world",
			},
		},
	}

	query, errTwo := goeql.SerializeJsonbQuery(jsonbQuery, "examples", "encrypted_jsonb_field")
	if errTwo != nil {
		log.Fatalf("Error marshaling encrypted_jsonb_field: %v", errTwo)
	}

	var returnedExample Example
	has, err := engine.Where("cs_ste_vec_v1(encrypted_jsonb_field) @> cs_ste_vec_v1(?)", query).Get(&returnedExample)
	if err != nil {
		t.Fatalf("Could not retrieve example: %v", err)
	}

	if !has {
		t.Errorf("Expected has to equal true, got: %v", has)
	}

	assert.Equal(t, returnedExample.EncryptedJsonbField, EncryptedJsonbField(expectedJson), "EncryptedJsonb field should match")
}

func TestOreStringRangeQuery(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)
	expected := EncryptedTextField("whale")

	examples := []Example{
		{
			NonEncryptedField:   "sydney",
			EncryptedTextField:  expected,
			EncryptedIntField:   42,
			EncryptedJsonbField: generateJsonbData("first", "second", "third"),
		},
		{
			NonEncryptedField:   "melbourne",
			EncryptedIntField:   42,
			EncryptedTextField:  "apple",
			EncryptedJsonbField: generateJsonbData("first", "second", "third"),
		},
	}

	inserted, err := engine.Insert(&examples)

	if err != nil {
		t.Errorf("Error inserting examples: %v", err)
	}

	assert.Equal(t, int64(2), inserted, "Expected to insert 2 rows")

	// Query
	query, errQuery := goeql.SerializeOreQuery("tree", "examples", "encrypted_text_field")
	if errQuery != nil {
		log.Fatalf("err: %v", errQuery)
	}

	var returnedExample Example
	has, err := engine.Where("cs_ore_64_8_v1(encrypted_text_field) > cs_ore_64_8_v1(?)", query).Get(&returnedExample)
	if err != nil {
		t.Fatalf("Could not retrieve example: %v", err)
	}

	if !has {
		t.Errorf("Expected has to equal true, got: %v", has)
	}

	assert.Equal(t, returnedExample.EncryptedTextField, expected, "EncryptedText field should match")
}

func TestOreIntRangeQuery(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)
	expected := EncryptedIntField(42)

	examples := []Example{
		{
			NonEncryptedField:   "sydney",
			EncryptedTextField:  "whale",
			EncryptedIntField:   expected,
			EncryptedJsonbField: generateJsonbData("first", "second", "third"),
		},
		{
			NonEncryptedField:   "melbourne",
			EncryptedIntField:   23,
			EncryptedTextField:  "apple",
			EncryptedJsonbField: generateJsonbData("first", "second", "third"),
		},
	}

	inserted, err := engine.Insert(&examples)

	if err != nil {
		t.Errorf("Error inserting examples: %v", err)
	}

	assert.Equal(t, int64(2), inserted, "Expected to insert 2 rows")

	// Query
	query, errQuery := goeql.SerializeOreQuery(32, "examples", "encrypted_int_field")
	if errQuery != nil {
		log.Fatalf("err: %v", errQuery)
	}

	var returnedExample Example
	has, err := engine.Where("cs_ore_64_8_v1(encrypted_int_field) > cs_ore_64_8_v1(?)", query).Get(&returnedExample)
	if err != nil {
		t.Fatalf("Could not retrieve example: %v", err)
	}

	if !has {
		t.Errorf("Expected has to equal true, got: %v", has)
	}

	assert.Equal(t, returnedExample.EncryptedIntField, expected, "EncryptedInt field should match")
}

func TestOreBoolRangeQuery(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)
	expected := EncryptedBoolField(true)

	examples := []Example{
		{
			NonEncryptedField:   "sydney",
			EncryptedTextField:  "whale",
			EncryptedIntField:   42,
			EncryptedJsonbField: generateJsonbData("first", "second", "third"),
			EncryptedBoolField:  false,
		},
		{
			NonEncryptedField:   "melbourne",
			EncryptedIntField:   23,
			EncryptedTextField:  "pineapple",
			EncryptedJsonbField: generateJsonbData("first", "second", "third"),
			EncryptedBoolField:  expected,
		},
		{
			NonEncryptedField:   "launceston",
			EncryptedIntField:   23,
			EncryptedTextField:  "apple",
			EncryptedJsonbField: generateJsonbData("first", "second", "third"),
			EncryptedBoolField:  false,
		},
	}

	inserted, err := engine.Insert(&examples)

	if err != nil {
		t.Errorf("Error inserting examples: %v", err)
	}

	assert.Equal(t, int64(3), inserted, "Expected to insert 3 rows")

	// Query
	query, errQuery := goeql.SerializeOreQuery(false, "examples", "encrypted_bool_field")
	if errQuery != nil {
		log.Fatalf("err: %v", errQuery)
	}

	var returnedExample Example
	has, err := engine.Where("cs_ore_64_8_v1(encrypted_bool_field) > cs_ore_64_8_v1(?)", query).Get(&returnedExample)
	if err != nil {
		t.Fatalf("Could not retrieve example: %v", err)
	}

	if !has {
		t.Errorf("Expected has to equal true, got: %v", has)
	}

	assert.Equal(t, returnedExample.EncryptedBoolField, expected, "EncryptedBool field should match")
}

func TestUniqueStringQuery(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)
	expected := EncryptedTextField("testing two")

	examples := []Example{
		{
			NonEncryptedField:   "sydney",
			EncryptedTextField:  "whale",
			EncryptedIntField:   42,
			EncryptedJsonbField: generateJsonbData("first", "second", "third"),
			EncryptedBoolField:  false,
		},
		{
			NonEncryptedField:   "melbourne",
			EncryptedIntField:   23,
			EncryptedTextField:  expected,
			EncryptedJsonbField: generateJsonbData("first", "second", "third"),
			EncryptedBoolField:  true,
		},
		{
			NonEncryptedField:   "launceston",
			EncryptedIntField:   23,
			EncryptedTextField:  "apple",
			EncryptedJsonbField: generateJsonbData("first", "second", "third"),
			EncryptedBoolField:  false,
		},
	}

	inserted, err := engine.Insert(&examples)

	if err != nil {
		t.Errorf("Error inserting examples: %v", err)
	}

	assert.Equal(t, int64(3), inserted, "Expected to insert 3 rows")

	// Query
	query, errQuery := goeql.SerializeUniqueQuery("testing two", "examples", "encrypted_text_field")
	if errQuery != nil {
		log.Fatalf("err: %v", errQuery)
	}

	var returnedExample Example
	has, err := engine.Where("cs_unique_v1(encrypted_text_field) = cs_unique_v1($1)", query).Get(&returnedExample)
	if err != nil {
		t.Fatalf("Could not retrieve example: %v", err)
	}

	if !has {
		t.Errorf("Expected has to equal true, got: %v", has)
	}

	assert.Equal(t, returnedExample.EncryptedTextField, expected, "EncryptedText field should match")
}
