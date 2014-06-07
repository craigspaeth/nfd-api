Listings = require '../dal/listings'
async = require 'async'

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
    async.parallel {
      total: (cb) -> Listings.collection.count(cb)
      count: (cb) -> Listings.count(req.query, cb)
      results: (cb) -> Listings.find(req.query, cb)
    }, (err, results) ->
      return res.send 500 if err
      res.send results
      
'GET /listings/:id':
  desc: """
  Retrieves a listing by id.
  """
  cb: (req, res) ->
    Listings.findOne req.params.id, (err, doc) ->
      return res.send 404, { error: "Listing not found." } unless doc?
      res.send Listings.toJSON doc