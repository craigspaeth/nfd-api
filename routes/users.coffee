{ insert, toJSON, update } = require '../dal/users'
async = require 'async'
ClientApplications = require '../dal/client-applications'
crypto = require 'crypto'
auth = require '../lib/middleware/auth'
_ = require 'underscore'

module.exports =
      
'POST /users':
  desc: """
  Creates a new user.
  
  Params:
  *email*: User's email address when signing up through email.
  *password*: User's password when signing up through email.
  *twitter-data*: TBD
  *facebook-data*: TBD
  """
  cb: (req, res, next) ->
    insert req.body, (err, user) ->
      return next err if err
      res.send toJSON user

'POST /access-token':
  desc: """
  Get an access token Logs in a user via email and password.
  
  Params:
  *id*: Application client id
  *secret*: Application client secret 
  *email*: User's email address when signing up through email.
  *password*: User's password when signing up through email.
  """
  cb: [
    (req, res, next) ->
      ClientApplications.findOne {
        id: req.body['id']
        secret: req.body['secret']
      }, (err, clientApp) ->
        return next err if err
        return res.send 404, { error: "Client application not found." } unless clientApp?
        next()
    , auth.email
    (req, res) ->
      update req.user.id, {
        accessToken: token = crypto.createHash('md5').update(Math.random().toString()).digest('hex')
      }, (err, user) ->
        return next err if err
        res.send _.extend toJSON(req.user), accessToken: token
  ]

'GET /me':
  desc: """
  Returns the current user json.
  
  Params:
  *token*: Access token.
  """
  cb: [
    auth.accessToken
    (req, res, next) ->
      res.send toJSON req.user
    ]