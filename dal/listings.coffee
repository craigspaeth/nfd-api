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
#     formatted_address: String,
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

DEFAULT_PAGE_SIZE = 50
NEIGHBORHOOD_GROUPS =
  'Uptown': [
    'Lenox Hill'
    'Lincoln Square'
    'UES'
    'UWS'
    'East Harlem'
    'Fort George'
    'Hamilton Heights'
    'Harlem'
    'Inwood'
    'Upper Manhattan'
    'Washington Heights'
    'Yorkville'
    'Hudson Heights'
  ]
  'Midtown': [
    'Chelsea'
    'Gramercy Park'
    "Hell's Kitchen"
    'Kips Bay'
    'Midtown'
    'Turtle Bay'
    'Korea Town'
    'Sutton Place'
    'Union Square'
    'Theater District - Times Square'
  ]
  'Downtown': [
    'Lower Manhattan'
    'Alphabet City'
    'Downtown'
    'East Village'
    'Greenwich Village'
    'Lower East Side'
    'NoLita'
    'South Side'
    'World Trade Center'
    'Bowery'
    'Chinatown'
    'Little Italy'
  ]
  'South Brooklyn': [
    'Clinton Hill'
    'Crown Heights'
    'Downtown Brooklyn'
    'Sheepshead Bay'
    'Brooklyn Heights'
    'East Flatbush'
    'East New York'
    'Fort Greene'
    'Vinegar Hill'
    'Bay Ridge'
    'Carroll Gardens'
    'Flatbush - Ditmas Park'
    'Greenwood'
    'Park Slope'
    'Sunset Park'
    'Prospect Lefferts Gardens'
  ]
  'North Brooklyn': [
    'Bushwick'
    'Williamsburg'
    'Bedford-Stuyvesant'
    'Dumbo'
    'East Williamsburg'
    'Greenpoint'
  ]
  'Queens': [
    'LIC'
    'Roosevelt Island'
    'Astoria'
    'Hunters Point'
    'Bayside'
    'Elmhurst'
    'Flushing'
    'Jamaica'
    'Middle Village'
    'Corona'
    'Forest Hills'
    'Kew Gardens'
    'Kew Gardens Hills'
  ]
  'Bronx': [
    'Kingsbridge'
    'Mott Haven'
    'Concourse'
    'Morris Heights'
  ]
  'Staten Island': [
    'Park Hill'
  ]
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

# Convenient alias to mongo findOne.
# 
# @param {String} id
# @param {Function} callback Calls back with (err, doc)

@findOne = (id, callback) =>
  @collection.findOne { _id: new ObjectID(id) }, callback

# A `find` operation that is allowed by users. Pass in params that would be
# sent via query params and it'll translate that into the right mongo queries.
# 
# @param {Object} params Query params see the API documentation.
# @param {Function} callback Calls back with (err, listings)

@find = (params, callback) =>
  pageSize = parseInt(params.size) or DEFAULT_PAGE_SIZE
  query = {}
  query.beds = { $gte: parseInt params.bed_min } if params.bed_min?
  query.baths = { $gte: parseInt params.bath_min } if params.bath_min?
  query.rent = { $lte: parseInt params.rent_max } if params.rent_max?
  query['location.neighborhood'] = { $in: params.neighborhoods } if params.neighborhoods?
  query[key] = _.extend(query[key] ? {}, val) for key, val of GOOD_PARAMS
  cursor = @collection.find(query)
  cursor.sort(rent: 1) if params.sort is 'rent'
  cursor.sort(beds: -1, baths: -1) if params.sort is 'size'
  cursor.skip(pageSize * params.page or 0).limit(pageSize).toArray (err, listings) =>
    callback err, @toJSON listings

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
      formatted_address: firstResult.formatted_address
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

# Converts a raw listing document into a JSON hash useable in our API.
# 
# @param {Object} docs Array or object of listing documents

@toJSON = (docs) ->
  schema = (doc) ->
    _.extend doc,
      id: doc._id
      _id: undefined
  if _.isArray(docs) then (schema(doc) for doc in docs) else schema(docs)