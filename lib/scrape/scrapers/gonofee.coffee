{ parseBeds, parseBaths } = Scraper = require '../scraper'
accounting = require 'accounting'
_ = require 'underscore'
_.mixin require('underscore.string').exports()

module.exports = new Scraper
  startPage: 0
  listingsPerPage: 200
  engines: { list: 'request', item: 'request' }
  listUrl: (page) -> "http://gonofee.com/Listings-no-fee-apartments/currentpage/#{page}.aspx"
  listItemSelector: '.RealEstateLink a'
  $ToListing: ($) ->
    rent: accounting.unformat _.trim $('#rightcolumn .stats tr:nth-child(5)')
                                     .text().replace('Monthly Rent', '')
    beds: parseBeds _.trim $('#rightcolumn .stats tr:nth-child(7)')
                            .text().replace('Bedrooms', '')
    baths: parseInt _.trim $('#rightcolumn .stats tr:nth-child(8)')
                            .text().replace('Bathrooms', '')
    location: 
      name: _.clean $('#rightcolumn .stats tr:nth-child(1)').text()
    pictures: $('#propertycontainer a').map(-> $(@).attr "href").toArray()