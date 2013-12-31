dal = require './dal'
Listings = require './dal/listings'

dal.connect (err) ->
  Listings.badDataHash (err, count) ->
    console.log 'moo', count
    process.exit()