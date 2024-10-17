package goeql

// This package contains helpers to use with Go/Xorm to serialize/deserialize values
// into the shape EQL and the CipherStash proxy needs to enable encryption/decryption.

// EQL expects a json format that looks like this:
// '{"k":"pt","p":"a string representation of the plaintext that is being encrypted","i":{"t":"table","c":"column"},"v":1}'

import (
	"encoding/json"
	"fmt"
	"strconv"
)

type TableColumn struct {
	T string `json:"t"`
	C string `json:"c"`
}

type EncryptedColumn struct {
	K string      `json:"k"`
	P string      `json:"p"`
	I TableColumn `json:"i"`
	V int         `json:"v"`
}

// Creating custom types for encrypted fields to enable creating methods for
// serialization/deserialization of these types.
type EncryptedText string
type EncryptedJsonb map[string]interface{}
type EncryptedInt int
type EncryptedBool bool

// Text
func (et EncryptedText) Serialize(table string, column string) ([]byte, error) {
	val, err := ToEncryptedColumn(string(et), table, column)
	if err != nil {
		return nil, fmt.Errorf("error serializing: %v", err)
	}
	return json.Marshal(val)
}

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

func EncryptedTextToDb(et EncryptedText, table string, column string) ([]byte, error) {
	return (&et).Serialize(table, column)
}

func EncryptedTextFromDb(et *EncryptedText, data []byte) (EncryptedText, error) {
	val, err := et.Deserialize(data)
	if err != nil {
		return "", err
	}

	return val, nil

}

// Jsonb
func (ej EncryptedJsonb) Serialize(table string, column string) ([]byte, error) {
	val, err := ToEncryptedColumn(map[string]any(ej), table, column)
	if err != nil {
		return nil, fmt.Errorf("error serializing: %v", err)
	}
	return json.Marshal(val)
}

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

// Int
func (et EncryptedInt) Serialize(table string, column string) ([]byte, error) {
	val, err := ToEncryptedColumn(int(et), table, column)
	if err != nil {
		return nil, fmt.Errorf("error serializing: %v", err)
	}
	return json.Marshal(val)
}

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

// Bool
func (eb EncryptedBool) Serialize(table string, column string) ([]byte, error) {
	val, err := ToEncryptedColumn(bool(eb), table, column)
	if err != nil {
		return nil, fmt.Errorf("error serializing: %v", err)
	}
	return json.Marshal(val)
}

func (et *EncryptedBool) Deserialize(data []byte) (EncryptedBool, error) {
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

// Serialize a query

func SerializeQuery(value any, table string, column string) ([]byte, error) {
	query, err := ToEncryptedColumn(value, table, column)
	if err != nil {
		return nil, fmt.Errorf("error converting to EncryptedColumn: %v", err)
	}
	serializedQuery, errMarshal := json.Marshal(query)

	if errMarshal != nil {
		return nil, fmt.Errorf("error marshalling EncryptedColumn: %v", errMarshal)
	}
	return serializedQuery, nil

}

// Converts a plaintext value to a string and returns the EncryptedColumn struct to use to insert into the db.
func ToEncryptedColumn(value any, table string, column string) (EncryptedColumn, error) {
	str, err := convertToString(value)
	if err != nil {
		return EncryptedColumn{}, fmt.Errorf("error: %v", err)
	}

	data := EncryptedColumn{K: "pt", P: str, I: TableColumn{T: table, C: column}, V: 1}

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
