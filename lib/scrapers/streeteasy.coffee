# 
# Iterates through listings on street easy and stores the listings
# as our own data model.
#

jQuery = require 'jquery'
@dal = require '../../dal'
_ = require 'underscore'
Browser = require 'zombie'

# Scrapes a page of listing urls and saves the empty listings to mongo.
# 
# @param {Number} page
# @param {Function} callback Callsback with (err)

@scrapePage = (page, callback) =>
  listings = []
  fetchListingUrls page, (err, urls) =>
    return callback('fail') if err
    listings = ({ url: url } for url in urls)
    @dal.listings.upsert listings, callback
    
# Goes through listings without `dateScraped` and populates them by scraping
# their urls.
# 
# @param {Function} callback Callsback with (err)

populateEmptyListings = (callback = ->) =>
  @dal.listings.collection.find({ dateScraped: null }).toArray (err, listings) =>
    if listings.length is 0
      console.log "All listings scraped!"
      callback()
      return
    console.log "Scraping #{listings.length} listings..."
    callback = _.after listings.length, callback
    for { url } in listings
      fetchListing url, (err, listing) =>
        return if err
        listing.dateScraped = new Date
        @dal.listings.upsert(listing)
        callback()

# Fetches a page of listing urls.
# 
# @param {Number} page The page number to scrape
# @param {Function} callback Callsback with (err, urls)

fetchListingUrls = (page, callback) ->
  console.log "Fetching page #{page} from StreetEasy..."
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
    console.log "Saved listing from #{url}."
    callback null, parseDirty
      location: $('h1 span').text()
      rent: $('h1 .price').text()
      beds: $('.data p:last-child').text()
      baths: $('.data p:last-child').text()
      url: url
      pictures: $('.photo.medium > a').map((i, el) -> $(el).attr 'href').toArray()
    
# Parses dirty strings such as "\n    $3,500" into forms of data that 
# we actually want such as 3500.
# 
# @param {Object} data Hash of dirty strings
# @return Cleaned up listing data

parseDirty = (data) =>
  {
    rent: if data.rent then parseInt(data.rent.match(/\$.*/)[0].replace /\$|\,/g, '') else null
    beds: parseFloat if data.beds?.match /studio/ then 1 else data.beds.match(/[\.\d]* bed/)
    baths: parseFloat data.baths?.match(/[\.\d]* bath/)
    location:
      name: data.location
    url: data.url
    pictures: data.pictures
  }

# Scrape first argument number of pages if the module has been run directly
return unless module is require.main
@dal.connect =>
  return populateEmptyListings() unless process.argv[2]
  start = process.argv[2] or 1
  end = process.argv[3] or 3
  total = end - start + 1
  console.log "Scraping #{total} pages..."
  callback = _.after total, ->
    console.log "Finished scraping!"
    process.exit()
  i = start
  scrape = =>
    @scrapePage i, ->
      scrape()
      callback()
    i++
  scrape()