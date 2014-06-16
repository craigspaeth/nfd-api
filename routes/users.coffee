{ insert, toJSON, update, findOne, resetPassword, createAccessToken,
  getAlertHTML } = require '../dal/users'
async = require 'async'
ClientApplications = require '../dal/client-applications'
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
  *id*: User's id
  *email*: User's email address when signing up through email.
  *password*: User's password when signing up through email.
  *alerts*: An array of { query: Object, name: String } hashes storing alerts for User.
  """
  cb: [
    auth.accessToken
    (req, res, next) ->
      return res.send 403, { error: 'Access denied.' } unless req.user._id.toString() is req.param('id')
      update req.param('id'), req.body, (err, user) ->
        return next err if err
        res.send toJSON user
  ]

'GET /users/:id':
  desc: """
  Returns a user.
  
  Params:
  *id*: User's id.
  *accessToken*: Access token.
  """
  cb: [
    auth.accessToken
    (req, res, next) ->
      findOne req.params.id, (err, user) ->
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
      createAccessToken req.user, (err, user) ->
        return next err if err
        res.send toJSON user
  ]

'POST /users/reset-password':
  desc: """
  Sets a temporary accessToken on User and emails them a reset link.
  
  Params:
  *email*: User's email address.
  """
  cb: (req, res, next) ->
    resetPassword req.param('email'), (err, resp) ->
      return next err if err
      res.send resp

'GET /users/:id/alerts/:index/email':
  desc: """
  Shows the email template for a user's alerts.

  Params:
  *id*: User's id.
  *index*: The index of the user's alerts. e.g. 0 is the first alert for the user.
  """
  cb: (req, res, next) ->
    findOne req.params.id, (err, user) ->
      return next err if err
      getAlertHTML user.alerts[req.params.index], (err, html) ->
        return next err if err
        res.send html