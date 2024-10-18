all: test

test: gotest goerrcheck gostaticcheck

cidep:
	go install honnef.co/go/tools/cmd/staticcheck@latest
	go install github.com/kisielk/errcheck@latest

gotest:
	go test ./... -v -timeout=45s -failfast

goerrcheck:
	errcheck -exclude .errcheck-excludes -ignoretests ./...

gostaticcheck:
	staticcheck ./...
