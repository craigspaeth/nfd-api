BIN = node_modules/.bin

s:
	$(BIN)/coffee index.coffee

scrape:
	$(BIN)/coffee lib/scrapers/streeteasy.coffee $(start) $(end)
	$(BIN)/coffee lib/gecode_listings.coffee
	# $(BIN)/coffee lib/remove_bad_listings.coffee

test:
	$(BIN)/mocha $(shell find test -name '*.coffee' -not -path 'test/helpers/*' -not -path 'test/scrapers/*')

.PHONY: test
