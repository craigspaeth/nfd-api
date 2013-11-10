Scraper = require '../scraper'
accounting = require 'accounting'

module.exports = new Scraper
  startPage: 0
  listingsPerPage: 10
  listUrl: (page) ->
    "http://www.urbanedgeny.com/results?page=#{page}&nh1=90&p[min]=&p[max]=&bd=&ba="
  listItemSelector: '.property-title a'
  $ToListing: ($) ->
    return $('html').html() unless $('html').html().length > 30
    rent: accounting.unformat $('#listing-overview > div:first-child').text()
    beds: Scraper.parseBeds $('#listing-overview').text()
    baths: parseFloat($('#listing-overview').text().match(/[\.\d]* bath/i)) or null
    location: 
      name: _.clean($('.address-block').text())
    pictures: $('#slide-runner a').map(->
      "http://www.urbanedgeny.com" + $(@).attr 'href').toArray()