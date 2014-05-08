# 
# A base set of behaviors like findOne etc.
# 

_ = require 'underscore'
{ ObjectID } = mongodb = require 'mongodb'

@extend = (context) ->
  context[k] = _.bind(fn, context) for k, fn of _.omit _.clone(module.exports), 'extend'

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
  update = =>
    @collection.findAndModify idQuery(query), [], { $set: attrs }, {}, =>
      @findOne query, callback
  if @sanitize?
    @sanitize attrs, (err, a) ->
      attrs = a
      update()
  else
    update()

# Returns a mongo query object if query is an ID string.
# 
# @param {Object|String} query

idQuery = (query) ->
  if query.toString().length is 24 then { _id: new ObjectID(query.toString()) } else query