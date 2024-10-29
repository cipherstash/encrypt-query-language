all: test

test: gotest goerrcheck gostaticcheck

gotest:
	go test ./... -v -timeout=45s -failfast

goerrcheck:
	errcheck -exclude .errcheck-excludes -ignoretests ./...

gostaticcheck:
	staticcheck ./...

fetch_eql:
	curl -sLo cipherstash-eql-install.sql https://github.com/cipherstash/encrypt-query-language/releases/latest/download/cipherstash-encrypt.sql
