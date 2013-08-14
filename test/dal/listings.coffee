listings = require '../../dal/listings'
sinon = require 'sinon'
collectionStub = require '../helpers/collection_stub'
_ = require 'underscore'

describe 'listings', ->
  
  beforeEach ->
    listings.collection = collectionStub()
      
  describe "#find", ->
    
    it 'limits by beds', ->
      listings.find(bed_min: 2)
      listings.collection.find.args[0][0].beds["$gte"].should.equal 2
    
    it 'limits by baths', ->
      listings.find(bath_min: 2)
      listings.collection.find.args[0][0].baths["$gte"].should.equal 2
    
    it 'limits by rent', ->
      listings.find(rent_max: 2000)
      listings.collection.find.args[0][0].rent["$lte"].should.equal 2000
    
  describe '#upsert', ->
    
    it 'upserts restricting to urls', ->
      listings.upsert [{ url: 'foo', foo: 'foo' }, {  url: 'bar', bar: 'foo' }]
      listings.collection.update.args[0][0].url.should.equal 'foo'
      listings.collection.update.args[1][0].url.should.equal 'bar'
      
    it 'upserts each document', ->
      listings.upsert [{ url: 'foo', foo: 'foo' }, {  url: 'bar', bar: 'foo' }]
      listings.collection.update.calledTwice.should.be.ok
    
    it 'updates the passed info', ->
      listings.upsert [{ url: 'foo', foo: 'foo' }, {  url: 'bar', bar: 'bar' }]
      listings.collection.update.args[0][1].foo.should.equal 'foo'
      listings.collection.update.args[1][1].bar.should.equal 'bar'
  
  describe '#geocode', ->
    
    beforeEach ->
      listings.collection.update.callsArgWith 3, null
    
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
    
    it 'errs on listings without location names', (done) ->
      listings.geocode { location: {} }, (err) ->
        (err?).should.be.ok
        done()
      
    it 'errs if there are no results', (done) ->
      listings.gm = { geocode: sinon.stub() }
      listings.gm.geocode.callsArgWith 1, { status: 'ZERO RESULTS' }
      listings.geocode { location: { name: 'foobar' } }, (err, listing) ->
        (err?).should.be.ok
        done()
        
  describe '#findNeighborhoods', ->
    
    it 'distincts the neighborhoods and returns the results', (done) ->
      listings.collection.distinct.callsArgWith 1, null, ['foo', 'bar']
      listings.findNeighborhoods (err, results) ->
        results[0].should.equal 'bar'
        results[1].should.equal 'foo'
        done()
      
    it 'ignores null neighborhoods', (done) ->
      listings.collection.distinct.callsArgWith 1, null, ['foo', 'bar', null]
      listings.findNeighborhoods (err, results) ->
        results.length.should.equal 2
        done()
      
    it 'sorts alphabetically', (done) ->
      listings.collection.distinct.callsArgWith 1, null, ['a', 'd', 'c', 'b']
      listings.findNeighborhoods (err, results) ->
        results.join('').should.equal 'abcd'
        done()