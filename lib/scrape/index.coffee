# 
# Creates a bunch of scrapers and is the CLI to run them.
# 
# For websites that don't follow the conventional list view with detail pages you can
# still be a "scraper" by providing the `scrapePages(start, end, callback)` and
# `populateEmptyListings(limit, callback) APIs.
# 

dal = require '../../dal'
_ = require 'underscore'
fs = require 'fs'
{ basename } = require 'path'

scrapers = {}
for f in fs.readdirSync('./lib/scrape/scrapers')
  s = require "./scrapers/#{f}"
  scrapers[basename f, '.coffee'] = s if s.scrapePages?

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
    console.log 'mooo'
    callback = _.after _.keys(scrapers).length, -> 
      console.log "DONE SCRAPING PAGES FOR ALL SOURCES!"
      process.exit()
    for name, scraper of scrapers
      console.log name
      scraper.scrapePages(0, 20, callback)
  
  # Scrape ALL THE LISTINGS with  with `coffee lib/scrape listings`
  else if process.argv[2] is 'listings'
    callback = _.after _.keys(scrapers).length, ->
      console.log "DONE!"
      process.exit()
    for name, scraper of scrapers
      scraper.populateEmptyListings 1000, callback