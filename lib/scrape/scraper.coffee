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
    @[key] = val for key, val of attrs
    @samePagesCount = 0
    @toListingErrorCount = 0
    @scrapePageTimeouts = []
    @host = urlLib.parse(@listUrl 0).host
    @zombieOpts = _.extend({ silent: true }, @zombieOpts, { userAgent:
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.57 Safari/537.36"
    })
  
  # Scrapes a single page and saves the empty listings to mongo.
  # 
  # @param {Number} page
  # @param {Function} callback Callsback with (err)

  scrapePage: (page, callback) =>
    delay = _.random(
      ((page - 1) * (60 / @requestsPerMinute)) * 1000
      (page * (60 / @requestsPerMinute)) * 1000
    )
    @scrapePageTimeouts.push setTimeout =>
      if @samePagesCount > 2
        console.log "These listings are looking the same for #{@host}, done scraping pages!"
        for timeout in @scrapePageTimeouts
          clearTimeout(timeout)
          callback()
        return
      @fetchListingUrls page, (err, urls) =>
        return callback('fail') if err
        Listings.collection.find(url: { $in: urls }).count (err, count) => 
          if count is urls.length and urls.length > 0 and count > 0
            console.log "Page #{page} already scraped from #{@host}."
            @samePagesCount++
            callback()
          else
            listings = ({ url: url } for url in urls)
            Listings.upsert listings, (err) ->
              console.log "Saved page #{page}."
              callback()
    , delay
  
  # Scrapes a range of pages in parallel and saves the empty listings to mongo.
  # 
  # @param {Number} start
  # @param {Number} end
  # @param {Function} callback Callsback with (err)

  scrapePages: (start, end, callback) =>  
    pages = [start..end]
    console.log "Scraping #{pages.length} pages from #{@host}..."
    callback = _.after pages.length, callback
    @scrapePage(page, callback) for page in pages
  
  # Fetches a page of listing urls.
  # 
  # @param {Number} page The page number to scrape
  # @param {Function} callback Callsback with (err, urls)

  fetchListingUrls: (page, callback) ->
    console.log "Fetching page #{page} from #{@listUrl(page)}..."
    url = @listUrl(page)
    url = "http://www.gmodules.com/ig/proxy?url=#{url}" if @useProxy
    Browser.visit url, @zombieOpts, (err, browser) =>
      $ = jQuery.create(browser.window)
      $listings = $(@listItemSelector)
      if $listings?.length is 0
        console.log "ERROR: Found no listings for on page #{page}: #{@listUrl page}"
        callback {}
      else
        urls = $listings.map((i, el) => 
          urlLib.resolve "http://" + @host, $(el).attr 'href').toArray()
        callback null, urls
  
  # Scrapes an individual listing and converts it to our data model.
  # 
  # @param {String} url The listing page's url
  # @param {Function} Callsback with (err, listing)
 
  fetchListing: (url, total, callback) ->
    delay = _.random 0, ((60 / @requestsPerMinute) * 1000) * total
    setTimeout =>
      visitUrl = url
      visitUrl = "http://www.gmodules.com/ig/proxy?url=#{url}" if @useProxy
      console.log "Fetching listing from #{visitUrl}..."
      Browser.visit visitUrl, @zombieOpts, (err, browser) => 
        browser.wait =>
          $ = jQuery.create(browser.window)
          if _.isObject @$ToListing($)
            console.log "Saved listing from #{url}.", @$ToListing($)
            callback null, _.extend @$ToListing($), url: url
          else
            console.log "ERROR from #{url}", @$ToListing($)
            @toListingErrorCount++
            throw "Too many listings returning unexpected HTML" if @toListingErrorCount > 4
            callback @$ToListing($)
    , delay
    
  # Goes through listings without `dateScraped` and populates them by scraping
  # their urls.
  # 
  # @param {Function} callback Callsback with (err)

  populateEmptyListings: (limit, callback = ->) ->
    Listings.collection.find(
      dateScraped: null
      url: { $regex: @host }
    ).limit(limit).toArray (err, listings) =>
      if listings.length is 0
        console.log "All listings scraped for #{@host}!"
        callback()
        return
      console.log "Scraping #{listings.length} listings from #{@host}..."
      callback = _.after listings.length, callback
      for { url } in listings
        @fetchListing url, listings.length, (err, listing) =>
          return callback(err) if err
          listing.dateScraped = new Date
          Listings.upsert(listing)
          callback()
          
  # No-op that converts a browser window context to a listing object close to our schema.
  # 
  # @param {Object} window The Browser window
  # @return {Object} The listing object to be persisted into mongo
  
  $ToListing: (window) ->