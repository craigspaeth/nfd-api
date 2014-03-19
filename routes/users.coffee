{ insert, toJSON } = require '../dal/users'
async = require 'async'
passport = require 'passport'

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

'POST /login':
  desc: """
  Logs in a user via email and password. Sets a session cookie so only useful for
  browser -> api communication. Later we will implement oauth2.
  
  Params:
  *email*: User's email address when signing up through email.
  *password*: User's password when signing up through email.
  """
  cb: [
    passport.authenticate('local')
    (req, res) ->
      res.send toJSON req.user
  ]