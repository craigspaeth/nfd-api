dal = require '../dal'

module.exports =

'GET /':
  cb: (req, res) ->
    res.send 'This is No Fee Digs API server.'