all: test

test: gotest goerrcheck gostaticcheck

gotest:
	go test ./... -v -timeout=45s -failfast

goerrcheck:
	errcheck -exclude .errcheck-excludes -ignoretests ./...

gostaticcheck:
	staticcheck ./...
