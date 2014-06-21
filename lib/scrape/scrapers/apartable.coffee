Scraper = require '../scraper'
accounting = require 'accounting'

module.exports = new Scraper
  engines: { list: 'request', item: 'request' }
  listUrl: (page) ->
    "http://apartable.com/search?utf8=%E2%9C%93&q=New+York%2C+NY%2C+USA&min_price=&max_price=" +
    "&broker_fee=false&available_date=&state=NY&city=New+York&lat=40.7127837&lng=-74.00594130000002"
  listItemSelector: 'a.map-link'
  $ToListing: ($) ->
    rent: accounting.unformat $('.price').text()
    beds: Scraper.parseBeds $('.bedrooms').text()
    baths: parseFloat($('.bathrooms').text().match(/[\.\d]* bath/i)) or null
    location: 
      name: $('#map-container h3').text()
    pictures: $('#galleria a').map(-> $(@).attr 'href').toArray()