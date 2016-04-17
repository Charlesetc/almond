
FILES = ./std/* ./hazelnut.hzl ./read.hzl

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

test: build-test
	./build/hazelnut --run-tests true

build-test:
	hazelnut build $(FILES) ./tests/* --build=hazelnut

run-test: build-test
	./build/hazelnut --run-tests true --only-test "$(name)"
