SHELL := /bin/bash
PATH  := $(shell npm bin):$(PATH)
LSC_OPTS = -b -k

lib/%.js: src/%.ls
	lsc $(LSC_OPTS) -c "$<"

all: lib/index.js

test: all test.ls
	mocha -r LiveScript -u exports test.ls

docs/%.md: src/%.ls
	sug convert -o docs $<

docs: docs/index.md

.PHONY: test
