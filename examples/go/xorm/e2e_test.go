package main

import (
	"encoding/json"
	"fmt"
	"log"
	"reflect"
	"testing"

	"github.com/cipherstash/goeql"
	"github.com/stretchr/testify/assert"
	"xorm.io/xorm"
)

func proxyEngine() *xorm.Engine {

	proxyConnStr := "user=postgres password=postgres port=6432 host=localhost dbname=postgres sslmode=disable"
	proxyEngine, err := xorm.NewEngine("pgx", proxyConnStr)

	if err != nil {
		log.Fatalf("Could not connect to the database: %v", err)
	}

	return proxyEngine
}

func truncateDb(engine *xorm.Engine) error {
	query := "TRUNCATE TABLE goexamples"
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

	var returnedExample Example
	text := "sydney"

	has, err := engine.Where("non_encrypted_field = ?", text).Get(&returnedExample)
	if err != nil {
		t.Fatalf("Could not retrieve example: %v", err)
	}

	if !has {
		t.Errorf("Expected has to equal true, got: %v", has)
	}

	assert.Equal(t, newExample.NonEncryptedField, returnedExample.NonEncryptedField, "NonEncryptedField does not match")
	assert.Equal(t, newExample.EncryptedIntField, returnedExample.EncryptedIntField, "EncryptedIntField does not match")
	assert.Equal(t, newExample.EncryptedTextField, returnedExample.EncryptedTextField, "EncryptedTextField does not match")
	assert.Equal(t, newExample.EncryptedJsonbField, returnedExample.EncryptedJsonbField, "EncryptedJsonbField does not match")
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

	goexamples := []Example{
		{
			NonEncryptedField:   "brisbane",
			EncryptedIntField:   23,
			EncryptedTextField:  "another string that shouldn't be returned",
			EncryptedJsonbField: jsonData,
		},
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

	inserted, err := engine.Insert(&goexamples)

	if err != nil {
		t.Errorf("Error inserting goexamples: %v", err)
	}

	assert.Equal(t, int64(3), inserted, "Expected to insert 2 rows")

	query, err := goeql.MatchQuery("this", "goexamples", "encrypted_text_field")
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

	assert.Equal(t, EncryptedTextField("this is a long string"), returnedExample.EncryptedTextField, "EncryptedTextField should match")
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

	goexamples := []Example{
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

	inserted, err := engine.Insert(&goexamples)

	if err != nil {
		t.Errorf("Error inserting goexamples: %v", err)
	}

	assert.Equal(t, int64(2), inserted, "Expected to insert 2 rows")

	query, err := goeql.MatchQuery("test", "goexamples", "encrypted_text_field")
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

	assert.Equal(t, EncryptedTextField("testemail@test.com"), returnedExample.EncryptedTextField, "EncryptedTextField should match")
}

func TestJsonbQueryContainment(t *testing.T) {
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

	goexamples := []Example{
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

	inserted, err := engine.Insert(&goexamples)

	if err != nil {
		t.Errorf("Error inserting goexamples: %v", err)
	}

	assert.Equal(t, int64(2), inserted, "Expected to insert 2 rows")

	// create a query
	jsonbQuery := map[string]any{
		"top": map[string]any{
			"integer": float64(101),
		},
	}

	query, errTwo := goeql.JsonbQuery(jsonbQuery, "goexamples", "encrypted_jsonb_field")
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

	assert.Equal(t, EncryptedJsonbField(expectedJson), returnedExample.EncryptedJsonbField, "EncryptedJsonb field should match")
}

func TestJsonbQueryNestedContainment(t *testing.T) {
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

	goexamples := []Example{
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

	inserted, err := engine.Insert(&goexamples)

	if err != nil {
		t.Errorf("Error inserting goexamples: %v", err)
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

	query, errTwo := goeql.JsonbQuery(jsonbQuery, "goexamples", "encrypted_jsonb_field")
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

	assert.Equal(t, EncryptedJsonbField(expectedJson), returnedExample.EncryptedJsonbField, "EncryptedJsonb field should match")
}

func TestJsonbExtractionOp(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)

	expected_one := map[string]interface{}{
		"nested_two": "hello world",
	}
	jsonOne := map[string]interface{}{
		"top": map[string]interface{}{
			"integer": float64(101),
			"float":   1.234,
			"string":  "some string",
			"nested":  expected_one,
		},
		"bottom": "value_three",
	}
	expected_two := map[string]interface{}{
		"nested_two": "foo bar",
	}
	jsonTwo := map[string]interface{}{
		"top": map[string]interface{}{
			"integer": float64(101),
			"float":   1.234,
			"string":  "some string",
			"nested":  expected_two,
		},
		"bottom": "value_three",
	}

	goexamples := []Example{
		{
			NonEncryptedField:   "sydney",
			EncryptedTextField:  "testing",
			EncryptedIntField:   42,
			EncryptedJsonbField: jsonOne,
		},
		{
			NonEncryptedField:   "melbourne",
			EncryptedIntField:   42,
			EncryptedTextField:  "someone@gmail.com",
			EncryptedJsonbField: jsonTwo,
		},
	}

	inserted, err := engine.Insert(&goexamples)

	if err != nil {
		t.Errorf("Error inserting goexamples: %v", err)
	}

	assert.Equal(t, int64(2), inserted, "Expected to insert 2 rows")

	sql := `SELECT cs_ste_vec_value_v1(encrypted_jsonb_field, ?) AS val FROM goexamples`
	ejson_path, err := goeql.EJsonPathQuery("$.top.nested", "goexamples", "encrypted_jsonb_field")

	if err != nil {
		log.Fatalf("Error serializing fields_encrypted query: %v", err)
	}
	results, err := engine.Query(sql, ejson_path)
	if err != nil {
		t.Fatalf("Could not retrieve example using extraction: %v", err)
	}

	assert.Equal(t, 2, len(results))

	for i := range results {

		var encryptedJson goeql.EncryptedJsonb

		deserializedValue, err := encryptedJson.Deserialize(results[i]["val"])
		if err != nil {
			log.Fatal("Deserialization error:", err)
		}
		jsonb_expected_one := goeql.EncryptedJsonb(expected_one)
		jsonb_expected_two := goeql.EncryptedJsonb(expected_two)

		if !reflect.DeepEqual(deserializedValue, jsonb_expected_one) && !reflect.DeepEqual(deserializedValue, jsonb_expected_two) {
			t.Errorf("Expected value to be either %v or %v, but got %v", jsonb_expected_one, jsonb_expected_two, deserializedValue)
		}

	}
}

func TestJsonbComparisonOp(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)

	jsonOne := map[string]interface{}{
		"top": map[string]interface{}{
			"integer": 3,
			"float":   1.234,
			"string":  "some string",
		},
		"bottom": "value_three",
	}
	jsonTwo := map[string]interface{}{
		"top": map[string]interface{}{
			"integer": 50,
			"float":   1.234,
			"string":  "some string",
		},
		"bottom": "value_three",
	}
	expected_id := int64(2)
	example_one := Example{
		Id:                  int64(1),
		NonEncryptedField:   "sydney",
		EncryptedTextField:  "testing",
		EncryptedIntField:   42,
		EncryptedJsonbField: jsonOne,
	}
	example_two := Example{
		Id:                  expected_id,
		NonEncryptedField:   "melbourne",
		EncryptedIntField:   42,
		EncryptedTextField:  "someone@gmail.com",
		EncryptedJsonbField: jsonTwo,
	}

	goexamples := []Example{
		example_one,
		example_two,
	}

	inserted, err := engine.Insert(&goexamples)

	if err != nil {
		t.Errorf("Error inserting goexamples: %v", err)
	}

	assert.Equal(t, int64(2), inserted, "Expected to insert 2 rows")

	path := "$.top.integer"
	ejson_path, err := goeql.EJsonPathQuery(path, "goexamples", "encrypted_jsonb_field")

	if err != nil {
		log.Fatalf("Error serializing fields_encrypted query: %v", err)
	}
	value := 10
	comparison_value, err := goeql.JsonbQuery(value, "goexamples", "encrypted_jsonb_field")

	if err != nil {
		log.Fatalf("Error marshaling comparison value: %v", err)
	}
	var results []Example
	err = engine.Where("cs_ste_vec_term_v1(goexamples.encrypted_jsonb_field, ?) > cs_ste_vec_term_v1(?)", ejson_path, comparison_value).Find(&results)

	if err != nil {
		t.Fatalf("Could not retrieve example using comparison op: %v", err)
	}

	assert.Equal(t, 1, len(results))
	assert.Equal(t, expected_id, results[0].Id)
}

func TestJsonbTermsOp(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)

	jsonOne := map[string]interface{}{
		"top": map[string]interface{}{
			"integer": 3,
			"float":   1.234,
			"string":  "some string",
			"nums":    []int64{1, 2, 3},
		},
		"bottom": "value_three",
	}
	jsonTwo := map[string]interface{}{
		"top": map[string]interface{}{
			"integer": 50,
			"float":   1.234,
			"string":  "some string",
			"nums":    []int64{4, 5, 6},
		},
		"bottom": "value_three",
	}
	expected_id := int64(2)
	example_one := Example{
		Id:                  int64(1),
		NonEncryptedField:   "sydney",
		EncryptedTextField:  "testing",
		EncryptedIntField:   42,
		EncryptedJsonbField: jsonOne,
		EncryptedBoolField:  true,
	}
	example_two := Example{
		Id:                  expected_id,
		NonEncryptedField:   "melbourne",
		EncryptedIntField:   42,
		EncryptedTextField:  "someone@gmail.com",
		EncryptedJsonbField: jsonTwo,
		EncryptedBoolField:  false,
	}

	goexamples := []Example{
		example_one,
		example_two,
	}

	inserted, err := engine.Insert(&goexamples)

	if err != nil {
		t.Errorf("Error inserting goexamples: %v", err)
	}

	assert.Equal(t, int64(2), inserted, "Expected to insert 2 rows")

	// Serialize value as jsonb
	value := 5
	comparison_value, err := goeql.JsonbQuery(value, "goexamples", "encrypted_jsonb_field")
	if err != nil {
		log.Fatalf("Error marshaling comparison value: %v", err)
	}
	// Serialize path
	path := "$.top.nums[*]"
	ejson_path, err := goeql.EJsonPathQuery(path, "goexamples", "encrypted_jsonb_field")

	sql := `SELECT * from goexamples e
			WHERE EXISTS (
			SELECT 1
				FROM unnest(cs_ste_vec_terms_v1(e.encrypted_jsonb_field, ?)) AS term
				WHERE term > cs_ste_vec_term_v1(?)
			)`

	if err != nil {
		log.Fatalf("Error serializing encrypted_jsonb_field query: %v", err)
	}

	results, err := engine.Query(sql, ejson_path, comparison_value)
	if err != nil {
		t.Fatalf("Could not retrieve example using terms: %v", err)
	}

	assert.Equal(t, 1, len(results))

	var jsonData int64
	if err := json.Unmarshal(results[0]["id"], &jsonData); err != nil {
		t.Fatalf("Could not unmarshal %v", err)
	}
	assert.Equal(t, expected_id, jsonData)
}

func TestJsonbNullWriteRead(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)

	example_one := Example{
		NonEncryptedField:   "sydney",
		EncryptedTextField:  "test@gmail.com",
		EncryptedIntField:   42,
		EncryptedJsonbField: nil,
		EncryptedBoolField:  true,
	}

	example_two := Example{
		NonEncryptedField:   "melbourne",
		EncryptedIntField:   42,
		EncryptedTextField:  "someone@gmail.com",
		EncryptedJsonbField: make(map[string]interface{}),
		EncryptedBoolField:  false,
	}

	goexamples := []Example{
		example_one,
		example_two,
	}

	inserted, err := engine.Insert(&goexamples)

	if err != nil {
		t.Errorf("Error inserting goexamples: %v", err)
	}

	assert.Equal(t, int64(2), inserted, "Expected to insert 2 rows")

	var returnedgoExamples []Example
	err = engine.Where("encrypted_jsonb_field IS NULL").Find(&returnedgoExamples)
	if err != nil {
		t.Fatalf("Could not retrieve example: %v", err)
	}

	for i := range returnedgoExamples {
		assert.Equal(t, EncryptedJsonbField(nil), returnedgoExamples[i].EncryptedJsonbField)
	}
}

func TestTextNullWriteRead(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)

	example_one := Example{
		NonEncryptedField:   "sydney",
		EncryptedIntField:   42,
		EncryptedJsonbField: generateJsonbData("first", "second", "third"),
		EncryptedBoolField:  true,
	}

	example_two := Example{
		NonEncryptedField:   "melbourne",
		EncryptedTextField:  "someone@gmail.com",
		EncryptedIntField:   42,
		EncryptedJsonbField: make(map[string]interface{}),
		EncryptedBoolField:  false,
	}

	goexamples := []Example{
		example_one,
		example_two,
	}

	inserted, err := engine.Insert(&goexamples)

	if err != nil {
		t.Errorf("Error inserting goexamples: %v", err)
	}

	assert.Equal(t, int64(2), inserted, "Expected to insert 2 rows")

	results, err := engine.Query("select * from goexamples")
	if err != nil {
		t.Fatalf("Could not retrieve goexamples: %v", err)
	}

	assert.Equal(t, 2, len(results))
}

