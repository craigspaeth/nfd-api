BIN = node_modules/.bin

s:
	$(BIN)/coffee index.coffee

test:
	$(BIN)/mocha $(shell find test -name '*.coffee' -not -path 'test/helpers/*' -not -path 'test/scrapers/*')

.PHONY: test
