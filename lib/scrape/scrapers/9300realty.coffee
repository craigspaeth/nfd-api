{ parseBeds, parseBaths } = Scraper = require '../scraper'
accounting = require 'accounting'
_ = require 'underscore'
_.mixin require('underscore.string').exports()

module.exports = new Scraper
  startPage: 0
  listingsPerPage: 200
  listUrl: (page) -> "http://www.9300realty.com/index.cfm?page=allRentals"
  listItemSelector: '.dspListings2Elements > a:first-child'
  $ToListing: ($) ->
    return $('html').html() unless $('html').html().length > 30
    rent: accounting.unformat _.trim $('.innerRight:nth-child(3) .essentials:nth-child(6)').text()
    beds: parseBeds $('.innerRight:nth-child(3) .essentials:nth-child(4)').text().replace('Bedrooms: ', '')
    baths: parseInt $('.innerRight:nth-child(3) .essentials:nth-child(5)').text().replace('Bathrooms: ', '')
    location: 
      name: _.clean ($('.dspBreadCrumbs > a:nth-child(3)').text() + 
            $('.innerRight:nth-child(3) .essentials:nth-child(2)').text()).replace('Area:', '')
    pictures: $(".thumb a").map(-> $(@).attr "href").toArray()