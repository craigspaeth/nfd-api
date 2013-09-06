sinon = require 'sinon'

METHODS = ['update', 'find', 'skip', 'limit', 'toArray', 'update', 'distinct', 'sort']

module.exports = ->
  collectionStub = {}
  for name in METHODS
    collectionStub[name] = sinon.stub()
    collectionStub[name].returns collectionStub
  collectionStub