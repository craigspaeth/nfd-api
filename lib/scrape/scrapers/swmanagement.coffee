accounting = require 'accounting'
_ = require 'underscore'
_.mixin require('underscore.string').exports()
{ parse } = require 'querystring'
{ parseBeds, parseBaths } = Scraper = require '../scraper'

class SWScraper extends Scraper

  $toListingUrls: ($) ->
    @samePagesCount = 3
    $('#mytable tr').map(->
      "http://www.swmanagement.com/aspsite/unitDetails.aspx?aid=#{$(@).attr 'aid'}"
    ).toArray()

module.exports = new SWScraper
  engines: { list: 'request', item: 'request' }
  listUrl: (page) ->
    "http://www.swmanagement.com/aspsite/PropertyListings.aspx"
  $ToListing: ($) ->
    rent: accounting.unformat _.trim $('#ctl00_ContentPlaceHolder2_priceLbl').text()
    beds: parseBeds $('#ctl00_ContentPlaceHolder2_bedLbl').text()
    baths: parseInt $('#ctl00_ContentPlaceHolder2_bathLbl').text()
    location:
      name: $('#ctl00_ContentPlaceHolder2_bldAddress').text()
    pictures: $('#galleria img').map(->
      $(@).attr('src').replace '../', 'http://www.swmanagement.com/'
    ).toArray()