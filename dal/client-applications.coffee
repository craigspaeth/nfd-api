# ClientApplication
# 
# An API client.
# 
# Schema: {
#   secret: String,
#   name: String
# }

_ = require 'underscore'
{ ObjectID } = mongodb = require 'mongodb'

# For now we only need to auth against our website so we can hard-code this.
ID = 'ddc7384ce313772cfad415c1ed2afc30'
SECRET = '2acfd8a430c873ea7d03335b0644733a'
@findOne = (query, callback) ->
  if query.id is ID and query.secret is SECRET
    callback null, { id: ID, secret: SECRET, name: 'No Fee Digs Website' }
  else
    callback new Error "Could not find application"