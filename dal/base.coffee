# 
# A base set of behaviors like findOne etc.
# 

_ = require 'underscore'
{ ObjectID } = mongodb = require 'mongodb'

@extend = (context) ->
  context[k] = _.bind(fn, context) for k, fn of _.omit _.clone module.exports, 'extend'

# Convenient alias to mongo findOne.
# 
# @param {Object} query Pass in a string for ID or an object for mongo query
# @param {Function} callback Calls back with (err, doc)

@findOne = (query, callback) ->
  @collection.findOne idQuery(query), callback

# Convenient alias to mongo update.
# 
# @param {Object} query
# @param {Object} attrs updated attrs
# @param {Function} callback

@update = (query, attrs, callback) ->
  @collection.findAndModify idQuery(query), [], { $set: attrs }, {}, callback

# Returns a mongo query object if query is an ID string.
# 
# @param {Object|String} query

idQuery = (query) ->
  if _.isString(query) then { _id: new ObjectID(query) } else query