# 
# Iterates through listings on street easy and stores the listings
# as our own data model.
#

jQuery = require 'jquery'
dal = require '../../dal'
_ = require 'underscore'
Browser = require 'zombie'

# Scrapes a page of listings and saves them to mongo
# 
# @param {Number} page
# @param {Function} callback Callsback with (err)

scrapePage = (page, callback) ->
  listings = []
  fetchListingUrls page, (err, urls) ->
    return callback('fail') if err
    console.log "Scraping #{urls.length} listings from page #{page}..."
    cb = _.after urls.length, ->
      console.log "Saved page #{page}!"
      dal.listings.upsert listings, callback
    for url in urls
      fetchListing url, (err, listing) ->
        listings.push(listing)
        cb() 

# Fetches a page of listing urls.
# 
# @param {Number} page The page number to scrape
# @param {Function} callback Callsback with (err, urls)

fetchListingUrls = (page, callback) ->
  console.log "Fetching page #{page}..."
  url = "http://streeteasy.com/nyc/rentals/nyc/rental_type:frbo,brokernofee?" + 
        "page=#{page}&sort_by=listed_desc"
  Browser.visit url, { silent:true }, (err, browser) ->
    $ = jQuery.create(browser.window)
    $listings = $('.unsponsored .item.listing .body h3 a')
    if $listings?.length is 0
      console.log "ERROR: Found no listings on page #{page}"
      callback {}
    else
      urls = $listings.map((i, el) -> "http://streeteasy.com" + $(el).attr('href')).toArray()
      callback null, urls

# Scrapes an individual listing and converts it to our data model.
# 
# @param {String} url The listing page's url
# @param {Function} Callsback with (err, listing)
 
fetchListing = (url, callback) ->
  console.log "Fetching listing from #{url}..."
  Browser.visit url, { silent:true }, (err, browser) ->
    $ = jQuery.create(browser.window)
    parseDirty {
      location: $('h1 span').text()
      rent: $('h1 .price').text()
      beds: $('.data p:last-child').text()
      baths: $('.data p:last-child').text()
      url: url
      pictures: $('.photo.medium > a').map((i, el) -> $(el).attr 'href').toArray()
    }, callback
    
# Parses dirty strings such as "\n    $3,500" into forms of data that 
# we actually want such as 3500.
# 
# @param {Object} data Hash of dirty strings
# @param {Function} Callsback with (err, listing)

parseDirty = (data, callback) =>
  callback null, {
    rent: if data.rent then parseInt(data.rent.match(/\$.*/)[0].replace /\$|\,/g, '') else null
    beds: parseFloat if data.beds?.match /studio/ then 1 else data.beds.match(/[\.\d]* bed/)
    baths: parseFloat data.baths?.match(/[\.\d]* bath/)
    location: {
      name: data.location
    }
    url: data.url
    pictures: data.pictures
  }

# Scrape first argument number of pages if the module has been run directly
return unless module is require.main
dal.connect ->
  start = process.argv[2]
  end = process.argv[3]
  total = end - start + 1
  console.log "Scraping #{total} pages..."
  callback = _.after total, ->
    console.log "Finished scraping!"
    process.exit()
  i = 0
  scrape = ->
    i++
    scrapePage(i, scrape)
    callback()
  scrape()