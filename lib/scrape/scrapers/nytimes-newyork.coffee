{ parseBeds, parseBaths } = Scraper = require '../scraper'
accounting = require 'accounting'
_ = require 'underscore'
_.mixin require('underscore.string').exports()
{ parse } = require 'querystring'

opts =
  engines: { list: 'request', item: 'request' }
  listUrl: (page) ->
    "http://realestate.nytimes.com/rentals/new-york-ny-usa/" + 
    "NO-FEE-pf/NEW-LISTINGS-sort/#{page * 10}-p"
  listItemSelector: '.property-title a'
  $ToListing: ($) ->
    rent: accounting.unformat _.trim $('#detail-info > h3 > span:first-child').text()
    beds: parseBeds $('.info:first-of-type li:first-child').text()
    baths: parseBaths $('.info:first-of-type li:nth-child(2)').text()
    location:
      name: _.clean $('.locality').text().split('Also')[0]
    pictures: _.uniq _.flatten(_.map($('html').html().match(/arrPhotos\.push.*/g), (text) ->
      (text.match(/http.*(jpg|jpeg)/i)[0].split("', '"))))

module.exports = new Scraper opts

module.exports.opts = opts