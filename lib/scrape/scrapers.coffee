# 
# Function that returns a hash of scrapers based off the scraper files we've written.
# 

fs = require 'fs'
{ basename } = require 'path'

scrapers = {}
for f in fs.readdirSync('./lib/scrape/scrapers')
  s = require "./scrapers/#{f}"
  scrapers[basename f, '.coffee'] = s if s.scrapePages?

module.exports = scrapers