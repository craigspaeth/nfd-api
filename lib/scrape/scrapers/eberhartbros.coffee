{ parseBeds, parseBaths } = Scraper = require '../scraper'
accounting = require 'accounting'
_ = require 'underscore'
_.mixin require('underscore.string').exports()
{ parse } = require 'querystring'

opts =
  engines: { list: 'request', item: 'request' }
  listUrl: (page) ->
    "http://www.eberhartbros.com/search_results.php?" +
    "search=standard&sorter=dateavail_year,dateavail_month,dateavail_day" + 
    "&locationid=&lowprice=0&highprice=4294967295&numbedrooms="
  listItemSelector: '.results a'
  $ToListing: ($) ->
    rent: accounting.unformat _.trim $('table[width="300px"] tr:nth-child(2) td:nth-child(2)').text()
    beds: parseInt $('table[width="300px"] tr:nth-child(3) td:nth-child(2)').text()
    baths: parseInt $('table[width="300px"] tr:nth-child(4) td:nth-child(2)').text()
    location:
      name: _.clean $('span[style="font-size:1em; font-weight:bold; color:#048a7a;"]').text()
    pictures: $('#gallery li a').map(-> $(@).attr 'href').toArray()

module.exports = new Scraper opts

module.exports.opts = opts