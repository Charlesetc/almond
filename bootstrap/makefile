
FILES = ./std/* ./hazelnut.hzl

.PHONY: run show build tokens go

run:
	hazelnut run $(FILES)

show:
	hazelnut show $(FILES)

build:
	hazelnut build $(FILES) --build=hazelnut

tokens:
	hazelnut tokens $(FILES)

go:
	hazelnut $(FILES)

test: build-test run-test

build-test:
	hazelnut build $(FILES) ./tests/* --build=hazelnut

run-test:
	./build/hazelnut --run-tests true
