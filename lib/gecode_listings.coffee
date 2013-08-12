# 
# Iterates through the listings in the database and generates the geocode data
# from google maps.
# 

dal = require '../dal'
_ = require 'underscore'
  
geocodePage = (page, callback) ->
  dal.listings.find { page: page }, (err, listings) ->
    callback = _.after listings.length, callback
    for listing in listings
      if listing.location.lng
        callback()
      else
        dal.listings.geocode listing, (err, listing) -> 
         return console.log(err) if err
         console.log "Geocoded '#{listing.location.name}'."
         callback()
         
# Geocode the page indicated by the first argument if the module has been run directly
return unless module is require.main
dal.connect ->
  geocodePage (process.argv[2] or 1), ->
    console.log "Finished geocoding."
    process.exit()