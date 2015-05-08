SHELL := /bin/bash
PATH  := $(shell npm bin):$(PATH)

TEST_FILES = $(wildcard test/*)
JS_SRC     = $(wildcard src/*.js)
JS_FILES   = $(patsubst src/%,lib/%,$(JS_SRC))

BABEL_OPTS = --optional runtime

all: $(JS_FILES)

lib/%.js: src/%.js
	@mkdir -p $(@D)
	babel $(BABEL_OPTS) -o $@ $<

test: all $(TEST_FILES)
	mocha -r babel/register $(TEST_FILES)

.PHONY: test
