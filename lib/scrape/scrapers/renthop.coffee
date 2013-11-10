Scraper = require '../scraper'
accounting = require 'accounting'
_ = require 'underscore'
_.mixin require('underscore.string').exports()

module.exports = new Scraper
  startPage: 1
  listingsPerPage: 22
  engines: { list: 'request', item: 'request' }
  listUrl: (page) -> "http://www.renthop.com/search?features%5B%5D=No+Fee&page=#{page}"
  listItemSelector: '#resultsList .pictures > a'
  $ToListing: ($) ->
    return $('html').html() unless $('html').html().length > 30
    rent: accounting.unformat $('.listingHeading span:first-child strong').html()
    beds: parseBeds $('.listingHeading').text()
    baths: parseFloat($('.listingHeading').html().match(/[\.\d]* bath/i))
    location:
      name: _.clean $('.listingHeading h1').text()
                    .match(/at(.*)/i)[1].replace(/for.*/, '') + ', New York'
    pictures: $('#photoSlider a').map(-> $(@).attr 'href').toArray()