# 
# A base library of common scraping actions like gathering the listing detail urls from
# a list view and saving the empty listings to be populated later.
# 

jQuery = require 'jquery'
Listings = require '../../dal/listings'
_ = require 'underscore'
_.mixin require('underscore.string').exports()
Browser = require 'zombie'
{ parse, resolve } = require 'url'
cheerio = require 'cheerio'
{ SCRAPE_PER_MINUTE, VISIT_TIMEOUT, MIXPANEL_KEY } = require '../../config'
request = require 'request'
jsdom = require 'jsdom'
fs = require 'fs'

inputProxy = (proxyUrl, inputSelector, buttonSelector, url, cb) ->
  Browser.visit proxyUrl, { runScripts: false }, (err, browser) =>
    return cb '' if err
    browser.wait -> browser.fill(inputSelector, url).pressButton buttonSelector, ->
      browser.wait -> cb browser.location.href

PROXIES = [
  # (url, cb) -> cb "http://translate.google.com/translate?sl=ja&tl=en&u=#{url}"
  (url, cb) -> cb "http://proxy2974.my-addr.org/myaddrproxy.php/http/#{url.replace('http://', '')}"
  (url, cb) -> inputProxy 'http://www.rxproxy.com/', '#address_box', '#go', url, cb
  (url, cb) -> inputProxy 'http://www.surfert.nl/', '#address_box', '#go', url, cb
  # (url, cb) -> inputProxy 'http://websiteproxy.co.uk/', 'input[name=url]', '.bigbtn', url, cb
]

Array::toArray = -> @

module.exports = class Scraper
  
  constructor: (attrs) ->
    _.extend @, attrs
    @requestsPerMinute = SCRAPE_PER_MINUTE
    @samePagesCount = 0
    @scrapePageTimeouts = []
    @host = parse(@listUrl 0).hostname
    @zombieOpts = _.extend({
      silent: true
      runScripts: false
      waitFor: 2000
      maxWait: 15000
    }, @zombieOpts, { userAgent:
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.57 Safari/537.36"
    })
    @engines ?= { list: 'zombie', item: 'zombie' }
  
  proxiedUrl: (url, callback) ->
    return callback(url) unless @useProxy
    _.sample(PROXIES)(url, callback)
  
  # Wrapper over zombie's visit to switch between zombie and superagent.
  # 
  # @param {String} url
  # @param {Function} callback Callsback with (err, $)

  visit: (engine, url, callback) =>
    timeout = null
    # Callback with the $ and window objects
    cb = (err, $, window) ->
      clearTimeout timeout
      return callback err if err
      if $('html').html().length <= 30
        console.log "Document too small for #{url}, looks like:"
        return callback Error("Document too small for. #{url}")
      callback null, $, window
    # Visit the url depending on which engine was chosen
    switch engine
      when 'zombie'
        Browser.visit url, @zombieOpts, (err, browser) ->
          browser.wait ->
            cb err, jQuery.create(browser.window), browser.window
      when 'request'
        request url, (err, res, body) -> cb err, cheerio.load(body)
      when 'jsdom'
        jsdom.env url, [], (err, window) -> cb err, jQuery.create(window), window
    # Ensure that visiting a url times out after a while
    timeout = setTimeout (-> cb "Timeout for #{url}"), VISIT_TIMEOUT

  # Scrapes a single page and saves the empty listings to mongo.
  # 
  # @param {Number} page
  # @param {Function} callback Callsback with (err)

  scrapePage: (page, callback, endCallback) =>
    delay = _.random(
      ((page - 1) * (60 / @requestsPerMinute)) * 1000
      (page * (60 / @requestsPerMinute)) * 1000
    )
    @scrapePageTimeouts.push setTimeout =>
      if @samePagesCount > 2
        console.log "These listings are looking the same for #{@host}, done scraping pages!"
        clearTimeout(timeout) for timeout in @scrapePageTimeouts
        endCallback()
        return
      @fetchListingUrls page, (err, urls) =>
        return callback('fail') if err
        Listings.collection.count { url: { $in: urls } }, (err, count) =>
          if count is urls.length and urls.length > 0 and count > 0
            console.log "Page #{page} already scraped from #{@host}."
            @samePagesCount++
            callback()
          else
            listings = ({ url: url } for url in urls)
            Listings.upsert listings, (err) =>
              console.log "Saved page #{page} for #{@host}."
              callback()
    , delay
  
  # Scrapes a range of pages in parallel and saves the empty listings to mongo.
  # 
  # @param {Number} start
  # @param {Number} end
  # @param {Function} callback Callsback with (err)

  scrapePages: (start, end, callback) =>  
    pages = [start..end]
    console.log "Scraping up to #{pages.length} pages from #{@host}..."
    cb = _.after pages.length, callback
    @scrapePage(page, cb, callback) for page in pages
  
  # Fetches a page of listing urls.
  # 
  # @param {Number} page The page number to scrape
  # @param {Function} callback Callsback with (err, urls)

  fetchListingUrls: (page, callback) ->
    console.log "Fetching page #{page} from #{@listUrl(page)}..."
    @proxiedUrl @listUrl(page), (url) =>
      @visit @engines['list'], url, (err, $) =>
        return callback err if err
        res = @$toListingUrls($)
        if _.isArray(res) then callback(null, res) else callback(res)

  $toListingUrls: ($) =>
    if ($listings = $ @listItemSelector).length is 0
      console.log "ERROR: #{err}"
      @samePagesCount++
      new Error "Found no listings at #{url}"
    else
      urls = $listings.map((i, el) =>
        href = $(el).attr('href') or el.attribs?.href
        @editListingUrl resolve "http://" + @host, href
      ).toArray()
  
  # Scrapes an individual listing and converts it to our data model.
  # 
  # @param {String} url The listing page's url
  # @param {Function} Callsback with (err, listing)
 
  fetchListing: (url, total, callback) ->
    delay = _.random 0, ((60 / @requestsPerMinute) * 1000) * total
    setTimeout =>
      @proxiedUrl url, (visitUrl) =>
        console.log "Fetching listing from #{visitUrl}..."
        @visit @engines['item'], visitUrl, (err, $, window) =>
          err = 'No dollar sign!? ' + @engines?.item unless $?
          if err
            callback @$ToListing($, window)
          else
            callback null, _.extend @$ToListing($, window), url: url
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
          @saveListing url, listing, callback

  saveListing: (url, listing, callback) ->
    Listings.upsert listing, (err, docs) =>
      return callback err if err
      console.log "Saved listing from #{url}.", listing
      callback()
  
  # No-op that converts a browser window context to a listing object close to our schema.
  # 
  # @param {Object} window The Browser window
  # @return {Object} The listing object to be persisted into mongo
  
  $ToListing: (window) ->
  
  # When scraping listing urls the hrefs might not be the desired url to go to.
  # e.g. For streeteasy we want to pass a query param to get the old street easy.
  # 
  # @param {String} url
  
  editListingUrl: (url) -> url

  @parseBeds: (text) ->
    text = _.clean(text) or ''
    parsed = parseFloat if text.match(/studio/i) then 0 else text.match(/[\.\d]* bed/i) or text
    if _.isNaN(parsed) then null else parsed

  @parseBaths: (text) ->
    text = _.clean(text) or ''
    parsed = parseFloat if text.match(/full/i) then 1 else text.match(/[\.\d]* bath/i) or text
    if _.isNaN(parsed) then null else parsed