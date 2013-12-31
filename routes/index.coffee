Listings = require '../dal/listings'

@index = (req, res) ->
  Listings.countBad (err, badCount, total) ->
    Listings.badDataHash (err, badHash) ->
      res.render 'index',
        badCount: badCount
        badHash: badHash
        total: total