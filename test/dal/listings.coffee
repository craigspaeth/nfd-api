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
  
  describe '#geocode', ->
    
    it 'fetches the geocode data from google maps and injects it into the listing', (done) ->
      listings.gm = { geocode: sinon.stub() }
      listings.geocode { location: { name: 'foobar' } }, (err, listing) ->
        listing.location.formatted_address.should.equal(
          '245 East 124th Street, New York, NY 10035, USA'
        )
        listing.location.lng.should.equal -73.934573
        listing.location.lat.should.equal 40.802391
        listing.location.neighborhood.should.equal 'East Harlem'
        done()
      listings.gm.geocode.args[0][0].should.equal 'foobar'
      listings.gm.geocode.args[0][1] null,
        results: [
            address_components: [
              long_name: "East Harlem"
              short_name: "East Harlem"
              types: ["neighborhood", "political"]
            ]
            formatted_address: "245 East 124th Street, New York, NY 10035, USA"
            geometry:
              location:
                lat: 40.802391
                lng: -73.934573
          ]