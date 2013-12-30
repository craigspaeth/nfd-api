{ parseBeds, parseBaths } = Scraper = require '../scraper'
accounting = require 'accounting'
_ = require 'underscore'
_.mixin require('underscore.string').exports()

module.exports = new Scraper
  engines: { list: 'request', item: 'request' }
  useProxy: true
  listUrl: (page) ->
    "http://www.nybits.com/search/?_a%21process=" + 
    "y&_rid_=3&_ust_todo_=65733&_xid_=" +
    "aaLx8ms445ZfSq-1377828951&%21%21rmin=&%21%21rmax=&%21%21fee=nofee&%21%21orderby=" + 
    "dateposted&submit=+SHOW+RENTAL+APARTMENTS+&!!_magic%3APrefix!_search_start%3D#{page * 200}="
  listItemSelector: '[colspan="3"] a'
  $ToListing: ($) ->
    rent: accounting.unformat _.trim $("#capsuletable tr:nth-child(2)").text().replace('Rent:', '')
    beds: parseBeds $("#capsuletable tr:nth-child(1)").text().replace('Layout:', '')
    baths: null
    location:
      name: _.clean $("#capsuletable tr:nth-child(7)").text().replace('Building:', '')
    pictures: $('.photocolumntitle').nextAll('img').map(-> $(@).attr 'src').toArray()