# User
# 
# A user at no fee digs. Stores all of the typical user information like username, email
# password, preferences, etc.
# 
# Schema: {
#   email: String,
#   password: String,
#   twitterData: Object,
#   facebookData: Object
# }

_ = require 'underscore'
{ ObjectID } = mongodb = require 'mongodb'
{ isEmail } = require 'validator'

# Creates a user.
# 
# @param {Object} user User data
# @param {Function} callback Calls back with (err, doc)

@insert = (user, cb = ->) =>
  return cb err if err = validate user
  @collection.insert sanitize(user), (err, docs) ->
    cb err, docs[0]

sanitize = (doc) ->
  _.pick(doc, 'email', 'password', 'twitterData', 'facebookData')

validate = (doc) ->
  return new Error "Invalid email" unless isEmail doc.email
  return new Error "Password too short" unless doc.password?.length > 6
  return

# Converts a raw user document into a JSON hash to be read in our API.
# 
# @param {Object} user User document

@toJSON = (doc) ->
  _.extend doc,
    id: doc._id
    _id: undefined