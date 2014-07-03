Listings = require '../../dal/listings'
sinon = require 'sinon'
collectionStub = require '../helpers/collection-stub'
_ = require 'underscore'

describe 'listings', ->
  
  beforeEach ->
    Listings.collection = collectionStub()
      
  describe "#find", ->
    
    it 'limits by beds', ->
      Listings.find('bed-min': 2)
      Listings.collection.find.args[0][0].beds["$gte"].should.equal 2
    
    it 'limits by baths', ->
      Listings.find('bath-min': 2)
      Listings.collection.find.args[0][0].baths["$gte"].should.equal 2
    
    it 'limits by rent', ->
      Listings.find('rent-max': 2000)
      Listings.collection.find.args[0][0].rent["$lte"].should.equal 2000
      
    it 'limits by size', ->
      Listings.find(size: 10, page: 1)
      Listings.collection.limit.args[0][0].should.equal 10
      
    it 'accepts page params', ->
      Listings.find(size: 10, page: 1)
      Listings.collection.skip.args[0][0].should.equal 10
      
    it 'filters by neighborhoods', ->
      Listings.find(neighborhoods: ['bar', 'foo'])
      _.isEqual(
        Listings.collection.find.args[0][0]['location.neighborhood']
        { $in: ['bar', 'foo'] }
      ).should.be.ok
      
    it 'sorts by rent', ->
      Listings.find(sort: 'rent')
      Listings.collection.sort.args[0][0].rent.should.equal 1
    
    it 'sorts by size', ->
      Listings.find(sort: 'size')
      Listings.collection.sort.args[0][0].beds.should.equal -1
      Listings.collection.sort.args[0][0].baths.should.equal -1
    
    it 'sorts by newest listings', ->
      Listings.find(sort: 'newest')
      Listings.collection.sort.args[0][0].dateScraped.should.equal -1

    it 'can pull the latest listings', ->
      Listings.find 'date-scraped-start': new Date()
      Listings.collection.find.args[0][0].dateScraped.$gte.toString()
        .should.equal new Date().toString()
  
  describe '#count', ->
    
    it 'counts listings by params', ->
      Listings.count('bed-min': 2)
      Listings.collection.count.args[0][0].beds["$gte"].should.equal 2
  
  describe '#upsert', ->
    
    it 'upserts restricting to urls', ->
      Listings.upsert [{ url: 'foo', foo: 'foo' }, {  url: 'bar', bar: 'foo' }]
      Listings.collection.update.args[0][0].url.should.equal 'foo'
      Listings.collection.update.args[1][0].url.should.equal 'bar'
      
    it 'upserts each document', ->
      Listings.upsert [{ url: 'foo', foo: 'foo' }, {  url: 'bar', bar: 'foo' }]
      Listings.collection.update.calledTwice.should.be.ok
    
    it 'updates the passed info', ->
      Listings.upsert [{ url: 'foo', foo: 'foo' }, {  url: 'bar', bar: 'bar' }]
      Listings.collection.update.args[0][1].foo.should.equal 'foo'
      Listings.collection.update.args[1][1].bar.should.equal 'bar'
  
  describe '#geocode', ->
    
    beforeEach ->
      Listings.collection.update.callsArgWith 3, null
    
    it 'stores dateGeocoded', (done) ->
      Listings.gm = { geocode: sinon.stub() }
      Listings.geocode { location: { name: 'foobar' } }, (err, listing) ->
        listing.dateGeocoded.toString().should.containEql new Date().getFullYear()
        done()
      Listings.gm.geocode.args[0][0].should.equal 'foobar'
      Listings.gm.geocode.args[0][1] null,
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
      Listings.gm = { geocode: sinon.stub() }
      Listings.geocode { location: { name: 'foobar' } }, (err, listing) ->
        listing.location.formattedAddress.should.equal(
          '245 East 124th Street, New York, NY 10035, USA'
        )
        listing.location.lng.should.equal -73.934573
        listing.location.lat.should.equal 40.802391
        listing.location.neighborhood.should.equal 'East Harlem'
        done()
      Listings.gm.geocode.args[0][0].should.equal 'foobar'
      Listings.gm.geocode.args[0][1] null,
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
      Listings.gm = { geocode: sinon.stub() }
      Listings.gm.geocode.callsArgWith 1, { status: 'ZERO RESULTS' }
      Listings.geocode { location: { name: 'foobar' } }, (err, listing) ->
        (err?).should.be.ok
        done()
        
    it 'does not geocode non-new york cities', (done) ->
      Listings.gm = { geocode: sinon.stub() }
      Listings.geocode { location: { name: 'foobar' } }, (err, listing) ->
        listing.location.formattedAddress.should.equal 'Kewl York, New York, NY'
        done()
      Listings.gm.geocode.args[0][1] null,
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
      Listings.collection.distinct.callsArgWith 1, null, ['foo', 'bar']
      Listings.findNeighborhoods (err, groups) ->
        groups['Other'][0].should.equal 'bar'
        groups['Other'][1].should.equal 'foo'
        done()
      
    it 'ignores null neighborhoods', (done) ->
      Listings.collection.distinct.callsArgWith 1, null, ['foo', 'bar', null]
      Listings.findNeighborhoods (err, groups) ->
        groups['Other'].length.should.equal 2
        done()
      
    it 'sorts alphabetically', (done) ->
      Listings.collection.distinct.callsArgWith 1, null, ['a', 'd', 'c', 'b']
      Listings.findNeighborhoods (err, groups) ->
        groups['Other'].join('').should.equal 'abcd'
        done()
        
    it 'groups neighborhoods into their proper larger groups', (done) ->
      Listings.collection.distinct.callsArgWith 1, null, ['UES', 'Clinton Hill']
      Listings.findNeighborhoods (err, groups) ->
        groups['South Brooklyn'][0].should.equal 'Clinton Hill'
        groups['Uptown'][0].should.equal 'UES'
        done()
        
  describe '#countBad', ->
    
    it 'counts the number of bad listings', (done) ->
      Listings.countBad (err, badCount, total) ->
        badCount.should.equal 50
        total.should.equal 100
        done()
      Listings.collection.count.args[0][0] null, 100
      Listings.collection.count.args[1][1] null, 50

  describe '#badDataHash', ->

    it 'scans the database and maps it into a hash of bad data easy to parse'
    it 'splits the scraper name by a dash so it handles the nytimes-newyork scrapers'