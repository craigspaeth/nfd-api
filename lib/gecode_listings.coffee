# 
# Iterates through the listings in the database and generates the geocode data
# from google maps.
# 

dal = require '../dal'

dal.connect ->
 dal.listings.find { page: 1 }, (err, listings) ->
   for listing in listings
     dal.listings.geocode listing, console.log