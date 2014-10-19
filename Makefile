SHELL := /bin/bash
PATH  := $(shell npm bin):$(PATH)
TRACEUR_OPTS = --experimental --modules commonjs

lib/%.js: src/%.js
	traceur $(TRACEUR_OPTS) --out $@ $<

all: lib/index.js

test: all test.ls
	mocha -r LiveScript -u exports test.ls

docs/%.md: src/%.ls
	sug convert -o docs $<

docs: docs/index.md

.PHONY: test
