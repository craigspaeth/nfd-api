# 
# Creates a bunch of scrapers and is the CLI to run them.
# 

dal = require '../../dal'
Scraper = require './scraper'
accounting = require 'accounting'

scrapers =
  
  streeteasy: new Scraper
    listUrl: "http://streeteasy.com/nyc/rentals/nyc/rental_type:frbo,brokernofee?" + 
             "page={page}&sort_by=listed_desc"
    listItemSelector: '.unsponsored .item.listing .body h3 a'
    $ToListing: ($) ->
      data =
        rent: $('h1 .price').text()
        beds: $('.data p:last-child').text()
        baths: $('.data p:last-child').text()
        location: $('h1 span').text()
        pictures: $('.photo.medium > a').map((i, el) -> $(el).attr 'href').toArray()
      clean =
        rent: if data.rent then parseInt(accounting.unformat data.rent) else null
        beds: parseFloat if data.beds?.match /studio/ then 1 else data.beds.match(/[\.\d]* bed/)
        baths: parseFloat data.baths?.match(/[\.\d]* bath/)
        location:
          name: data.location
        pictures: data.pictures
      
  trulia: new Scraper
    listUrl: "http://www.trulia.com/for_rent/New_York,NY/0_bf/{page}_p"
    listItemSelector: 'a.primaryLink'
    zombieOpts: { runScripts: false, silent: true }
    $ToListing: ($) ->
      data =
        rent: accounting.unformat $('[itemprop="price"]').html()
        beds: parseFloat($('.listBulleted').html().match(/[\.\d]* bed/i))
        baths: parseFloat($('.listBulleted').html().match(/[\.\d]* bath/i))
        location:
          name: $('[itemprop="address"]').html()
        pictures: $('.photoPlayerThumbnails > img').map ->
                    $('.photoPlayerCurrentItem img').click().attr('src')
      

return unless module is require.main
dal.connect =>
  scraper = scrapers[process.argv[2]]
  if process.argv[4]
    scraper.scrapePagesRecur process.argv[3], process.argv[4], -> process.exit()
  else
    scraper.populateEmptyListings process.argv[3], -> process.exit()