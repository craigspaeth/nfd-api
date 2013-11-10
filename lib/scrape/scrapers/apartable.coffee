Scraper = require '../scraper'
accounting = require 'accounting'

module.exports = new Scraper
  startPage: 1
  listingsPerPage: 28
  listUrl: (page) ->
    "http://apartable.com/apartments?broker_fee=false&city=New+York" +
    "&page=#{page}&state=NY&utf8=%E2%9C%93"
  listItemSelector: 'a.map-link'
  $ToListing: ($) ->
    return $('html').html() unless $('html').html().length > 30
    rent: accounting.unformat $('.price').text()
    beds: Scraper.parseBeds $('.bedrooms').text()
    baths: parseFloat($('.bathrooms').text().match(/[\.\d]* bath/i)) or null
    location: 
      name: $('#map-container h3').text()
    pictures: $('#galleria a').map(-> $(@).attr 'href').toArray()