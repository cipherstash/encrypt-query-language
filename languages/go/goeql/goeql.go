package goeql

// goeql is a collection of helpers for serializing and deserializing values
// into the shape EQL and the CipherStash Proxy needs to enable encryption and
// decryption of values, and search of those encrypted values while keeping them
// encrypted at all times.

// EQL expects a json format that looks like this:
//
// '{"k":"pt","p":"a string representation of the plaintext that is being encrypted","i":{"t":"table","c":"column"},"v":1}'
//
// More documentation on this format can be found at https://github.com/cipherstash/encrypt-query-language#data-format

import (
	"encoding/json"
	"fmt"
	"strconv"
)

// TableColumn represents the table and column an encrypted value belongs to
type TableColumn struct {
	T string `json:"t"`
	C string `json:"c"`
}

// EncryptedColumn represents the plaintext value sent by a database client
type EncryptedColumn struct {
	K string      `json:"k"`
	P string      `json:"p"`
	I TableColumn `json:"i"`
	V int         `json:"v"`
	Q string      `json:"q"`
}

// EncryptedText is a string value to be encrypted
type EncryptedText string

// EncryptedJsonb is a jsonb value to be encrypted
type EncryptedJsonb map[string]interface{}

// EncryptedInt is a int value to be encrypted
type EncryptedInt int

// EncryptedBool is a bool value to be encrypted
type EncryptedBool bool

// Serialize turns a EncryptedText value into a jsonb payload for CipherStash Proxy
func (et EncryptedText) Serialize(table string, column string) ([]byte, error) {
	val, err := ToEncryptedColumn(string(et), table, column)
	if err != nil {
		return nil, fmt.Errorf("error serializing: %v", err)
	}
	return json.Marshal(val)
}

// Deserialize turns a jsonb payload from CipherStash Proxy into an EncryptedText value
func (et *EncryptedText) Deserialize(data []byte) (EncryptedText, error) {
	var jsonData map[string]interface{}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		return "", err
	}

	if pValue, ok := jsonData["p"].(string); ok {
		return EncryptedText(pValue), nil
	}

	return "", fmt.Errorf("invalid format: missing 'p' field in JSONB")
}

// Serialize turns a EncryptedJsonb value into a jsonb payload for CipherStash Proxy
func (ej EncryptedJsonb) Serialize(table string, column string) ([]byte, error) {
	val, err := ToEncryptedColumn(map[string]any(ej), table, column)
	if err != nil {
		return nil, fmt.Errorf("error serializing: %v", err)
	}
	return json.Marshal(val)
}

// Deserialize turns a jsonb payload from CipherStash Proxy into an EncryptedJsonb value
func (ej *EncryptedJsonb) Deserialize(data []byte) (EncryptedJsonb, error) {
	var jsonData map[string]interface{}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		return nil, err
	}

	if pValue, ok := jsonData["p"].(string); ok {
		var pData map[string]interface{}
		if err := json.Unmarshal([]byte(pValue), &pData); err != nil {
			return nil, fmt.Errorf("error unmarshaling 'p' JSON string: %v", err)
		}

		return EncryptedJsonb(pData), nil
	}

	return nil, fmt.Errorf("invalid format: missing 'p' field in JSONB")
}

// Serialize turns a EncryptedInt value into a jsonb payload for CipherStash Proxy
func (et EncryptedInt) Serialize(table string, column string) ([]byte, error) {
	val, err := ToEncryptedColumn(int(et), table, column)
	if err != nil {
		return nil, fmt.Errorf("error serializing: %v", err)
	}
	return json.Marshal(val)
}

