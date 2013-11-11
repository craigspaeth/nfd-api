{ parseBeds, parseBaths } = Scraper = require '../scraper'
accounting = require 'accounting'
_ = require 'underscore'
_.mixin require('underscore.string').exports()

detailPrefix = 'table[width="100%"][border="0"][align="center"]' +
               '[cellpadding="2"][cellspacing="2"][bordercolor="#000000"]'

module.exports = new Scraper
  engines: { list: 'request', item: 'request' }
  listUrl: (page) -> "http://www.nofeerentals.com/apartments.asp"
  listItemSelector: 'tr[bgcolor="#ffffff"] td:nth-child(2) a'
  $ToListing: ($) ->
    rent: accounting.unformat _.trim $("#{detailPrefix} tr:nth-child(5) td:nth-child(3)").text()
    beds: parseBeds _.trim $("#{detailPrefix} tr:nth-child(6) td:nth-child(3)").text()
    baths: parseInt _.trim $("#{detailPrefix} tr:nth-child(7) td:nth-child(3)").text()
    location:
      name: _.clean $("#{detailPrefix} tr:nth-child(2) td:nth-child(3) h2").text()
    pictures: $('[align=center][border="0"][bordercolor="pink"][cellspacing="2"]' + 
                '[cellpadding="0"][valign="top"][width="100%"] img').map(->
                  'http://www.nofeerentals.com' + $(@).attr 'src').toArray()