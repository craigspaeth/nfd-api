Listings = require '../dal/listings'

module.exports =

'GET /':
  cb: (req, res) ->
    Listings.countBad (err, badCount, total) ->
      res.send "Welcome to No Fee Digs API. " + 
               "There are #{total - badCount} good listings out of #{total} total listings."