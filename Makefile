BIN = node_modules/.bin

s:
	$(BIN)/coffee index.coffee
	
scrape:
	$(BIN)/coffee lib/scrapers/streeteasy.coffee