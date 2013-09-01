# 
# Iterates through the listings in the database and generates the geocode data
# from google maps.
# 

dal = require '../dal'
Listings = require '../dal/listings'
_ = require 'underscore'
         
# Geocode the page indicated by the first argument if the module has been run directly
return unless module is require.main
dal.connect ->
  callback = ->
    console.log "Finished geocoding."
    process.exit()
  Listings.collection
    .find(_.extend(
      { "location.lat": null, "dateGeocoded": null }
      Listings.GOOD_PARAMS
    )).limit(2500).toArray (err, listings) ->
      console.log "Starting to geocode #{listings.length} listings..."
      callback = _.after listings.length, callback
      geoCodeListing(i, listing, callback) for listing, i in listings

geoCodeListing = (i, listing, callback) ->
  setTimeout ->
    Listings.geocode listing, (err, listing) -> 
      if err
        console.log(err)
        process.exit() if err is 'OVER_QUERY_LIMIT'
      else
        console.log "Geocoded '#{listing.location.name}'."
      callback()
  , i * 500