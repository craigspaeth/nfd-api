{ parseBeds, parseBaths } = Scraper = require '../scraper'
accounting = require 'accounting'
_ = require 'underscore'
_.mixin require('underscore.string').exports()

module.exports = new Scraper
  engines: { list: 'request', item: 'request' }
  listUrl: (page) -> 
    "http://streeteasy.com/no-fee-rentals/nyc"
  listItemSelector: '.details_title a'
  $ToListing: ($) ->
    rent: accounting.unformat _.trim $('.price').first().text().replace('for rent', '')
    beds: parseBeds $('.details_info').first().text()
    baths: parseBaths $('.details_info').first().text()
    location: 
      name: _.trim $('h1').text()
    pictures: $('#gallery_images img').map(-> $(@).attr 'src').toArray()