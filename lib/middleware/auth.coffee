# 
# Middleware that ensures a user is authenticated by email and password or access token.
# 

{ findOne, comparePassword, toJSON } = require '../../dal/users'

module.exports.email = (req, res, next) ->
  findOne { email: req.param('email') }, (err, user) ->
    return next err if err
    return res.send 404, { error: "User not found." } unless user?
    comparePassword user, req.param('password'), (err, pass) ->
      return next(err) if err
      return res.send 403, { error: "Wrong password." } unless pass
      req.user = toJSON user
      next()

module.exports.accessToken = (req, res, next) ->
  findOne { accessToken: req.param('accessToken') }, (err, user) ->
    return next err if err
    return res.send 403, { error: "Invalid or expired access token." } unless user?
    req.user = toJSON user
    next()