func TestIntNullWriteRead(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)

	example_one := Example{
		NonEncryptedField:   "sydney",
		EncryptedTextField:  "test@gmail.com",
		EncryptedJsonbField: generateJsonbData("first", "second", "third"),
		EncryptedBoolField:  true,
	}

	example_two := Example{
		NonEncryptedField:   "melbourne",
		EncryptedTextField:  "someone@gmail.com",
		EncryptedIntField:   42,
		EncryptedJsonbField: make(map[string]interface{}),
		EncryptedBoolField:  false,
	}

	goexamples := []Example{
		example_one,
		example_two,
	}

	inserted, err := engine.Insert(&goexamples)

	if err != nil {
		t.Errorf("Error inserting goexamples: %v", err)
	}

	assert.Equal(t, int64(2), inserted, "Expected to insert 2 rows")

	results, err := engine.Query("select * from goexamples")
	if err != nil {
		t.Fatalf("Could not retrieve goexamples: %v", err)
	}

	assert.Equal(t, 2, len(results))
}

func TestBooleanNullWriteRead(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)

	// Remove boolean field
	example_one := Example{
		NonEncryptedField:   "sydney",
		EncryptedTextField:  "test@gmail.com",
		EncryptedJsonbField: generateJsonbData("first", "second", "third"),
	}

	example_two := Example{
		NonEncryptedField:   "melbourne",
		EncryptedTextField:  "someone@gmail.com",
		EncryptedIntField:   42,
		EncryptedJsonbField: make(map[string]interface{}),
		EncryptedBoolField:  false,
	}

	goexamples := []Example{
		example_one,
		example_two,
	}

	inserted, err := engine.Insert(&goexamples)

	if err != nil {
		t.Errorf("Error inserting goexamples: %v", err)
	}

	assert.Equal(t, int64(2), inserted, "Expected to insert 2 rows")

	results, err := engine.Query("select * from goexamples")
	if err != nil {
		t.Fatalf("Could not retrieve goexamples: %v", err)
	}

	assert.Equal(t, 2, len(results))
}

