BIN = node_modules/.bin

s:
	$(BIN)/coffee index.coffee

scrape-pages:
	until $(BIN)/coffee lib/scrape pages; do  echo "Crashed with $?">&2; sleep 1; done

scrape-listings:
	until $(BIN)/coffee lib/scrape listings; do  echo "Crashed with $?">&2; sleep 1; done

scrape: scrape-pages scrape-listings geocode

dbcopy:
	mongodump --host paulo.mongohq.com:10085 --db app17949403 -u heroku -p dj6TGZX-pcpitvzXzgzC -c listings
	mongorestore dump/app17949403/listings.bson -c listings -d nfd --drop
	rm -rf dump/

geocode:
	$(BIN)/coffee lib/gecode-listings.coffee

drop-old:
	$(BIN)/coffee lib/drop-old.coffee

test:
	$(BIN)/mocha $(shell find test -name '*.coffee' -not -path 'test/helpers/*' -not -path 'test/scrapers/*')

.PHONY: test