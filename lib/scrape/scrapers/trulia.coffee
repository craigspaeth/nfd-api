Scraper = require '../scraper'
accounting = require 'accounting'

module.exports = trulia: new Scraper
  listUrl: (page) -> "http://trulia.com/for_rent/New_York,NY/0_bf/#{page}_p"
  listItemSelector: 'a.primaryLink'
  $ToListing: ($) ->
    rent: accounting.unformat $('[itemprop="price"]').html()
    beds: Scraper.parseBeds $('.listBulleted').text()
    baths: parseFloat($('.listBulleted').html().match(/[\.\d]* bath/i))
    location:
      name: $('[itemprop="address"]').html()
    pictures: _.pluck($('.photoPlayer').data('photos')?.photos, 'standard_url') or
              [$('.photoPlayerCurrentItem img').attr('src')]