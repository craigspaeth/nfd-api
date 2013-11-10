Scraper = require '../scraper'
accounting = require 'accounting'

module.exports = new Scraper
  startPage: 1
  listingsPerPage: 22
  listUrl: (page) -> "http://www.renthop.com/search?features%5B%5D=No+Fee&page=#{page}"
  listItemSelector: '#resultsList .pictures > a'
  $ToListing: ($) ->
    return $('html').html() unless $('html').html().length > 30
    rent: accounting.unformat $('.listingHeading span:first strong').html()
    beds: Scraper.parseBeds $('.listingHeading').text()
    baths: parseFloat($('.listingHeading').html().match(/[\.\d]* bath/i))
    location:
      name: $('.listingHeading h1').text().match(/at(.*) for/)[1]
    pictures: $('#photoSlider a').map(-> $(@).attr 'href').toArray()