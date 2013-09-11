Listings = require '../dal/listings'
_ = require 'underscore'

module.exports =

'GET /listings': 
  desc: """
  Retrieves all listings, returns listings as a hash with data on the whole set and the
  listing data itself inside `results`.
  
  e.g.
  
  {
    count: 100,
    results: []
  }
  
  Query params:
  *bed-min*: Filters by minimum number of bedrooms.
  *bath-min*: Filters by minimum number of bathrooms.
  *rent-max*: Filters by a maximum rent.
  *neighborhoods*: Filters by an array of neighborhood names e.g. ['Astoria', 'UWS'].
  See /neighborhoods for a list of all available neighborhoods.
  *sort*: Sorts the listings by various terms. These terms include:
    * "size" Sorted by the combination of number of beds and baths, then sorted by price within that
    * "price" Simply sorted by price low to high 
  *size*: Limits the ammount of results per page. Default: 50
  *page*: Page of results to fetch.
  """
  cb: (req, res) ->
    listings = []
    count = 0
    callback = _.after 2, ->
      res.send { count: count, results: listings }
    Listings.collection.count (err, _count) ->
      count = _count
      callback()
    Listings.find req.query, (err, _listings) ->
      return res.send 500 if err
      listings = _listings
      callback()
      
'GET /listings/:id':
  desc: """
  Retrieves a listing by id.
  """
  cb: (req, res) ->
    Listings.findOne req.params.id, (err, doc) ->
      res.send Listings.toJSON doc