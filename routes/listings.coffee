dal = require '../dal'

module.exports =

'GET /listings': (req, res) ->
  dal.listings.find req.query, (err, docs) ->
    return res.send 500 if err
    res.send dal.listings.toJSON docs
    
'GET /listings/:id': (req, res) ->
  dal.listings.findOne req.params.id, (err, doc) ->
    res.send dal.listings.toJSON doc