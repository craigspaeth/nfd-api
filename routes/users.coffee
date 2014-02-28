{ insert, toJSON } = require '../dal/users'
async = require 'async'

module.exports =
      
'POST /users':
  desc: """
  Creates a user.
  """
  cb: (req, res, next) ->
    insert req.body, (err, user) ->
      return next err if err
      res.send toJSON user