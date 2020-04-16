GOBIN=$(shell which go)
BUILD_CMD = ${GOBIN} install
BINDIR = ./bin
GOBINDIR = `readlink -f ./bin`
PROFILE = -tags profile
ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
LDFLAGS=-all-static
GO_FLAGS=--ldflags '-extldflags "-static"'


all: sybil demo

demo:
	GOBIN=$(GOBINDIR) $(BUILD_CMD) $(GO_FLAGS) $(BUILD_FLAGS) ./src/api/demo

deps:
	${GOBIN} get -d -v -t ./...

sybil: bindir
	GOBIN=$(GOBINDIR) $(BUILD_CMD) $(GO_FLAGS) $(BUILD_FLAGS) ./

fake-data: fake-uptime

fake-people:
	python scripts/fakedata/people_generator.py 50000 | ./bin/sybil ingest -table people
	./bin/sybil digest -table people

fake-uptime:
	python scripts/fakedata/host_generator.py 1000000 | ./bin/sybil ingest -table uptime
	./bin/sybil digest -table uptime

testquery:
	${BINDIR}/sybil query -table people -int age,f1 -op hist -group state

bindir:
	mkdir ${BINDIR} 2>/dev/null || true

test:
	${GOBIN} test ./src/lib/ -race -v
	${GOBIN} test ./src/api/ -race -v

testv:
	${GOBIN} test ./src/lib/ -race -v -debug
	${GOBIN} test ./src/api/ -race -v -debug

update-golden:
	${GOBIN} test ./src/lib --update-golden

coverage:
	${GOBIN} test -covermode atomic -coverprofile cover.out ./src/lib
	sed -i "s|_${ROOT_DIR}|.|"	cover.out
	${GOBIN} tool cover -html=cover.out -o cover.html

benchmarks:
	${GOBIN} test -run=NONE -benchmem -bench=. ./src/lib |tee bench.txt

tdigest: export BUILD_FLAGS += -tags tdigest
tdigest: bindir
	make all

nodeltaencoding: export BUILD_FLAGS += -tags denc
nodeltaencoding: bindir
	make all

profile: export BUILD_FLAGS += -tags profile
profile: bindir
	make all

tags:
	ctags --languages=+Go src/lib/*.go
	starscope -e cscope
	starscope -e ctags

default: all

clean:
	rm ./bin/*

.PHONY: tags
.PHONY: query
.PHONY: ingest
.PHONY: clean

