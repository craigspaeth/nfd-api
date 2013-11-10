# 
# Creates a bunch of scrapers and is the CLI to run them.
# 
# For websites that don't follow the conventional list view with detail pages you can
# still be a "scraper" by providing the `scrapePages(start, end, callback)` and
# `populateEmptyListings(limit, callback) APIs.
# 

dal = require '../../dal'
_ = require 'underscore'

scrapers =
  streeteasy: require './scrapers/streeteasy'
  urbanedge: require './scrapers/urbanedge'
  apartable: require './scrapers/apartable'
  trulia: require './scrapers/trulia'
  renthop: require './scrapers/renthop'
  nybits: require './scrapers/nybits'
  '9300realty': require './scrapers/9300realty'
  iconrealtymgmt: require './scrapers/iconrealtymgmt'
  sspny: require './scrapers/sspny'
  gonofee: require './scrapers/gonofee'

return unless module is require.main
dal.connect =>
  scraper = scrapers[process.argv[2]]
  
  # Scrape pages of listings with `coffee lib/scrape streeteasy 0 1`
  if process.argv[4]
    scraper.scrapePages parseInt(process.argv[3]), parseInt(process.argv[4]), -> process.exit()
  
  # Scrape listings themself with `coffee lib/scrape streeteasy 10`
  else if process.argv[3]
    scraper.populateEmptyListings parseInt(process.argv[3]), -> process.exit()
  
  # Scrape ALL THE PAGES with  with `coffee lib/scrape pages`
  else if process.argv[2] is 'pages'
    callback = _.after _.keys(scrapers).length, -> 
      console.log "DONE SCRAPING PAGES FOR ALL SOURCES!"
      process.exit()
    for name, scraper of scrapers
      scraper.scrapePages(
        scraper.startPage
        1000 / scraper.listingsPerPage
        callback
      )
  
  # Scrape ALL THE LISTINGS with  with `coffee lib/scrape listings`
  else if process.argv[2] is 'listings'
    callback = _.after _.keys(scrapers).length, ->
      console.log "DONE!"
      process.exit()
    for name, scraper of scrapers
      scraper.populateEmptyListings 1000, callback