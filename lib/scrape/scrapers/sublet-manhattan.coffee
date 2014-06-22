{ parseBeds, parseBaths } = Scraper = require '../scraper'
accounting = require 'accounting'
_ = require 'underscore'
_.mixin require('underscore.string').exports()
{ parse } = require 'querystring'

opts =
  engines: { list: 'request', item: 'request' }
  listUrl: (page) ->
    "http://www.sublet.com/city_rentals/manhattan_rentals.asp?sortby=posted_down&apt_share=private&page=#{page}"
  listItemSelector: 'a[href^="http://www.sublet.com/spider/supplydetails.asp?supplyid"]'
  $ToListing: ($) ->
    daily = $('.headerfontsmall').text().match(/(.*)\/day/)?[1].replace('&nbsp;','')
    weekly = $('.headerfontsmall').text().match(/(.*)\/week/)?[1].replace('&nbsp;','')
    monthly = $('.headerfontsmall').text().match(/(.*)\/month/)?[1].replace('&nbsp;','')
    rent = if monthly
             parseInt(monthly)
           else if weekly
             parseInt(weekly) * 4
           else if daily
             parseInt(daily) * 30
           else
             null
    {
      rent: rent
      beds: parseBeds $(".details.font10 tr").first().text()
      baths: parseBaths $(".details.font10 tr").first().text()
      location:
        name: _.clean $('h1 b').text()
      pictures: $('#myGallery img').map(-> $(@).attr 'src').toArray()
    }

module.exports = new Scraper opts

module.exports.opts = opts