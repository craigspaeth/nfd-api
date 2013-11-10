{ parseBeds, parseBaths } = Scraper = require '../scraper'
accounting = require 'accounting'
_ = require 'underscore'
_.mixin require('underscore.string').exports()

module.exports = new Scraper
  startPage: 0
  listingsPerPage: 200
  engines: { list: 'request', item: 'zombie' }
  listUrl: (page) -> "http://www.sspny.com/availabilities"
  listItemSelector: '#listings a'
  $ToListing: ($) ->
    rent: accounting.unformat _.trim $('.detail_extra .apt_info table tbody tr:first-child')
                                     .text().replace('Rent:', '').replace('/mo', '')
    beds: parseBeds _.trim $('.detail_extra .apt_info table tbody tr:nth-child(3)')
                           .text().replace('Bedrooms:', '')
    baths: parseInt _.trim $('.detail_extra .apt_info table tbody tr:nth-child(4)')
                           .text().replace('Baths:', '')
    location: 
      name: _.clean $('.detail_extra .apt_info table tbody tr:nth-child(2)')
                    .text().replace('Building:', '')
    pictures: $('#featured img').map(-> $(@).attr "src").toArray()