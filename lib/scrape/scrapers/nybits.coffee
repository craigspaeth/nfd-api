Scraper = require '../scraper'
accounting = require 'accounting'

module.exports = new Scraper
  startPage: 0
  listingsPerPage: 200
  zombieOpts: { runScripts: false }
  listUrl: (page) ->
    "http://www.nybits.com/search/?_a%21process=" + 
    "y&_rid_=3&_ust_todo_=65733&_xid_=" +
    "aaLx8ms445ZfSq-1377828951&%21%21rmin=&%21%21rmax=&%21%21fee=nofee&%21%21orderby=" + 
    "dateposted&submit=+SHOW+RENTAL+APARTMENTS+&!!_magic%3APrefix!_search_start%3D#{page * 200}="
  listItemSelector: '[colspan="3"] a'
  $ToListing: ($) ->
    return $('html').html() unless $('html').html().length > 30
    rent = $("#capsuletable tr").filter( -> 
           $(@).find("td:eq(0)").text().match /Rent/).find("td:eq(1)").text()
    layout = $("#capsuletable tr").filter( -> 
             $(@).find("td:eq(0)").text().match /Layout/).find("td:eq(1)").text()
    building = $("#capsuletable tr").filter( -> 
               $(@).find("td:eq(0)").text().match /Building/).find("td:eq(1)").text()
    {
      rent: accounting.unformat(rent)
      beds: parseFloat(if layout.match /studio/i then 0 else layout) or null
      baths: null
      location:
        name: _.clean(building)
      pictures: $('.photocolumntitle').nextAll('img').map(-> $(@).attr 'src').toArray()
    }