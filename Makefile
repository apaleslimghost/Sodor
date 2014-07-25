LSC_OPTS = -b -k

%.js: %.ls
	node_modules/.bin/lsc $(LSC_OPTS) -c "$<"

all: index.js

test: all test.ls
	node_modules/.bin/mocha -r LiveScript -u exports test.ls

docs/%.md: %.ls
	node_modules/.bin/sug convert -o docs $<

docs: docs/index.md

.PHONY: test
