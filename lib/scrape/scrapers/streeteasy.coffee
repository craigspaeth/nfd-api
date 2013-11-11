Scraper = require '../scraper'
accounting = require 'accounting'

module.exports = new Scraper
  listUrl: (page) -> 
    "http://streeteasy.com/nyc/rentals/nyc/rental_type:frbo,brokernofee?" + 
    "page=#{page}&sort_by=listed_desc&lnf=old"
  listItemSelector: '.unsponsored .item.listing .body h3 a'
  editListingUrl: (url) -> url + '?lnf=old'
  $ToListing: ($) ->
    rent: accounting.unformat $('h1 .price').text()
    beds: Scraper.parseBeds $('.data').text()
    baths: parseFloat($('.data').text().match(/[\.\d]* bath/)) or null
    location: 
      name: $('h1 span').text()
    pictures: $('.photo.medium > a').map(-> $(@).attr 'href').toArray()