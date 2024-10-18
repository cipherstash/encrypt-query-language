
## Minimal Plaintext

```
{
  "v": 1,
  "s": {
    "k": "pt",
    "p": "plaintext string",
    "e": {
      "t": "users",
      "c": "name_encrypted"
    }
  }
}
```


INSERT INTO users (name_encrypted) VALUES ('
{
  "v": 1,
  "s": {
	"k": "ct",
  	"c": "ciphertext",
	"e": {
		"t": "table",
		"c": "column"
	},
	"m": [42],
	"u": "unique",
	"o": ["a","b","c"]
  },
  "t": {
	"k": "pt",
    "p": "plaintext",
	"e": {
		"t": "table",
		"c": "column"
	},
	"m": [42],
	"u": "unique"
  }
}'::cs_encrypted_v1);




## Minimal Ciphertext

```
{
  "v": 1,
  "s": {
    "k": "ct",
    "c": "XvfWQUrSxKNhkOxiMXvgvkwxIYFfnYTb",
    "e": {
      "t": "users",
      "c": "name_encrypted"
    }
  }
}
```


## Embedded

```
{
  "v": 1,
  "s": {
    "k": "ct",
    "c": "XvfWQUrSxKNhkOxiMXvgvkwxIYFfnYTb",
    "e": {
      "t": "users",
      "c": "name_encrypted"
    }
  }
  "t": {
    "k": "pt",
    "p": "plaintext string",
    "e": {
      "t": "users",
      "c": "name"
    }
  }
}
```