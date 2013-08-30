# 
# Creates a bunch of scrapers and is the CLI to run them.
# 

dal = require '../../dal'
Scraper = require './scraper'
accounting = require 'accounting'
_ = require 'underscore'
_.mixin require 'underscore.string'

TOTAL_LISTINGS_LIMIT = 2500

scrapers =
  
  streeteasy: new Scraper
    listUrl: "http://streeteasy.com/nyc/rentals/nyc/rental_type:frbo,brokernofee?" + 
             "page={page}&sort_by=listed_desc"
    listItemSelector: '.unsponsored .item.listing .body h3 a'
    startPage: 1
    requestsPerMinute: 15
    listingsPerPage: 10
    $ToListing: ($) ->
      return $('html').html() unless $('html').html().length > 30
      rent: accounting.unformat $('h1 .price').text()
      beds: parseFloat $('.data').text().match(/[\.\d]* bed/)
      baths: parseFloat $('.data').text().match(/[\.\d]* bath/)
      location: 
        name: $('h1 span').text()
      pictures: $('.photo.medium > a').map((i, el) -> $(el).attr 'href').toArray()
      
  urbanedge: new Scraper
    listUrl: "http://www.urbanedgeny.com/results?page={page}&nh1=90&p[min]=&p[max]=&bd=&ba="
    listItemSelector: '.property-title a'
    startPage: 0
    requestsPerMinute: 15
    listingsPerPage: 10
    $ToListing: ($) ->
      return $('html').html() unless $('html').html().length > 30
      rent: accounting.unformat $('#listing-overview > div:first-child').text()
      beds: parseFloat $('#listing-overview').text().match(/[\.\d]* bed/i)
      baths: parseFloat $('#listing-overview').text().match(/[\.\d]* bath/i)
      location: 
        name: _.clean($('.address-block').text())
      pictures: $('#slide-runner a').map((i, el) ->
        "http://www.urbanedgeny.com" + $(el).attr 'href').toArray()

# Scrape all the pages of listings and populate all of the empty listings.
scrapeAll = ->
  perScraperLimit = TOTAL_LISTINGS_LIMIT / _.keys(scrapers).length
  for name, scraper of scrapers
    scraper.scrapePages(
      scraper.startPage
      Math.round(perScraperLimit / scraper.listingsPerPage) - 1
    )

return unless module is require.main
dal.connect =>
  scraper = scrapers[process.argv[2]]
  
  # Scrape pages of listings
  if process.argv[4]
    scraper.scrapePages parseInt(process.argv[3]), parseInt(process.argv[4]), -> process.exit()
  
  # Scrape listings themself
  else
    scraper.populateEmptyListings -> process.exit()