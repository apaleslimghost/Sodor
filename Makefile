LSC_OPTS = -k

%.js: %.ls
	node_modules/.bin/lsc $(LSC_OPTS) -c "$<"

all: index.js

test: all
	node_modules/.bin/mocha -r LiveScript -u exports test.ls

.PHONY: test
