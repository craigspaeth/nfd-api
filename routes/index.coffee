Listings = require '../dal/listings'

module.exports =

'GET /':
  cb: (req, res) ->
    Listings.countBad (err, badCount, total) ->
      Listings.sourcesHash (err, sourcesHash) ->
        res.render 'index',
          badCount: badCount
          sourcesHash: sourcesHash
          total: total