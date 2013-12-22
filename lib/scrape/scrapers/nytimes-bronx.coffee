_ = require 'underscore'
Scraper = require '../scraper'

module.exports = new Scraper _.extend require('./nytimes-newyork').opts,
  listUrl: (page) ->
    "http://realestate.nytimes.com/rentals/bronx-ny-usa/" + 
    "NO-FEE-pf/NEW-LISTINGS-sort/#{page * 10}-p"