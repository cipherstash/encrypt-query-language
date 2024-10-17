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

	assert.Equal(t, newExample.NonEncryptedField, example.NonEncryptedField, "NonEncryptedField should match")
	assert.Equal(t, newExample.EncryptedIntField, example.EncryptedIntField, "EncryptedIntField should match")
	assert.Equal(t, newExample.EncryptedTextField, example.EncryptedTextField, "EncryptedTextField should match")
	assert.Equal(t, newExample.EncryptedJsonbField, example.EncryptedJsonbField, "EncryptedJsonbField should match")
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

	query, err := goeql.SerializeQuery("this", "examples", "encrypted_text_field")
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

	query, err := goeql.SerializeQuery("test", "examples", "encrypted_text_field")
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

	query, errTwo := goeql.SerializeQuery(jsonbQuery, "examples", "encrypted_jsonb_field")
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
