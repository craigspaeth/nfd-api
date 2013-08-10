{ check } = require 'validator'
_ = require 'underscore'
streeteasy = require '../../lib/scrapers/streeteasy'

describe 'streeteasy scaper', ->
  
  beforeEach ->
    @upsertStub = (@listings, callback) => callback()
    streeteasy.dal = { listings: { upsert: @upsertStub } }
  
  describe '#scrapePage', ->
  
    it 'upserts some scraped data from street easy', (done) ->
      streeteasy.scrapePage 1, => 
        @listings[0].rent.should.be.above 100
        @listings[0].beds.should.be.above 0
        @listings[0].baths.should.be.above 0
        (typeof @listings[0].location.name).should.equal 'string'
        check(@listings[0].url).isUrl()
        check(@listings[0].pictures[0]).isUrl()
        done()