# 
# Drops old listings
# 

dal = require '../dal'
Listings = require '../dal/listings'
_ = require 'underscore'
         
# Geocode the page indicated by the first argument if the module has been run directly
return unless module is require.main
dal.connect ->
  Listings.dropOld (err, num) ->
    if err then console.log 'ERR: ' + err else console.log "Dropped #{num} listings!"
    process.exit()