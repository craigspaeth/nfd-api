accounting = require 'accounting'
_ = require 'underscore'
_.mixin require('underscore.string').exports()
{ parseBeds, parseBaths } = Scraper = require '../scraper'
request = require 'superagent'

class UCScraper extends Scraper

  fetchListingUrls: (page, callback) ->
    str = "json=%7B%22neighborhoods%22%3A%5B%5D%2C%22min_price%22%3A%22%22%2C%22max_price%22%3A%22%22%2C%22bedrooms%22%3A%5B%5D%2C%22min_bathrooms%22%3A%221%22%2C%22features%22%3A%5B%5D%2C%22fee_types%22%3A%5B%5D%2C%22min_square_footage%22%3A0%2C%22max_monthly_fees%22%3A0%2C%22listingTypes%22%3A%5B0%5D%2C%22pets%22%3A%5B%5D%2C%22extra%22%3A%5B%5D%2C%22order%22%3A5%2C%22start%22%3A#{page * 10}%2C%22num%22%3A10%2C%22max_date_available%22%3A%22%22%2C%22exclusives%22%3Afalse%2C%22history_days%22%3A%220%22%2C%22min_rating%22%3A0%2C%22includedFilters%22%3A%5B%5D%2C%22debug_options%22%3A%7B%22listingTypes%22%3A%220%22%2C%22tileSize%22%3A512%7D%7D"
    request
      .post('https://www.urbancompass.com/api/search/listings/')
      .set('Content-Length', str.length)
      .send(str)
      .end (res) ->
        return callback res.error if res.error
        urls = (for listing in res.body.response.listings
          "https://www.urbancompass.com/listing/#{listing.id}/view"
        )
        callback null, urls

module.exports = new UCScraper
  engines: { list: 'request', item: 'request' }
  listUrl: -> 'http://www.urbancompass.com'
  $ToListing: ($) ->
    rent: accounting.unformat _.trim $('.pill__section__figure').eq(2).text()
    beds: parseBeds $('.pill__section__figure').eq(0).text()
    baths: parseInt _.clean $('.pill__section__figure').eq(1).text()
    location:
      name: _.clean $('.listing--header').text()
    pictures: $('#slideshow img').map(-> $(@).attr('src')).toArray()