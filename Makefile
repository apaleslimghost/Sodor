SHELL := /bin/bash
PATH  := $(shell npm bin):$(PATH)
TRACEUR_OPTS = --experimental --modules=commonjs
TEST_SRC = $(wildcard test-src/*)
TEST_FILES := $(patsubst test-src/%,test-lib/%,$(TEST_SRC))
TEST_FILES := $(patsubst test-lib/%.ls,test-lib/%.js,$(TEST_FILES))
JS_SRC   = $(wildcard src/*.js)
JS_FILES = $(patsubst src/%,lib/%,$(JS_SRC))

lib/%.js: src/%.js
	traceur $(TRACEUR_OPTS) --out $@ $<
	echo 'require("traceur/bin/traceur-runtime");' | cat - $@ > /tmp/out && mv /tmp/out $@

test-lib/%.js: test-src/%.js
	traceur $(TRACEUR_OPTS) --out $@ $<
	echo 'require("traceur/bin/traceur-runtime");' | cat - $@ > /tmp/out && mv /tmp/out $@

test-lib/%.js: test-src/%.ls
	lsc -o test-lib -c $<

all: $(JS_FILES)

test: all $(TEST_FILES)
	mocha -u exports $(TEST_FILES)

docs/%.md: src/%.js
	sug convert -o docs $<

docs: docs/index.md

.PHONY: test