func TestOreStringRangeQuery(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)
	expected := EncryptedTextField("whale")

	goexamples := []Example{
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

	inserted, err := engine.Insert(&goexamples)

	if err != nil {
		t.Errorf("Error inserting goexamples: %v", err)
	}

	assert.Equal(t, int64(2), inserted, "Expected to insert 2 rows")

	// Query
	query, errQuery := goeql.OreQuery("tree", "goexamples", "encrypted_text_field")
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

	assert.Equal(t, expected, returnedExample.EncryptedTextField, "EncryptedText field should match")
}

func TestOreIntRangeQuery(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)
	expected := EncryptedIntField(42)

	goexamples := []Example{
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

	inserted, err := engine.Insert(&goexamples)

	if err != nil {
		t.Errorf("Error inserting goexamples: %v", err)
	}

	assert.Equal(t, int64(2), inserted, "Expected to insert 2 rows")

	// Query
	query, errQuery := goeql.OreQuery(32, "goexamples", "encrypted_int_field")
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

	assert.Equal(t, expected, returnedExample.EncryptedIntField, "EncryptedInt field should match")
}

func TestOreBoolRangeQuery(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)
	expected := EncryptedBoolField(true)

	goexamples := []Example{
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

	inserted, err := engine.Insert(&goexamples)

	if err != nil {
		t.Errorf("Error inserting goexamples: %v", err)
	}

	assert.Equal(t, int64(3), inserted, "Expected to insert 3 rows")

	// Query
	query, errQuery := goeql.OreQuery(false, "goexamples", "encrypted_bool_field")
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

	assert.Equal(t, expected, returnedExample.EncryptedBoolField, "EncryptedBool field should match")
}

func TestUniqueStringQuery(t *testing.T) {
	engine := proxyEngine()
	truncateDb(engine)
	expected := EncryptedTextField("testing two")

	goexamples := []Example{
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

	inserted, err := engine.Insert(&goexamples)

	if err != nil {
		t.Errorf("Error inserting goexamples: %v", err)
	}

	assert.Equal(t, int64(3), inserted, "Expected to insert 3 rows")

	// Query
	query, errQuery := goeql.UniqueQuery("testing two", "goexamples", "encrypted_text_field")
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

	assert.Equal(t, expected, returnedExample.EncryptedTextField, "EncryptedText field should match")
}

func generateJsonbData(value_one string, value_two string, value_three string) map[string]any {
	data := map[string]any{
		"top": map[string]any{
			"nested": []any{value_one, value_two},
		},
		"bottom": value_three,
	}

	return data
}
