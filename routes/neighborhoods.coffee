dal = require '../dal'

module.exports =

'GET /neighborhoods': (req, res) ->
  dal.listings.findNeighborhoods (err, neighborhoods) ->
    return res.send 500 if err
    res.send neighborhoods