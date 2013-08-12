# 
# Iterates through the listings in the database and generates the geocode data
# from google maps.
# 

dal = require '../dal'

dal.connect ->
 dal.listings.findOne '5208281c6febd8053931785d', (err, listing) ->
   dal.listings.geocode listing, console.log