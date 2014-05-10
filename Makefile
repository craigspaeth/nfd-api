BIN = node_modules/.bin

s:
	$(BIN)/coffee index.coffee

# Scraping

scrape-pages:
	until $(BIN)/coffee lib/scrape pages; do  echo "Crashed with $?">&2; sleep 1; done

scrape-listings:
	until $(BIN)/coffee lib/scrape listings; do  echo "Crashed with $?">&2; sleep 1; done

geocode:
	$(BIN)/coffee lib/gecode-listings.coffee

drop-old:
	$(BIN)/coffee lib/drop-old.coffee

scrape: scrape-pages scrape-listings drop-old geocode

# Emails

send-alerts:
	$(BIN)/coffee lib/send-alerts.coffee

# Development

dbcopy:
	mongodump --host paulo.mongohq.com:10085 --db app17949403 -u heroku -p dj6TGZX-pcpitvzXzgzC -c listings
	mongorestore dump/app17949403/listings.bson -c listings -d nfd --drop
	rm -rf dump/

test:
	$(BIN)/mocha $(shell find test -name '*.coffee' -not -path 'test/helpers/*' -not -path 'test/scrapers/*')

# Deployment

commit:
	git add .
	git commit -a -m 'deploying...'
	git push git@github.com:craigspaeth/nfd-api.git master

deploy: commit
	git push git@heroku.com:nfd-api.git master

.PHONY: test