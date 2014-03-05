{ insert, toJSON } = require '../dal/users'
async = require 'async'

module.exports =
      
'POST /users':
  desc: """
  Creates a new user.
  
  Params:
  *email*: User's email address when signing up through email.
  *password*: User's password when signing up through email.
  *twitterData*: TBD
  *facebookData*: TBD
  """
  cb: (req, res, next) ->
    insert req.body, (err, user) ->
      return next err if err
      res.send toJSON user