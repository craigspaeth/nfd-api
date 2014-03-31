{ insert, toJSON, update, findOne } = require '../dal/users'
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

'PUT /users/:id':
  desc: """
  Updates a user.
  
  Params:
  *email*: User's email address when signing up through email.
  *password*: User's password when signing up through email.
  *alerts*: An array of { query: Object, name: String } hashes storing alerts for the user.
  """
  cb: [
    auth.accessToken
    (req, res, next) ->
      return res.send 403, { error: 'Access denied.' } unless req.user.id.toString() is req.param('id')
      update req.param('id'), _.pick(req.body, 'email', 'password', 'alerts'), (err, user) ->
        return next err if err
        res.send toJSON user
  ]

'POST /access-token':
  desc: """
  Get an access token & logs in a user via email and password.
  
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
        res.send _.extend toJSON(user), accessToken: token
  ]

'GET /me':
  desc: """
  Returns the current user.
  
  Params:
  *accessToken*: Access token.
  """
  cb: [
    auth.accessToken
    (req, res, next) ->
      res.send toJSON req.user
    ]