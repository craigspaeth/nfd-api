{ parseBeds, parseBaths } = Scraper = require '../scraper'
accounting = require 'accounting'
_ = require 'underscore'
_.mixin require('underscore.string').exports()

perPage = 8
bedMap =
  'One': 1
  'Two': 2
  'Three': 3
  'Four': 4
  'Five': 5

module.exports = new Scraper
  startPage: 0
  listingsPerPage: perPage
  listUrl: (page) ->
    "http://www.iconrealtymgmt.com/search?price=All&beds=All&location=All&visible=1&start=#{page * perPage}"
  listItemSelector: '.result-info a'
  $ToListing: ($) ->
    return $('html').html() unless $('html').html().length > 30
    rent: accounting.unformat $('#listing-other ul li:nth-child(1)')
                              .text().replace('Price: ', '').replace('/mo.', '')
    beds: bedMap[_.trim $('#listing-other ul li:nth-child(2)').text()
            .replace('Unit Type: ', '').replace(' Bedroom', '')]
    baths: parseInt $('#listing-other ul li:nth-child(3)').text().replace('Bathrooms: ', '')
    location: 
      name: $('#listing-location div:nth-child(2)').text() + ', ' + 
            $('#listing-location div:nth-child(4)').text()
    pictures: $('#listing-thumbnails a').map(-> $(@).attr "href").toArray()