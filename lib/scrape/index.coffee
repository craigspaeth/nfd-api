# 
# Creates a bunch of scrapers and is the CLI to run them.
# 

dal = require '../../dal'
Scraper = require './scraper'
accounting = require 'accounting'
_ = require 'underscore'

scrapers =
  
  streeteasy: new Scraper
    listUrl: "http://streeteasy.com/nyc/rentals/nyc/rental_type:frbo,brokernofee?" + 
             "page={page}&sort_by=listed_desc"
    listItemSelector: '.unsponsored .item.listing .body h3 a'
    requestsPerMinute: 30
    $ToListing: ($) ->
      return $('html').html() unless $('html').html().length > 30
      rent: accounting.unformat $('h1 .price').text()
      beds: parseFloat $('.data').text().match(/[\.\d]* bed/)
      baths: parseFloat $('.data').text().match(/[\.\d]* bath/)
      location: 
        name: $('h1 span').text()
      pictures: $('.photo.medium > a').map((i, el) -> $(el).attr 'href').toArray()
  
  # trulia: new Scraper
  #   listUrl: "http://trulia.com/for_rent/New_York,NY/0_bf/{page}_p"
  #   listItemSelector: 'a.primaryLink'
  #   zombieOpts: { silent: true }
  #   populateLimit: 10
  #   $ToListing: ($) ->
  #     return $('html').html() unless $('html').html().length > 30
  #     rent: accounting.unformat $('[itemprop="price"]').html()
  #     beds: parseFloat($('.listBulleted').html().match(/[\.\d]* bed/i))
  #     baths: parseFloat($('.listBulleted').html().match(/[\.\d]* bath/i))
  #     location:
  #       name: $('[itemprop="address"]').html()
  #     pictures: _.pluck($('.photoPlayer').data('photos')?.photos, 'standard_url') or
  #               [$('.photoPlayerCurrentItem img').attr('src')]
                
return unless module is require.main
dal.connect =>
  scraper = scrapers[process.argv[2]]
  if process.argv[4]
    scraper.scrapePages parseInt(process.argv[3]), parseInt(process.argv[4]), -> process.exit()
  else if process.argv[2]
    scraper.populateEmptyListings -> process.exit()
  else
    callback = _.after(_.keys(scrapers).length, -> process.exit())
    scraper.populateEmptyListings(callback) for name, scraper of scrapers