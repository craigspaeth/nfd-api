Scraper = require '../scraper'
accounting = require 'accounting'

module.exports = trulia: new Scraper
  startPage: 1
  listingsPerPage: 15
  listUrl: (page) -> "http://trulia.com/for_rent/New_York,NY/0_bf/#{page}_p"
  listItemSelector: 'a.primaryLink'
  $ToListing: ($) ->
    return $('html').html() unless $('html').html().length > 30
    rent: accounting.unformat $('[itemprop="price"]').html()
    beds: Scraper.parseBeds $('.listBulleted').text()
    baths: parseFloat($('.listBulleted').html().match(/[\.\d]* bath/i))
    location:
      name: $('[itemprop="address"]').html()
    pictures: _.pluck($('.photoPlayer').data('photos')?.photos, 'standard_url') or
              [$('.photoPlayerCurrentItem img').attr('src')]