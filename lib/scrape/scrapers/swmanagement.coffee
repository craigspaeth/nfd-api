return
{ parseBeds, parseBaths } = Scraper = require '../scraper'
accounting = require 'accounting'
_ = require 'underscore'
_.mixin require('underscore.string').exports()
{ parse } = require 'querystring'

opts =
  engines: { list: 'request', item: 'request' }
  listUrl: (page) ->
    "http://www.swmanagement.com/index.php?location_or%5B%5D=&price-min=&price-max=&action=searchresults&pclass%5B%5D="
  listItemSelector: '.result_row_0 td:first-child a, .result_row_1 td:first-child a'
  $ToListing: ($) ->
    rent: accounting.unformat $('table[width="570"] tr td:first-of-type').html()?.match(/\$.*/)[0]
    beds: parseBeds $('table[width="570"] tr td:first-of-type').html()?.match(/bed.*:(.*)/)[1]
    baths: parseInt $('table[width="570"] tr td:first-of-type').html()?.match(/bath.*nbsp;(.*)/)[1]
    location:
      name: _.clean $('.color4b4b4b:first-of-type').html()
    pictures: _.select($('img').map(->
      if $(this).attr('src')?.match('jpg') then $(this).attr('src') else null
    ).toArray(), (val) -> val?)

module.exports = new Scraper opts

module.exports.opts = opts