SHELL := /bin/bash
PATH  := $(shell npm bin):$(PATH)
TRACEUR_OPTS = --experimental --modules commonjs

lib/%.js: src/%.js
	traceur $(TRACEUR_OPTS) --out $@ $<
	echo 'require("traceur/bin/traceur-runtime");' | cat - $@ > /tmp/out && mv /tmp/out $@

all: lib/index.js

test: all test.ls
	echo -e '//#sourceMappingURL=./index.map\nrequire("source-map-support").install();' | cat - lib/index.js > /tmp/out && mv /tmp/out lib/index.js
	mocha -r LiveScript -u exports test.ls

docs/%.md: src/%.ls
	sug convert -o docs $<

docs: docs/index.md

.PHONY: test
