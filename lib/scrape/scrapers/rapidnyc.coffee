return

{ parseBeds, parseBaths } = Scraper = require '../scraper'
accounting = require 'accounting'
_ = require 'underscore'
_.mixin require('underscore.string').exports()

module.exports = new Scraper
  engines: { list: 'zombie', item: 'zombie' }
  listUrl: (page) -> "http://www.rapidnyc.com/listings/search_results/page:#{page}/sort:ListingFee.rank/direction:asc"
  listItemSelector: '.resultRow > a'
  $ToListing: ($) ->
    rent: accounting.unformat _.trim $('.viewDetails tr:nth-child(1)').text().replace('Rent: ', '')
    beds: parseBeds $('.viewDetails tr:nth-child(2)').text().replace('Bedrooms: ', '')
    baths: parseBaths $('.viewDescriptionWrapper').text()
    location: 
      name: _.clean $('.viewDetails tr:nth-child(4)').text().replace('Neighborhood: ', '')
    pictures: $('.ps_nav li a').map(-> $(@).attr "href").toArray()