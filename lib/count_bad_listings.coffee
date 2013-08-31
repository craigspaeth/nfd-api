# 
# Removes listings without pictures, or couldn't be geocoded, etc.
# 

dal = require '../dal'
_ = require 'underscore'

return unless module is require.main
dal.connect ->
  dal.listings.countBad (err, count) ->
    console.log "There are #{count} bad listings."
    process.exit()