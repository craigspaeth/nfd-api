listings = require '../../dal/listings'
sinon = require 'sinon'
collectionStub = require '../helpers/collection-stub'
_ = require 'underscore'

describe 'listings', ->
  
  beforeEach ->
    listings.collection = collectionStub()
      
  describe "#find", ->
    
    it 'limits by beds', ->
      listings.find('bed-min': 2)
      listings.collection.find.args[0][0].beds["$gte"].should.equal 2
    
    it 'limits by baths', ->
      listings.find('bath-min': 2)
      listings.collection.find.args[0][0].baths["$gte"].should.equal 2
    
    it 'limits by rent', ->
      listings.find('rent-max': 2000)
      listings.collection.find.args[0][0].rent["$lte"].should.equal 2000
      
    it 'limits by size', ->
      listings.find(size: 10, page: 1)
      listings.collection.limit.args[0][0].should.equal 10
      
    it 'accepts page params', ->
      listings.find(size: 10, page: 1)
      listings.collection.skip.args[0][0].should.equal 10
      
    it 'filters by neighborhoods', ->
      listings.find(neighborhoods: ['bar', 'foo'])
      _.isEqual(
        listings.collection.find.args[0][0]['location.neighborhood']
        { $in: ['bar', 'foo'] }
      ).should.be.ok
      
    it 'sorts by rent', ->
      listings.find(sort: 'rent')
      listings.collection.sort.args[0][0].rent.should.equal 1
    
    it 'sorts by size', ->
      listings.find(sort: 'size')
      listings.collection.sort.args[0][0].beds.should.equal -1
      listings.collection.sort.args[0][0].baths.should.equal -1
    
    it 'sorts by newest listings', ->
      listings.find(sort: 'newest')
      listings.collection.sort.args[0][0].dateScraped.should.equal -1
  
  describe '#count', ->
    
    it 'counts listings by params', ->
      listings.count('bed-min': 2)
      listings.collection.count.args[0][0].beds["$gte"].should.equal 2
  
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
    
    it 'stores dateGeocoded', (done) ->
      listings.gm = { geocode: sinon.stub() }
      listings.geocode { location: { name: 'foobar' } }, (err, listing) ->
        listing.dateGeocoded.toString().should.containEql new Date().getFullYear()
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
    
    it 'fetches the geocode data from google maps and injects it into the listing', (done) ->
      listings.gm = { geocode: sinon.stub() }
      listings.geocode { location: { name: 'foobar' } }, (err, listing) ->
        listing.location.formattedAddress.should.equal(
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

    it 'errs if there are no results', (done) ->
      listings.gm = { geocode: sinon.stub() }
      listings.gm.geocode.callsArgWith 1, { status: 'ZERO RESULTS' }
      listings.geocode { location: { name: 'foobar' } }, (err, listing) ->
        (err?).should.be.ok
        done()
        
    it 'does not geocode non-new york cities', (done) ->
      listings.gm = { geocode: sinon.stub() }
      listings.geocode { location: { name: 'foobar' } }, (err, listing) ->
        listing.location.formattedAddress.should.equal 'Kewl York, New York, NY'
        done()
      listings.gm.geocode.args[0][1] null,
        results: [
            {
              address_components: []
              formatted_address: "245 East 124th Street, Cincinnati OH"
            }
            {
              address_components: [
                long_name: "East Harlem"
                short_name: "East Harlem"
                types: ["neighborhood", "political"]
              ]
              formatted_address: "Kewl York, New York, NY"
              geometry:
                location:
                  lat: 40.802391
                  lng: -73.934573             
            }
            {
              address_components: []
              formatted_address: "245 East 124th Street, Cincinnati OH"
            }
          ]
        
  describe '#findNeighborhoods', ->
    
    it 'distincts the neighborhoods and returns the results', (done) ->
      listings.collection.distinct.callsArgWith 1, null, ['foo', 'bar']
      listings.findNeighborhoods (err, groups) ->
        groups['Other'][0].should.equal 'bar'
        groups['Other'][1].should.equal 'foo'
        done()
      
    it 'ignores null neighborhoods', (done) ->
      listings.collection.distinct.callsArgWith 1, null, ['foo', 'bar', null]
      listings.findNeighborhoods (err, groups) ->
        groups['Other'].length.should.equal 2
        done()
      
    it 'sorts alphabetically', (done) ->
      listings.collection.distinct.callsArgWith 1, null, ['a', 'd', 'c', 'b']
      listings.findNeighborhoods (err, groups) ->
        groups['Other'].join('').should.equal 'abcd'
        done()
        
    it 'groups neighborhoods into their proper larger groups', (done) ->
      listings.collection.distinct.callsArgWith 1, null, ['UES', 'Clinton Hill']
      listings.findNeighborhoods (err, groups) ->
        groups['South Brooklyn'][0].should.equal 'Clinton Hill'
        groups['Uptown'][0].should.equal 'UES'
        done()
        
  describe '#countBad', ->
    
    it 'counts the number of bad listings', (done) ->
      listings.countBad (err, badCount, total) ->
        badCount.should.equal 50
        total.should.equal 100
        done()
      listings.collection.count.args[0][0] null, 100
      listings.collection.count.args[1][1] null, 50

  describe '#badDataHash', ->

    it 'scans the database and maps it into a hash of bad data easy to parse'
    it 'splits the scraper name by a dash so it handles the nytimes-newyork scrapers'