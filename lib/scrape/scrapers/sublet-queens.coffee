_ = require 'underscore'
Scraper = require '../scraper'

module.exports = new Scraper _.extend require('./sublet-manhattan').opts,
  listUrl: (page) ->
    "http://www.sublet.com/city_rentals/queens_rentals.asp?sortby=posted_down&apt_share=private&page=#{page}"