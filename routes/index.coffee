Listings = require '../dal/listings'
{ spawnJob } = require '../lib/cron'

module.exports =

'GET /':
  cb: (req, res) ->
    Listings.countBad (err, badCount, total) ->
      Listings.sourcesHash (err, sourcesHash) ->
        res.render 'index',
          badCount: badCount
          sourcesHash: sourcesHash
          total: total

'GET /task/:task': 
  cb: (req, res) ->
    return res.send 404 unless req.param('password') is 'moonset'
    spawnJob "make " + req.param('task')
    res.send "Running task: make #{req.param('task')}"