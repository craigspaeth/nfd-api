# 
# Removes listings without pictures, or couldn't be geocoded, etc.
# 

dal = require '../dal'
_ = require 'underscore'

return unless module is require.main
dal.connect ->
  dal.listings.removeBad (err, numDeleted) ->
    console.log "Finished deleting #{numDeleted} bad listings."
    process.exit()