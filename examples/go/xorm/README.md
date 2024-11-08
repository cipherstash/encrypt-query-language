# EQL Go/Xorm example

## Prerequisites

- Go
- Docker
- Docker compose
- CipherStash account
- CipherStash CLI

## Running / Development

Create an [account](https://cipherstash.com/signup).

Install the CLI:

```shell
brew install cipherstash/tap/stash
```

Login:

```shell
stash login
```

Create a [dataset](https://cipherstash.com/docs/how-to/creating-datasets) and [client](https://cipherstash.com/docs/how-to/creating-clients), and record them as `CS_CLIENT_ID` and `CS_CLIENT_KEY`.

```shell
stash datasets create xorm
# grab dataset ID and export CS_DATASET_ID=

stash clients create xorm --dataset-id $CS_DATASET_ID
# grab the client ID and export CS_CLIENT_ID=
# grab the client key and export CS_CLIENT_KEY=
```

Upload the `dataset.yml` file in this directory.

```shell
stash datasets config upload --file dataset.yml --client-id $CS_CLIENT_ID --client-key $CS_CLIENT_KEY --assume-yes
```

Create an [access key](https://cipherstash.com/docs/how-to/creating-access-keys) for CipherStash Proxy:

```shell
stash workspaces
# grab the workspace ID and export CS_WORKSPACE_ID=
stash access-keys create --workspace-id $CS_WORKSPACE_ID xorm
# grab the client access key and export CS_CLIENT_ACCESS_KEY=
```

Copy over the example `.envrc` file:

```shell
cp .envrc.example .envrc
```

Update the `.envrc` file with these environment variables `CS_WORKSPACE_ID`, `CS_CLIENT_ACCESS_KEY`, `CS_CLIENT_ID` and `CS_CLIENT_KEY`:

```shell
source .envrc
```

Start Postgres and CipherStash Proxy and install EQL:

```shell
./run.sh setup
```

Run tests:

```shell
./run.sh tests
```

## Integrating EQL into a Xorm app

Before starting to integrate, follow the EQL installation steps in the main [README file](../../../README.md).

The [goeql package](https://github.com/cipherstash/encrypt-query-language/blob/main/languages/go/goeql/goeql.go) contains functions to help with serializing data into the format that CipherStash Proxy expects and deserializing data from this format back to the original value.

For reference there is an example setup in the [main.go](./main.go) file.

Example migrations are in the [migrations.go](./migrations.go) file.

Start with adding a new encrypted field:

1. Add a custom type for the field.

For example a text field:

```go
type EncryptedTextField string
```

jsonb field:

```go
type EncryptedJsonbField map[string]interface{}
```

2. Add the field/s to the relevant struct:

```go
type Example struct {
	Id                  int64               `xorm:"pk autoincr"`
	EncryptedTextField  EncryptedTextField  `json:"encrypted_text_field" xorm:"jsonb 'encrypted_text_field'"`
	EncryptedJsonbField EncryptedJsonbField `json:"encrypted_jsonb_field" xorm:"jsonb 'encrypted_jsonb_field'"`
}
```

3. Use the conversion interface to define a custom mapping rule for each field.

Within each function use the goeql Serialize and Deserialize functions.

When serializing the table name and column name need to be passed as arguments.

Example for a text field:

```go
func (et EncryptedTextField) ToDB() ([]byte, error) {
	etCs := goeql.EncryptedText(et)
    // e.g table name is "examples" and field is "encrypted_text_field"
	return (&etCs).Serialize("examples", "encrypted_text_field")
}

func (et *EncryptedTextField) FromDB(data []byte) error {
	etCs := goeql.EncryptedText(*et)

	val, err := (&etCs).Deserialize(data)
	if err != nil {
		return err
	}

	*et = EncryptedTextField(val)

	return nil
}
```

Example for a jsonb field:

```go
func (ej EncryptedJsonbField) ToDB() ([]byte, error) {
	ejCs := goeql.EncryptedJsonb(ej)
    // e.g table name is "examples" and field is "encrypted_jsonb_field"
	return (&ejCs).Serialize("examples", "encrypted_jsonb_field")
}

func (ej *EncryptedJsonbField) FromDB(data []byte) error {
	etCs := goeql.EncryptedJsonb(*ej)

	val, err := (&etCs).Deserialize(data)
	if err != nil {
		return err
	}

	*ej = EncryptedJsonbField(val)

	return nil
}
```

4. Add a migration to add custom constraint checks for each field.

These checks will validate that the json payload is correct and that encrypted data is being inserted correctly.

Example:

```sql
	ALTER TABLE examples ADD CONSTRAINT encrypted_text_field_encrypted_check
	CHECK ( cs_check_encrypted_v1(encrypted_text_field) );

	ALTER TABLE examples ADD CONSTRAINT encrypted_jsonb_encrypted_check
	CHECK ( cs_check_encrypted_v1(encrypted_jsonb_field) );
```

5. [Add indexes](../../../README.md#managing-indexes-with-eql):

Example:

```sql
    SELECT cs_add_index_v1('examples', 'encrypted_text_field', 'unique', 'text', '{"token_filters": [{"kind": "downcase"}]}');
    SELECT cs_add_index_v1('examples', 'encrypted_text_field', 'match', 'text');
    SELECT cs_add_index_v1('examples', 'encrypted_text_field', 'ore', 'text');
    SELECT cs_add_index_v1('examples', 'encrypted_jsonb_field', 'ste_vec', 'jsonb', '{"prefix": "examples/encrypted_jsonb_field"}');

    --   The below indexes will also need to be added to enable full search functionality on the encrypted columns

    CREATE UNIQUE INDEX ON examples(cs_unique_v1(encrypted_text_field));
    CREATE INDEX ON examples USING GIN (cs_match_v1(encrypted_text_field));
    CREATE INDEX ON examples (cs_ore_64_8_v1(encrypted_text_field));
    CREATE INDEX ON examples USING GIN (cs_ste_vec_v1(encrypted_jsonb_field));

    --   Run these functions to activate

    SELECT cs_encrypt_v1();
    SELECT cs_activate_v1();
```

## Inserting

Inserting data remains the same.

The `toDB()` function that was setup in [this earlier step](README.md#integrating-eql-into-a-xorm-app), serializes the plaintext value into the json payload CipherStash Proxy expects.

Retrieving data remains the same as well.

The `fromDb()` function for the relevant encrypted field will deserialize the json payload returned from CipherStash Proxy and return the plaintext value

## Querying

The queries to retrieve data do change.

EQL provides specialized functions to interact with encrypted data.

You can read about these functions [here](../../../README.md#querying-data-with-eql).

Similar to how CipherStash Proxy require's a specific json payload when inserting data, a similar payload is required when querying.

Goeql has functions that will serialize a value into the format required by CipherStash Proxy.

[These functions](https://github.com/cipherstash/encrypt-query-language/blob/main/languages/go/goeql/goeql.go#L153-L171) will need to be used for the relevant query.

Examples of how to use these are in the [e2e_test.go](./e2e_test.go) file.

Below is an example of running a match query on a text field.

```go
    query, errTwo := goeql.MatchQuery("some", "examples", "encrypted_text_field")
	if errTwo != nil {
		log.Fatalf("Error marshaling encrypted_text_field: %v", errTwo)
	}

	has, errThree := engine.Where("cs_match_v1(encrypted_text_field) @> cs_match_v1(?)", query).Get(&ExampleTwo)
	if errThree != nil {
		log.Fatalf("Could not retrieve exampleTwo: %v", errThree)
	}
```
