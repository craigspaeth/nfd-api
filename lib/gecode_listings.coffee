# 
# Iterates through the listings in the database and generates the geocode data
# from google maps.
# 

dal = require '../dal'
_ = require 'underscore'
         
# Geocode the page indicated by the first argument if the module has been run directly
return unless module is require.main
dal.connect ->
  callback = ->
    console.log "Finished geocoding."
    process.exit()
  dal.listings.collection.find().toArray (err, listings) ->
    console.log "Starting to geocode #{listings.length} listings..."
    callback = _.after listings.length, callback, typeof listings
    for listing in listings
      if listing.location.lng?
        console.log "Already geocoded", listing.location.lng, listing.location.lat
        callback()
      else
        dal.listings.geocode listing, (err, listing) -> 
          return console.log(err) if err
          console.log "Geocoded '#{listing.location.name}'."
          callback()