// Deserialize turns a jsonb payload from CipherStash Proxy into an EncryptedInt value
func (et *EncryptedInt) Deserialize(data []byte) (EncryptedInt, error) {
	var jsonData map[string]interface{}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		return 0, fmt.Errorf("error unmarshaling 'p' JSON string: %v", err)
	}

	if pValue, ok := jsonData["p"].(string); ok {
		parsedValue, err := strconv.Atoi(pValue) // Convert string to int
		if err != nil {
			return 0, fmt.Errorf("invalid number format in 'p' field: %v", err)
		}
		return EncryptedInt(parsedValue), nil
	}

	return 0, fmt.Errorf("invalid format: missing 'p' field")
}

// Serialize turns a EncryptedBool value into a jsonb payload for CipherStash Proxy
func (eb EncryptedBool) Serialize(table string, column string) ([]byte, error) {
	val, err := ToEncryptedColumn(bool(eb), table, column)
	if err != nil {
		return nil, fmt.Errorf("error serializing: %v", err)
	}
	return json.Marshal(val)
}

// Deserialize turns a jsonb payload from CipherStash Proxy into an EncryptedBool value
func (eb *EncryptedBool) Deserialize(data []byte) (EncryptedBool, error) {
	var jsonData map[string]interface{}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		// TODO: Check the best return values for these.
		return false, err
	}

	if pValue, ok := jsonData["p"].(string); ok {
		parsedValue, err := strconv.ParseBool(pValue)
		if err != nil {
			return false, fmt.Errorf("invalid boolean format in 'p' field: %v", err)
		}
		return EncryptedBool(parsedValue), nil
	}

	return false, fmt.Errorf("invalid format: missing 'p' field")
}

// MatchQuery serializes a plaintext value used in a match query
func MatchQuery(value any, table string, column string) ([]byte, error) {
	return serializeQuery(value, table, column, "match")
}

// OreQuery serializes a plaintext value used in an ore query
func OreQuery(value any, table string, column string) ([]byte, error) {
	return serializeQuery(value, table, column, "ore")
}

// UniqueQuery serializes a plaintext value used in a unique query
func UniqueQuery(value any, table string, column string) ([]byte, error) {
	return serializeQuery(value, table, column, "unique")
}

// JsonbQuery serializes a plaintext value used in a jsonb query
func JsonbQuery(value any, table string, column string) ([]byte, error) {
	return serializeQuery(value, table, column, "ste_vec")
}

// serializeQuery produces a jsonb payload used by EQL query functions to perform search operations like equality checks, range queries, and unique constraints.
func serializeQuery(value any, table string, column string, queryType string) ([]byte, error) {
	query, err := ToEncryptedColumn(value, table, column, queryType)
	if err != nil {
		return nil, fmt.Errorf("error converting to EncryptedColumn: %v", err)
	}
	serializedQuery, errMarshal := json.Marshal(query)

	if errMarshal != nil {
		return nil, fmt.Errorf("error marshalling EncryptedColumn: %v", errMarshal)
	}
	return serializedQuery, nil

}

// ToEncryptedColumn converts a plaintext value to a string, and returns the EncryptedColumn struct for inserting into a database.
func ToEncryptedColumn(value any, table string, column string, queryType ...string) (EncryptedColumn, error) {
	str, err := convertToString(value)
	if err != nil {
		return EncryptedColumn{}, fmt.Errorf("error: %v", err)
	}
	data := EncryptedColumn{K: "pt", P: str, I: TableColumn{T: table, C: column}, V: 1}
	if queryType != nil {
		data.Q = queryType[0]
	}
	return data, nil
}

func convertToString(value any) (string, error) {
	switch v := value.(type) {
	case string:
		return v, nil
	case int:
		return fmt.Sprintf("%d", v), nil
	case float64:
		return fmt.Sprintf("%f", v), nil
	case map[string]any:
		jsonData, err := json.Marshal(v)
		if err != nil {
			return "", fmt.Errorf("error marshaling JSON: %v", err)
		}
		return string(jsonData), nil
	case bool:
		return strconv.FormatBool(v), nil
	default:
		return "", fmt.Errorf("unsupported type: %T", v)
	}
}
