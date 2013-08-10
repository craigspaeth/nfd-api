listings = require '../../dal/listings'
collectionStub = require '../helpers/collection_stub.coffee'
sinon = require 'sinon'

describe 'listings', ->
  
  before ->
    listings.collection = collectionStub
    
  describe '#upsert', ->
    
    beforeEach ->
      @spy = sinon.spy listings.collection, 'update'
      
    afterEach ->
      @spy.restore?()
    
    it 'upserts restricting to urls', ->
      listings.upsert [{ url: 'foo', foo: 'foo' }, {  url: 'bar', bar: 'foo' }]
      @spy.args[0][0].url.should.equal 'foo'
      @spy.args[1][0].url.should.equal 'bar'
      
    it 'upserts each document', ->
      listings.upsert [{ url: 'foo', foo: 'foo' }, {  url: 'bar', bar: 'foo' }]
      @spy.calledTwice.should.be.ok
    
    it 'updates the passed info', ->
      listings.upsert [{ url: 'foo', foo: 'foo' }, {  url: 'bar', bar: 'bar' }]
      @spy.args[0][1].foo.should.equal 'foo'
      @spy.args[1][1].bar.should.equal 'bar'
  