accounting = require 'accounting'
_ = require 'underscore'
_.mixin require('underscore.string').exports()
{ parse } = require 'querystring'
{ parseBeds, parseBaths } = Scraper = require '../scraper'

class NFRScraper extends Scraper

  $toListingUrls: ($) ->
    @samePagesCount = 3
    $('[bgcolor="#ffffff"] td:nth-child(2) a').map(->
      $(this).attr('href')
    ).toArray()

module.exports = new NFRScraper
  engines: { list: 'request', item: 'request' }
  listUrl: (page) ->
    "http://www.nofeerentals.com/apartments.asp"
  $ToListing: ($) ->
    beds = Math.ceil(parseFloat($('[bordercolor="#000000"]').eq(1).find('tr').eq(7).find('td').eq(2).text()))
    { 
      rent: accounting.unformat _.trim $('[bordercolor="#000000"]').eq(1).find('tr').eq(6).find('td').eq(2).text()
      beds: (beds - 2)
      baths: parseInt $('[bordercolor="#000000"]').eq(1).find('tr').eq(8).find('td').eq(2).text()
      location:
        name: $('[bordercolor="#000000"]').eq(1).find('tr').eq(4).find('td').eq(2).text()
      pictures: $('#galleria img').map(->
        $('[bordercolor="pink"] img').attr('src')
      ).toArray()
    }