# User
# 
# A user at no fee digs. Stores all of the typical user information like username, email
# password, preferences, etc.
# 
# Schema: {
#   name: String,
#   email: String,
#   password: String,
#   twitterData: Object,
#   facebookData: Object,
#   accessToken: String
# }

_ = require 'underscore'
bcrypt = require 'bcrypt'
{ ObjectID } = mongodb = require 'mongodb'
{ isEmail } = require 'validator'
{ BCRYPT_SALT_LENGTH } = require '../config'
require('./base').extend this

# Compares the decrypted password matches the encrypted password on the user.
# 
# @param {Object} user User data
# @param {String} password Unencrypted password string
# @param {Function} cb Calls back with (err, doc)

@comparePassword = (user, password, cb) ->
  bcrypt.compare password, user.password, cb 

# Creates a user and ensures they're not a duplicate based on email and social data.
# 
# @param {Object} user User data
# @param {Function} cb Calls back with (err, doc)

@insert = (user, cb = ->) =>
  return cb err if err = validate user
  sanitize user, (err, user) =>
    return cb err if err
    @collection.findOne { email: user.email }, (err, doc) =>
      return cb new Error "User already exists." if doc
      @collection.insert user, (err, docs) ->
        cb err, docs[0]

sanitize = (doc, cb) ->
  user = _.pick(doc, 'email', 'password', 'twitterData', 'facebookData', 'name')
  bcrypt.hash doc.password, BCRYPT_SALT_LENGTH, (err, hash) ->
    return cb err if err
    user.password = hash
    cb null, user

validate = (doc) ->
  return new Error "Invalid email" unless isEmail doc.email
  return new Error "Password too short" unless doc.password?.length > 6
  return

# Converts a raw user document into a JSON hash to be read in our API.
# 
# @param {Object} user User document

@toJSON = (doc) ->
  _.extend _.omit(doc, 'password'),
    id: doc._id
    _id: undefined