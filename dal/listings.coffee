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
#     lon: Number,
#     lng: Number
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
PAGE_SIZE = 50

@upsert = (listings, callback = ->) =>
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

@toJSON = (docs) ->
  if _.isArray(docs) then (schema(doc) for doc in docs) else schema(docs)

schema = (doc) ->
  _.extend doc,
    id: doc._id
    _id: undefined