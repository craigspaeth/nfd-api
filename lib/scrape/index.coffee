# 
# Creates a bunch of scrapers and is the CLI to run them.
# 

dal = require '../../dal'
Scraper = require './scraper'
accounting = require 'accounting'
_ = require 'underscore'
_.mixin require 'underscore.string'
{ SCRAPE_PER_MINUTE } = require '../../config'

TOTAL_LISTINGS = 5000

scrapers =
  
  streeteasy: new Scraper
    startPage: 1
    requestsPerMinute: SCRAPE_PER_MINUTE
    listingsPerPage: 10
    weight: 1
    listUrl: (page) -> 
      "http://streeteasy.com/nyc/rentals/nyc/rental_type:frbo,brokernofee?" + 
      "page=#{page}&sort_by=listed_desc"
    listItemSelector: '.unsponsored .item.listing .body h3 a'
    $ToListing: ($) ->
      return $('html').html() unless $('html').html().length > 30
      rent: accounting.unformat $('h1 .price').text()
      beds: parseFloat($('.data').text().match(/[\.\d]* bed/)) or null
      baths: parseFloat($('.data').text().match(/[\.\d]* bath/)) or null
      location: 
        name: $('h1 span').text()
      pictures: $('.photo.medium > a').map(-> $(@).attr 'href').toArray()
      
  urbanedge: new Scraper
    startPage: 0
    requestsPerMinute: SCRAPE_PER_MINUTE
    listingsPerPage: 10
    weight: 1
    listUrl: (page) ->
      "http://www.urbanedgeny.com/results?page=#{page}&nh1=90&p[min]=&p[max]=&bd=&ba="
    listItemSelector: '.property-title a'
    $ToListing: ($) ->
      return $('html').html() unless $('html').html().length > 30
      rent: accounting.unformat $('#listing-overview > div:first-child').text()
      beds: parseFloat($('#listing-overview').text().match(/[\.\d]* bed/i)) or null
      baths: parseFloat($('#listing-overview').text().match(/[\.\d]* bath/i)) or null
      location: 
        name: _.clean($('.address-block').text())
      pictures: $('#slide-runner a').map(->
        "http://www.urbanedgeny.com" + $(@).attr 'href').toArray()
      
  apartable: new Scraper
    startPage: 1
    requestsPerMinute: SCRAPE_PER_MINUTE
    listingsPerPage: 28
    weight: 1
    listUrl: (page) ->
      "http://apartable.com/apartments?broker_fee=false&city=New+York" + 
      "&page=#{page}&state=New+York&utf8=%E2%9C%93"
    listItemSelector: 'a.map-link'
    $ToListing: ($) ->
      return $('html').html() unless $('html').html().length > 30
      rent: accounting.unformat $('.price').text()
      beds: parseFloat($('.bedrooms').text().match(/[\.\d]* bed/i)) or null
      baths: parseFloat($('.bathrooms').text().match(/[\.\d]* bath/i)) or null
      location: 
        name: $('#map-container h3').text()
      pictures: $('#galleria a').map(-> $(@).attr 'href').toArray()

  nybits: new Scraper
    startPage: 0
    requestsPerMinute: SCRAPE_PER_MINUTE
    listingsPerPage: 200
    weight: 0.25
    useProxy: true
    listUrl: (page) ->
      "http://www.nybits.com/search/?_a%21process=" + 
      "y&_rid_=3&_ust_todo_=65733&_xid_=" +
      "aaLx8ms445ZfSq-1377828951&%21%21rmin=&%21%21rmax=&%21%21fee=nofee&%21%21orderby=" + 
      "dateposted&submit=+SHOW+RENTAL+APARTMENTS+&!!_magic%3APrefix!_search_start%3D#{page * 200}="
    listItemSelector: '[colspan="3"] a'
    $ToListing: ($) ->
      return $('html').html() unless $('html').html().length > 30
      rent = $("#capsuletable tr").filter( -> 
             $(@).find("td:eq(0)").text().match /Rent/).find("td:eq(1)").text()
      layout = $("#capsuletable tr").filter( -> 
               $(@).find("td:eq(0)").text().match /Layout/).find("td:eq(1)").text()
      building = $("#capsuletable tr").filter( -> 
                 $(@).find("td:eq(0)").text().match /Building/).find("td:eq(1)").text()
      {
        rent: accounting.unformat(rent)
        beds: parseFloat(if layout.match /studio/i then 1 else layout) or null
        baths: null
        location:
          name: _.clean(building)
        pictures: $('.photocolumntitle').nextAll('img').map(-> $(@).attr 'src').toArray()
      }

  trulia: new Scraper
    startPage: 1
    requestsPerMinute: SCRAPE_PER_MINUTE
    listingsPerPage: 15
    weight: 0.25
    useProxy: true
    listUrl: (page) -> "http://trulia.com/for_rent/New_York,NY/0_bf/#{page}_p"
    listItemSelector: 'a.primaryLink'
    $ToListing: ($) ->
      return $('html').html() unless $('html').html().length > 30
      rent: accounting.unformat $('[itemprop="price"]').html()
      beds: parseFloat($('.listBulleted').html().match(/[\.\d]* bed/i))
      baths: parseFloat($('.listBulleted').html().match(/[\.\d]* bath/i))
      location:
        name: $('[itemprop="address"]').html()
      pictures: _.pluck($('.photoPlayer').data('photos')?.photos, 'standard_url') or
                [$('.photoPlayerCurrentItem img').attr('src')]

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
    perScraperLimit = TOTAL_LISTINGS / _.keys(scrapers).length
    for name, scraper of scrapers
      scraper.scrapePages(
        scraper.startPage
        Math.round (perScraperLimit / scraper.listingsPerPage) * scraper.weight
        -> 
          console.log "DONE!"
          process.exit()
      )
  
  # Scrape ALL THE LISTINGS with  with `coffee lib/scrape listings`
  else if process.argv[2] is 'listings'
    for name, scraper of scrapers
      callback = _.after scrapers.length, ->
        console.log "DONE!"
        process.exit()
      scraper.populateEmptyListings 1000000, callback