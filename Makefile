 
#!/usr/bin/make -f

all: test clean install lint

# The below include contains the tools and runsim targets.
include contrib/devtools/Makefile

build:
	go build ./cmd/fbd
	go build ./cmd/fbcli
	go build ./cmd/fbrelayer

clean:
	rm -f fbd
	rm -f fbcli
	rm -f fbrelayer

install:
	go install ./cmd/fbd
	go install ./cmd/fbcli
	go install ./cmd/fbrelayer

lint:
	@echo "--> Running linter"
	golangci-lint run
	@find . -name '*.go' -type f -not -path "./vendor*" -not -path "*.git*" | xargs gofmt -d -s
	go mod verify

test:
	go test ./...

.PHONY: all build clean install test lint all