# Listing
# 
# An apartment listing. Contains information about the apartment, who to contact,
# where the listing came from, and more.
# 
# Common Schema:
# 
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
#   contact_info: {
#     name: String,
#     phone_number: String,
#     email: String,
#     website: String,
#     address: String
#   },
#   description: String,
#   listed_date: Date

_ = require 'underscore'
{ ObjectID } = mongodb = require 'mongodb'
@gm = require 'googlemaps'
PAGE_SIZE = 50

@upsert = (listings, callback = ->) =>
  listings = [listings] unless _.isArray(listings)
  callback = _.after listings.length, callback
  for listing in listings
    @collection.update { url: listing.url }, listing, { upsert: true }, callback

@findOne = (id, callback) =>
  @collection.findOne { _id: new ObjectID(id) }, callback
  
@find = (params, callback) =>
  options = {}
  options.beds = { $gte: parseInt params.bed_min } if params.bed_min?
  options.beds = { $gte: parseInt params.bed_min } if params.bath_min?
  options.rent = { $lte: parseInt params.rent_max } if params.rent_max?
  @collection.find(options)
             .skip(PAGE_SIZE * options.page or 0)
             .limit(PAGE_SIZE)
             .toArray callback

@geocode = (listing, callback) =>
  return callback("Listing must have a name.") unless listing.location.name
  @gm.geocode listing.location.name, (err, res) =>
    return callback(err) if err
    return callback("No results.") if res.status is 'ZERO_RESULTS'
    firstResult = res.results[0]
    neighborhood = (comp.short_name for comp in firstResult.address_components \
                                    when 'neighborhood' in comp.types)[0]
    listing.location = _.extend listing.location,
      formatted_address: firstResult.formatted_address
      lng: firstResult.geometry.location.lng
      lat: firstResult.geometry.location.lat
      neighborhood: neighborhood
    @upsert [listing], (err, listings) =>
      return callback(err) if err
      callback null, listing

@toJSON = (listings) ->
  if _.isArray(listings) then (@schema(listing) for listing in listings) else @schema(listings)

@schema = (doc) ->
  _.extend doc,
    id: doc._id
    _id: undefined