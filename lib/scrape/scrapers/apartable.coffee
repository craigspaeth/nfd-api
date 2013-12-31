Scraper = require '../scraper'
accounting = require 'accounting'

module.exports = new Scraper
  engines: { list: 'request', item: 'request' }
  listUrl: (page) ->
    "http://apartable.com/apartments?broker_fee=false&city=New+York" +
    "&page=#{page}&state=NY&utf8=%E2%9C%93"
  listItemSelector: 'a.map-link'
  $ToListing: ($) ->
    rent: accounting.unformat $('.price').text()
    beds: Scraper.parseBeds $('.bedrooms').text()
    baths: parseFloat($('.bathrooms').text().match(/[\.\d]* bath/i)) or null
    location: 
      name: $('#map-container h3').text()
    pictures: $('#galleria a').map(-> $(@).attr 'href').toArray()