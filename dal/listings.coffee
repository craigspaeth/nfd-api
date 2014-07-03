# Listing
# 
# An apartment listing. Contains information about the apartment, who to contact,
# where the listing came from, and more.
# 
# Schema: {
#   pictures: [String],
#   rent: Number,
#   beds: Number,
#   baths: Number,
#   location: {
#     name: String,
#     formattedAddress: String,
#     lat: Number,
#     lng: Number,
#     neighborhood: String
#   }
#   url: String,
#   contactInfo: {
#     name: String,
#     phone_number: String,
#     email: String,
#     website: String,
#     address: String
#   },
#   description: String,
#   dateScraped: Date,
#   dateListed: Date,
#   dateGeocoded: Date
# }

_ = require 'underscore'
{ ObjectID } = mongodb = require 'mongodb'
@gm = require 'googlemaps'
scrapers = require '../lib/scrape/scrapers'
require('./base').extend this

DEFAULT_PAGE_SIZE = 50
NEIGHBORHOOD_GROUPS = require '../lib/neighborhood-groups'
GOOD_PARAMS = @GOOD_PARAMS =
  'location.name': { $ne: null }
  rent: { $ne: 0 }
  # pictures: { $nin: [[], null] }
  
# Upserts listings into mongo using the listing url as the identifier for unique listings.
# 
# @param {Object} listings Array or single listing
# @param {Function} callback Calls back with (err, docs)

@upsert = (listings, callback = ->) =>
  listings = [listings] unless _.isArray(listings)
  callback = _.after listings.length, callback
  for listing in listings
    @collection.update { url: listing.url }, listing, { upsert: true }, callback

# A `find` operation that is allowed by users. Pass in params that would be
# sent via query params and it'll translate that into the right mongo queries.
# 
# @param {Object} params Query params see the API documentation.
# @param {Function} callback Calls back with (err, listings)

@find = (params, callback) =>
  pageSize = parseInt(params.size) or DEFAULT_PAGE_SIZE
  cursor = @collection.find(@buildQuery params)
  cursor.sort(rent: 1) if params.sort is 'rent'
  cursor.sort(beds: -1, baths: -1) if params.sort is 'size'
  cursor.sort(dateScraped: -1) if params.sort is 'newest'
  cursor.skip(pageSize * params.page or 0).limit(pageSize).toArray (err, listings) =>
    callback err, @toJSON listings
    
# A `count` operation that uses the params used by `find`. Pass in params that would be
# sent via query params and it'll translate that into the right mongo queries.
# 
# @param {Object} params Query params see the API documentation.
# @param {Function} callback Calls back with (err, count)

@count = (params, callback) =>
  @collection.count(@buildQuery(params), callback)

# Converts query params into a mongo query for searching listings.
# 
# @param {Object} params Query params
# @return Returns mongo query object

@buildQuery = (params) ->
  query = {}
  query.beds = { $gte: parseInt params['bed-min'] } if params['bed-min']?
  query.baths = { $gte: parseInt params['bath-min'] } if params['bath-min']?
  query.rent = { $lte: parseInt params['rent-max'] } if params['rent-max']?
  query.dateScraped = { $gte: new Date(params['date-scraped-start']) } if params['date-scraped-start']?
  query['location.neighborhood'] = { $in: params.neighborhoods } if params.neighborhoods?
  query[key] = _.extend(query[key] ? {}, val) for key, val of GOOD_PARAMS
  query

# Uses google maps to populate location data and geocode a listing.
# 
# @param {Object} listing
# @param {Function} callback Calls back with (err, listing)

@geocode = (listing, callback) =>
  @gm.geocode listing.location.name, (err, res) =>
    return callback(err) if err
    firstResult = (result for result in res?.results when result.formatted_address.match 'NY')[0]
    return callback(res.status) unless firstResult
    listing.location = _.extend listing.location,
      formattedAddress: firstResult.formatted_address
      lng: firstResult.geometry.location.lng
      lat: firstResult.geometry.location.lat
      neighborhood: (comp.short_name for comp in firstResult.address_components \
                                     when 'neighborhood' in comp.types)[0]
    listing.dateGeocoded = new Date
    @upsert listing, (err, listings) =>
      return callback(err) if err
      callback null, listing

# Says the number of bad listings there are.
# 
# @param {Function} callback Calls back with (err, badCount, totalCount)

@countBad = (callback) ->
  @collection.count (err, count) =>
    @collection.count GOOD_PARAMS, (err, goodCount) =>
      callback err, count - goodCount, count

# Gets the neighborhoods from all of the listings via mongo distinct, and maps them into
# our hash of neighborhood groups.
# 
# @param {Function} callback

@findNeighborhoods = (callback) =>
  @collection.distinct 'location.neighborhood', (err, results) ->
    return callback err if err 
    groups = {}
    neighborhoods = _.without(results, null).sort()
    ungroupped = _.without(neighborhoods, _.flatten(_.values(NEIGHBORHOOD_GROUPS))...)
    groups['Other'] = ungroupped if ungroupped.length
    for neighborhood in neighborhoods
      for groupName, groupNeighborhoods of NEIGHBORHOOD_GROUPS
        if neighborhood in groupNeighborhoods
          (groups[groupName] ?= []).push(neighborhood)
    callback null, groups

addCount = (hash, hostname, callback) =>
  @collection.count { url: { $regex: hostname } }, (err, count) ->
    hash[hostname] = count
    callback()

# Converts a raw listing document into a JSON hash useable in our API.
# 
# @param {Object} docs Array or object of listing documents

@toJSON = (docs) ->
  if _.isArray(docs) then (doc for doc in docs) else docs

# Drops listings older than 15 days to keep things fresh.
# 
# @param {Function} callback Calls back with (err, numRemoved)

@dropOld = (callback) =>
  now = new Date()
  date = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 15)
  @collection.remove { dateScraped: { $lte: date } }, callback

# Maps the sources of listings into a hash displaying information about
# the listings groupped by their source, e.g.
# 
# swmanagement: {
#   "No pictures": 580
# },
# streeteasy: {
#   "Null bedrooms": 100
# }
# 
# @param {Function} callback Calls back with (err, hash)

@sourcesHash = (callback) ->
  hash = {}
  hosts = _.uniq (scraper.split('-')[0] for scraper of scrapers)
  cb = _.after hosts.length, (err) -> callback err, hash
  storeSourceData(host, hash, cb) for host in hosts

storeSourceData = (host, hash, callback) =>
  hash[host] ?= {}
  total = 0
  storeCount = (key, query) =>
    @collection.count _.extend({ url: { $regex: host } }, query), (err, count) ->
      return callback(err) if err
      hash[host][key] = count
      callback()
    total++
  storeCount 'No pictures', { pictures: { $in: [[], null] } }
  storeCount 'No rent', { rent: { $in: [0, null] } }
  storeCount 'No bedrooms', { beds: { $in: [0, null] } }
  storeCount 'No bathrooms', { baths: { $in: [0, null] } }
  storeCount 'Missing location', { 'location.name': $in: ['', null] }
  storeCount 'Total', {}
  storeCount 'Undefined in pictures', { pictures: { $regex: 'undefined' } }
  callback = _.after total, callback