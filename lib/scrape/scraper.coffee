# 
# A base library of common scraping actions like gathering the listing detail urls from
# a list view and saving the empty listings to be populated later.
# 

jQuery = require 'jquery'
Listings = require '../../dal/listings'
_ = require 'underscore'
Browser = require 'zombie'
urlLib = require 'url'

module.exports = class Scraper
  
  constructor: (attrs) ->
    { 
      @listUrl
      @listItemSelector
      @$ToListing
      @zombieOpts
    } = attrs
    @zombieOpts ?= { silent: true }
    @browser = new Browser @zombieOpts
    
  # Fetches a page of listing urls.
  # 
  # @param {Number} page The page number to scrape
  # @param {Function} callback Callsback with (err, urls)

  fetchListingUrls: (page, callback) ->
    host = "http://" + urlLib.parse(@listUrl).host
    url = @listUrl.replace('{page}', page)
    console.log "Fetching page #{page} from #{url}..."
    @browser.visit url, (err) =>
      $ = jQuery.create(@browser.window)
      $listings = $(@listItemSelector)
      if $listings?.length is 0
        console.log "ERROR: Found no listings on page #{page}"
        callback {}
      else
        urls = $listings.map((i, el) -> host + $(el).attr('href')).toArray()
        callback null, urls

  # Scrapes a range of pages recursively and saves the empty listings to mongo.
  # 
  # @param {Number} start
  # @param {Number} end
  # @param {Function} callback Callsback with (err)

  scrapePagesRecur: (start, end, callback) =>  
    total = end - start + 1
    console.log "Scraping #{total} pages..."
    callback = _.after total, callback
    page = start
    scrape = =>
      @scrapePage page, ->
        page++
        scrape()
    scrape()
  
  # Scrapes a range of pages in parallel and saves the empty listings to mongo.
  # 
  # @param {Number} start
  # @param {Number} end
  # @param {Function} callback Callsback with (err)

  scrapePagesParallel: (start, end, callback) =>  
    total = end - start + 1
    console.log "Scraping #{total} pages..."
    callback = _.after total, callback
    @scrapePage(page, callback) for page in [0..total]

  # Scrapes a single page and saves the empty listings to mongo.
  # 
  # @param {Number} page
  # @param {Function} callback Callsback with (err)

  scrapePage: (page, callback) =>
    @fetchListingUrls page, (err, urls) =>
      return callback('fail') if err
      listings = ({ url: url } for url in urls)
      Listings.upsert listings, (err) ->
        console.log "Saved page #{page}."
        callback()
        
  # Scrapes an individual listing and converts it to our data model.
  # 
  # @param {String} url The listing page's url
  # @param {Function} Callsback with (err, listing)
 
  fetchListing: (url, callback) ->
    console.log "Fetching listing from #{url}..."
    @browser.visit url, (err) =>
      $ = jQuery.create(@browser.window)
      console.log "Saved listing from #{url}."
      callback null, _.extend @$ToListing($), url: url
      
  # No-op that converts a browser window context to a listing object close to our schema.
  # 
  # @param {Object} window The Browser window
  # @return {Object} The listing object to be persisted into mongo
  
  $ToListing: (window) ->
    
  # Goes through listings without `dateScraped` and populates them by scraping
  # their urls.
  # 
  # @param {Function} callback Callsback with (err)

  populateEmptyListings: (limit, callback = ->) ->
    Listings.collection.find(
      dateScraped: null
      url: { $regex: urlLib.parse(@listUrl).host }
    ).limit(parseInt limit).toArray (err, listings) =>
      if listings.length is 0
        console.log "All listings scraped!"
        callback()
        return
      console.log "Scraping #{listings.length} listings..."
      callback = _.after listings.length, callback
      for { url } in listings
        @fetchListing url, (err, listing) =>
          return if err
          listing.dateScraped = new Date
          Listings.upsert(listing)
          callback()