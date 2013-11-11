{ parseBeds, parseBaths } = Scraper = require '../scraper'
accounting = require 'accounting'
_ = require 'underscore'
_.mixin require('underscore.string').exports()

module.exports = new Scraper
  engines: { list: 'request', item: 'request' }
  listUrl: (page) -> "http://www.pinemanagement.com/Listings/SearchListings"
  listItemSelector: '.resultitem-name a'
  $ToListing: ($) ->
    rent: accounting.unformat _.trim $('#blockcenter .desc:first-of-type strong').text().split('\n')[1]
    beds: parseBeds _.trim $('#blockcenter .desc:first-of-type strong').text().split('\n')[2]
    baths: parseBaths _.trim $('#blockcenter .desc:first-of-type strong').text().split('\n')[3]
    location: 
      name: _.clean $('.listingheader').text()
    pictures: $('#thumbs_carousel a').map(-> $(@).attr "href").toArray()