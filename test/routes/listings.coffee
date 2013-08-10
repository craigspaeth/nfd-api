sinon = require 'sinon'
dal = require '../../dal'
dal.listings = require '../../dal/listings'
routes = require '../../routes/listings'

describe 'listings routes', ->
  
  describe 'GET /listings', ->
    
    beforeEach ->
      sinon.stub dal.listings, 'find'
      dal.listings.find.callsArgWith 1, null, [{ name: 'foo' }]
    
    afterEach ->
      dal.listings.find.restore()
    
    it 'returns listings', ->
      routes['GET /listings'] { query: { foo: 'bar' } }, { send: sendStub = sinon.stub() }
      dal.listings.find.args[0][0].foo.should.equal 'bar'
      listings = sendStub.args[0][0]
      listings[0].name.should.equal 'foo'
      
  describe 'GET /listings/:id', ->
    
    beforeEach ->
      sinon.stub dal.listings, 'findOne'
      dal.listings.findOne.callsArgWith 1, null, { name: 'foo' }
    
    afterEach ->
      dal.listings.findOne.restore()
    
    it 'returns one listing', ->
      routes['GET /listings/:id'] { params: { id: 'bar' } }, { send: sendStub = sinon.stub() }
      dal.listings.findOne.args[0][0].should.equal 'bar'
      listing = sendStub.args[0][0]
      listing.name.should.equal 'foo'