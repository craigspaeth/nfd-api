sinon = require 'sinon'
Listings = require '../../dal/listings'
routes = require '../../routes/listings'
collectionStub = require '../helpers/collection-stub'

describe 'listings routes', ->
  
  describe 'GET /listings', ->
    
    beforeEach ->
      Listings.collection = collectionStub()
    
    it 'returns listings', ->
      Listings.find = sinon.stub()
      Listings.find.callsArgWith 1, null, [{ foo: 'bar' }, { bar: 'foo' }]
      routes['GET /listings'].cb { query: { foo: 'bar' } }, { send: sendStub = sinon.stub() }
      Listings.collection.count.args[0][0] null, 10
      Listings.collection.count.args[1][1] null, 5
      sendStub.args[0][0].count.should.equal 5
      sendStub.args[0][0].total.should.equal 10
      sendStub.args[0][0].results[0].foo.should.equal 'bar' 
      
  describe 'GET /listings/:id', ->
    
    beforeEach ->
      sinon.stub Listings, 'findOne'
      Listings.findOne.callsArgWith 1, null, { name: 'foo' }
    
    afterEach ->
      Listings.findOne.restore()
    
    it 'returns one listing', ->
      routes['GET /listings/:id'].cb { params: { id: 'bar' } }, { send: sendStub = sinon.stub() }
      Listings.findOne.args[0][0].should.equal 'bar'
      listing = sendStub.args[0][0]
      listing.name.should.equal 'foo'