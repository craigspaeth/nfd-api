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
    .find({ "location.lat": null, "location.name": { $ne: null }, "dateGeocoded": null })
    .limit(parseInt process.argv[2])
    .toArray (err, listings) ->
      console.log "Starting to geocode #{listings.length} listings..."
      callback = _.after listings.length, callback
      for listing in listings
        Listings.geocode listing, (err, listing) -> 
          if err
            console.log(err)
          else
            console.log "Geocoded '#{listing.location.name}'."
          callback()