dal = require '../dal'

module.exports =

'GET /listings': 
  desc: """
  Retrieves all listings.
  
  Query params:
  *bed_min*: Filters by minimum number of bedrooms.
  *bath_min*: Filters by minimum number of bathrooms.
  *rent_max*: Filters by a maximum rent.
  *neighborhoods*: Filters by an array of neighborhood names e.g. ['Astoria', 'UWS'].
  See /neighborhoods for a list of all available neighborhoods.
  *sort*: Sorts the listings by various terms. These terms include:
    * "size" Sorted by the combination of number of beds and baths, then sorted by price within that
    * "price" Simply sorted by price low to high 
  *size*: Limits the ammount of results per page. Default: 50
  *page*: Page of results to fetch.
  """
  cb: (req, res) ->
    dal.listings.find req.query, (err, docs) ->
      return res.send 500 if err
      res.send dal.listings.toJSON docs
      
'GET /listings/:id':
  desc: """
  Retrieves a listing by id.
  """
  cb: (req, res) ->
    dal.listings.findOne req.params.id, (err, doc) ->
      res.send dal.listings.toJSON doc