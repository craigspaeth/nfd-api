Listings = require '../dal/listings'

module.exports =

'GET /':
  cb: (req, res) ->
    console.log 'index'
    Listings.countBad (err, badCount, total) ->
      Listings.badDataHash (err, badHash) ->
        res.render 'index',
          badCount: badCount
          badHash: badHash
          total: total