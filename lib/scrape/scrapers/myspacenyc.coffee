return

{ parseBeds, parseBaths } = Scraper = require '../scraper'
accounting = require 'accounting'
_ = require 'underscore'
_.mixin require('underscore.string').exports()

module.exports = new Scraper
  engines: { list: 'zombie', item: 'zombie' }
  listUrl: (page) -> "http://www.myspacenyc.com/results?page=#{page}"
  listItemSelector: '.listing dd:first-child a'
  zombieOpts: { runScripts: true }
  $ToListing: ($) ->
    rent: accounting.unformat $('.leftWrap dl:nth-child(3) dd')[0].innerText.replace(' ', '')
    beds: parseBeds _.trim $('.leftWrap dl:first-child dd')[0].innerText
    baths: parseBaths _.trim $('.leftWrap dl:first-child dd')[1].innerText
    location: 
      name: _.clean $('#rightcolumn .stats tr:nth-child(1)').text()
    pictures: $('ul.thumbs img').map(-> $(@).attr "src").toArray()