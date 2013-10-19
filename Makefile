BIN = node_modules/.bin

s:
	$(BIN)/coffee index.coffee

scrape-pages:
	until $(BIN)/coffee lib/scrape pages; do  echo "Crashed with $?">&2; sleep 1; done

scrape-listings:
	until $(BIN)/coffee lib/scrape listings; do  echo "Crashed with $?">&2; sleep 1; done

scrape:
	make scrape-pages
	make scrape-listings
	make geocode

geocode:
	$(BIN)/coffee lib/gecode-listings.coffee

test:
	$(BIN)/mocha $(shell find test -name '*.coffee' -not -path 'test/helpers/*' -not -path 'test/scrapers/*')

.PHONY: test
